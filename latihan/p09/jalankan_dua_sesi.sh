#!/bin/bash
# =====================================================================
# P09 - Menjalankan eksperimen Q1-Q10 dengan DUA sesi psql sekaligus.
#
# Berkas ini dijalankan DI DALAM container postgres, bukan di Windows:
#
#   docker compose cp latihan\p09\jalankan_dua_sesi.sh postgres:/tmp/p09.sh
#   docker compose exec -T postgres bash -c "tr -d '\r' < /tmp/p09.sh > /tmp/p09x.sh; bash /tmp/p09x.sh" > latihan\p09\bukti\hasil-sesi.txt 2>&1
#
# Dua proses psql dijalankan bersamaan, masing-masing diberi perintah
# lewat FIFO terpisah, sehingga urutan antar-sesi benar-benar nyata:
# ketika Sesi B membaca, transaksi Sesi A memang masih terbuka.
# Keluaran kedua sesi lalu digabung berdasarkan nomor langkah.
# =====================================================================

DB="${DB:-pagila}"
USR="${USR:-msbd}"
PSQL="${PSQL_CMD:-psql -U $USR -d $DB -X -e}"
JEDA="${JEDA:-0.7}"

for alat in mkfifo sleep awk; do
    command -v "$alat" >/dev/null 2>&1 || { echo "GAGAL: perintah '$alat' tidak ada di dalam container."; exit 1; }
done

cek=$(printf 'SELECT count(*) AS jumlah FROM lab9.rekening;\n' | eval "$PSQL" 2>&1)
case "$cek" in
    *" 2"*) ;;
    *)
        echo "GAGAL: tidak bisa membaca lab9.rekening sebagai user '$USR' di basis data '$DB'."
        echo "Keluaran psql:"
        echo "$cek"
        echo
        echo "Jalankan dulu q00_setup.sql, lalu coba lagi."
        exit 1
        ;;
esac

FA=/tmp/p09_fifo_a; FB=/tmp/p09_fifo_b
OA=/tmp/p09_out_a.txt; OB=/tmp/p09_out_b.txt
rm -f "$FA" "$FB" "$OA" "$OB"
mkfifo "$FA" "$FB"

eval "$PSQL" < "$FA" > "$OA" 2>&1 &
PID_A=$!
eval "$PSQL" < "$FB" > "$OB" 2>&1 &
PID_B=$!
exec 7>"$FA" 8>"$FB"

LANGKAH=0
JUDUL=""

# bab <judul>  -- menandai awal satu soal
bab() { JUDUL="$1"; }

# kirim <A|B> <sql>  -- kirim satu perintah ke satu sesi,
#                       tetapi tulis penanda langkah ke KEDUA sesi
kirim() {
    LANGKAH=$((LANGKAH + 1))
    local tanda
    tanda=$(printf '%03d' "$LANGKAH")
    printf '\\echo @@@ %s|%s|%s\n' "$tanda" "$1" "$JUDUL" >&7
    printf '\\echo @@@ %s|%s|%s\n' "$tanda" "$1" "$JUDUL" >&8
    if [ "$1" = "A" ]; then
        printf '%s\n' "$2" >&7
    else
        printf '%s\n' "$2" >&8
    fi
    sleep "$JEDA"
}

kirim A '\set VERBOSITY verbose'
kirim B '\set VERBOSITY verbose'
kirim A "SELECT 'Sesi A' AS sesi, pg_backend_pid() AS pid;"
kirim B "SELECT 'Sesi B' AS sesi, pg_backend_pid() AS pid;"

# --- Kondisi awal ---------------------------------------------------
bab 'Kondisi uji'
kirim A "SELECT version();"
kirim A "SHOW transaction_isolation;"
kirim A "SHOW deadlock_timeout;"
kirim A "SHOW lock_timeout;"
kirim A "SHOW statement_timeout;"
kirim A "SHOW idle_in_transaction_session_timeout;"
kirim A "UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);"

# --- Q1 -------------------------------------------------------------
bab 'Q1 - Kondisi awal dan total saldo'
kirim A "SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;"
kirim A "SELECT count(*) AS jumlah_rekening, sum(saldo) AS total_saldo FROM lab9.rekening;"

# --- Q2 -------------------------------------------------------------
bab 'Q2 - Perubahan sebelum COMMIT dilihat dari sesi lain'
kirim A "BEGIN;"
kirim A "UPDATE lab9.rekening SET saldo = saldo - 250000 WHERE rekening_id = 1;"
kirim A "SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;"
kirim B "SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;"
kirim B "SELECT pg_blocking_pids(pg_backend_pid()) AS menunggu_pid;"
kirim A "ROLLBACK;"
kirim B "SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;"

# --- Q3 -------------------------------------------------------------
bab 'Q3 - COMMIT lawan ROLLBACK'
kirim A "BEGIN;"
kirim A "UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1;"
kirim A "UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 2;"
kirim A "COMMIT;"
kirim A "SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;"
kirim A "BEGIN;"
kirim A "UPDATE lab9.rekening SET saldo = saldo - 400000 WHERE rekening_id = 1;"
kirim A "SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;"
kirim A "ROLLBACK;"
kirim A "SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;"

# --- Q4 -------------------------------------------------------------
bab 'Q4 - SAVEPOINT dan ROLLBACK TO SAVEPOINT'
kirim A "BEGIN;"
kirim A "UPDATE lab9.rekening SET saldo = saldo - 50000 WHERE rekening_id = 1;"
kirim A "SAVEPOINT sebelum_transfer_kedua;"
kirim A "UPDATE lab9.rekening SET saldo = saldo - 70000 WHERE rekening_id = 1;"
kirim A "SELECT saldo AS sesudah_tahap_dua FROM lab9.rekening WHERE rekening_id = 1;"
kirim A "ROLLBACK TO SAVEPOINT sebelum_transfer_kedua;"
kirim A "SELECT saldo AS sesudah_rollback_savepoint FROM lab9.rekening WHERE rekening_id = 1;"
kirim A "COMMIT;"
kirim A "SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;"

# --- Q5 -------------------------------------------------------------
bab 'Q5 - Atomicity dan CHECK (saldo >= 0)'
kirim A "BEGIN;"
kirim A "UPDATE lab9.rekening SET saldo = saldo + 1 WHERE rekening_id = 2;"
kirim A "UPDATE lab9.rekening SET saldo = saldo - 99999999 WHERE rekening_id = 1;"
kirim A "SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;"
kirim A "ROLLBACK;"
kirim A "SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;"
kirim A "SELECT sum(saldo) AS total_saldo FROM lab9.rekening;"
kirim A "UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);"

# --- Q6 -------------------------------------------------------------
bab 'Q6 - Non-repeatable read pada READ COMMITTED'
kirim A "BEGIN;"
kirim A "SHOW transaction_isolation;"
kirim A "SELECT saldo AS bacaan_pertama FROM lab9.rekening WHERE rekening_id = 1;"
kirim B "UPDATE lab9.rekening SET saldo = saldo - 300000 WHERE rekening_id = 1;"
kirim A "SELECT saldo AS bacaan_kedua FROM lab9.rekening WHERE rekening_id = 1;"
kirim A "COMMIT;"
kirim A "UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);"

# --- Q7 -------------------------------------------------------------
bab 'Q7 - Skenario sama pada REPEATABLE READ'
kirim A "BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;"
kirim A "SHOW transaction_isolation;"
kirim A "SELECT saldo AS bacaan_pertama FROM lab9.rekening WHERE rekening_id = 1;"
kirim B "UPDATE lab9.rekening SET saldo = saldo - 300000 WHERE rekening_id = 1;"
kirim A "SELECT saldo AS bacaan_kedua FROM lab9.rekening WHERE rekening_id = 1;"
kirim A "UPDATE lab9.rekening SET saldo = saldo - 1 WHERE rekening_id = 1;"
kirim A "ROLLBACK;"
kirim A "SELECT saldo AS setelah_semua FROM lab9.rekening WHERE rekening_id = 1;"
kirim A "UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);"

# --- Q8 -------------------------------------------------------------
bab 'Q8 - Phantom read'
kirim A "DROP TABLE IF EXISTS lab9.rekening_uji;"
kirim A "CREATE TABLE lab9.rekening_uji (rekening_id INT PRIMARY KEY, pemilik TEXT NOT NULL, saldo NUMERIC(12,2) NOT NULL);"
kirim A "INSERT INTO lab9.rekening_uji VALUES (1,'Ani',1000000),(2,'Budi',1000000),(3,'Citra',400000),(4,'Dedi',250000);"
kirim A "BEGIN;"
kirim A "SELECT count(*) AS hitung_pertama_rc FROM lab9.rekening_uji WHERE saldo > 500000;"
kirim B "INSERT INTO lab9.rekening_uji VALUES (5,'Eka',900000);"
kirim A "SELECT count(*) AS hitung_kedua_rc FROM lab9.rekening_uji WHERE saldo > 500000;"
kirim A "COMMIT;"
kirim A "BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;"
kirim A "SELECT count(*) AS hitung_pertama_rr FROM lab9.rekening_uji WHERE saldo > 500000;"
kirim B "INSERT INTO lab9.rekening_uji VALUES (6,'Fajar',800000);"
kirim A "SELECT count(*) AS hitung_kedua_rr FROM lab9.rekening_uji WHERE saldo > 500000;"
kirim A "COMMIT;"
kirim A "SELECT count(*) AS hitung_setelah_commit FROM lab9.rekening_uji WHERE saldo > 500000;"

# --- Q9 -------------------------------------------------------------
bab 'Q9 - Dirty read dan READ UNCOMMITTED'
kirim A "BEGIN;"
kirim A "UPDATE lab9.rekening SET saldo = 1 WHERE rekening_id = 1;"
kirim A "SELECT saldo AS yang_dilihat_a FROM lab9.rekening WHERE rekening_id = 1;"
kirim B "BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;"
kirim B "SHOW transaction_isolation;"
kirim B "SELECT saldo AS yang_dilihat_b FROM lab9.rekening WHERE rekening_id = 1;"
kirim B "COMMIT;"
kirim A "ROLLBACK;"
kirim A "SELECT saldo AS sesudah_rollback FROM lab9.rekening WHERE rekening_id = 1;"

# --- Q10 ------------------------------------------------------------
bab 'Q10 - Lost update'
kirim A "BEGIN;"
kirim A "SELECT saldo AS dibaca_a FROM lab9.rekening WHERE rekening_id = 1;"
kirim B "BEGIN;"
kirim B "SELECT saldo AS dibaca_b FROM lab9.rekening WHERE rekening_id = 1;"
kirim A "UPDATE lab9.rekening SET saldo = 900000 WHERE rekening_id = 1;"
kirim A "COMMIT;"
kirim B "UPDATE lab9.rekening SET saldo = 950000 WHERE rekening_id = 1;"
kirim B "COMMIT;"
kirim A "SELECT saldo AS saldo_akhir FROM lab9.rekening WHERE rekening_id = 1;"

# --- Pemulihan ------------------------------------------------------
bab 'Pemulihan kondisi awal'
kirim A "UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);"
kirim A "DROP TABLE IF EXISTS lab9.rekening_uji;"
kirim A "SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;"
kirim A "SELECT sum(saldo) AS total_saldo FROM lab9.rekening;"

printf '\\q\n' >&7
printf '\\q\n' >&8
exec 7>&- 8>&-
wait "$PID_A" 2>/dev/null
wait "$PID_B" 2>/dev/null
rm -f "$FA" "$FB"

# --- Gabungkan kedua keluaran berdasarkan nomor langkah -------------
awk -v total="$LANGKAH" '
function cetak_blok(n) {
    if (!(n in isi)) return
    teks = isi[n]
    gsub(/^[ \t\n]+|[ \t\n]+$/, "", teks)
    if (teks == "") return
    if (judul[n] != bab_terakhir) {
        bab_terakhir = judul[n]
        printf "\n"
        printf "================================================================================\n"
        printf " %s\n", bab_terakhir
        printf "================================================================================\n"
    }
    printf "\n--- langkah %s | Sesi %s ---\n%s\n", n, sesi[n], teks
}
FNR == 1 { berkas++ }
/^@@@ / {
    split(substr($0, 5), p, "|")
    kini = p[1]
    sesi[kini] = p[2]
    judul[kini] = p[3]
    next
}
{
    if (kini != "" && $0 !~ /^[ \t]*$/) isi[kini] = isi[kini] $0 "\n"
}
END {
    printf "================================================================================\n"
    printf " P09 - HASIL SESI MENTAH (Q1-Q10)\n"
    printf "================================================================================\n"
    printf " Dihasilkan otomatis oleh latihan/p09/jalankan_dua_sesi.sh\n"
    printf " Dua proses psql berjalan BERSAMAAN di dalam container, masing-masing diberi\n"
    printf " perintah lewat FIFO terpisah. Nomor langkah adalah urutan waktu yang\n"
    printf " sebenarnya, jadi langkah 041 benar-benar dijalankan setelah langkah 040\n"
    printf " selesai dan sebelum langkah 042 dimulai.\n"
    printf " Penanda \"Sesi A\" / \"Sesi B\" menunjukkan sesi yang menjalankan perintah itu.\n"
    printf " Keluaran di bawah adalah keluaran psql apa adanya, termasuk pesan ERROR.\n"
    printf "================================================================================\n"
    for (i = 1; i <= total; i++) {
        n = sprintf("%03d", i)
        cetak_blok(n)
    }
    printf "\n================================================================================\n"
    printf " Q11 - tabel ringkasan anomali: lihat laporan.md dan bukti/isolation-level.md\n"
    printf " Q12-Q32 - diisi anggota Langkah 3-6\n"
    printf "================================================================================\n"
}
' "$OA" "$OB"
GABUNG=$?
if [ "$GABUNG" -ne 0 ]; then
    echo "=== awk gagal menggabungkan; berikut keluaran kedua sesi apa adanya ==="
    echo "----- KELUARAN SESI A -----"; cat "$OA"
    echo "----- KELUARAN SESI B -----"; cat "$OB"
fi
