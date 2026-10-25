# Latihan P09 — Menguji Transaksi dan Kendali Konkurensi

ACID, isolation level, MVCC, row lock, deadlock, SERIALIZABLE, dan retry, seluruhnya pada skema
`lab9`. Tabel Pagila pada skema `public` dan skema latihan pertemuan lain (`lab5`, `lab6`) tidak
dibuat, diubah, maupun dihapus.

## Prasyarat

- Docker Desktop dengan stack proyek aktif (`docker compose up -d`): service `postgres`
  (PostgreSQL 17), user `msbd`
- Perintah dijalankan dari akar repositori `msbd-2026`
- Tidak ada skrip Python dan tidak ada variabel `DSN` yang perlu disetel; seluruh percobaan
  dijalankan langsung di dalam `psql`

## Yang membuat latihan ini berbeda

Pertemuan sebelumnya bisa dijalankan dengan satu perintah per berkas. Latihan ini **tidak
bisa**, karena yang diuji adalah apa yang terjadi ketika dua transaksi berjalan bersamaan.
Banyak perintah di sini sengaja dibiarkan menggantung — transaksinya belum di-`COMMIT` — supaya
sesi lain bisa dibuat menabraknya. Karena itu:

- `psql` dijalankan **interaktif** (`-it`, tanpa `-T` dan tanpa `<`), bukan dialirkan dari berkas
- `q01_q32_transaksi.sql` adalah **berkas acuan untuk dibaca dan disalin per baris**, bukan
  berkas untuk dijalankan sekaligus. Menjalankannya satu kali lewat `psql -f` akan menjalankan
  seluruh perintah di satu sesi dan tidak membuktikan apa pun
- buktinya bukan keluaran `EXPLAIN`, melainkan **urutan kejadian antar sesi**: apa yang dibaca
  Sesi A pada detik ketika Sesi B belum `COMMIT`

## Cara cepat: satu perintah untuk Q1–Q10

Menyalin puluhan perintah antar dua jendela itu lambat dan mudah keliru urutannya. Berkas
`jalankan_dua_sesi.sh` melakukannya otomatis: ia menjalankan **dua proses `psql` sekaligus di
dalam container**, masing-masing diberi perintah lewat FIFO terpisah, sehingga urutan antar-sesi
benar-benar nyata — ketika Sesi B membaca, transaksi Sesi A memang masih terbuka. Keluaran kedua
sesi lalu digabung menurut nomor langkah dan ditulis ke `bukti/hasil-sesi.txt`.

Jalankan `q00_setup.sql` lebih dulu, lalu dua perintah ini dari akar repositori:

```bat
docker compose cp latihan\p09\jalankan_dua_sesi.sh postgres:/tmp/p09.sh
docker compose exec -T postgres bash -c "tr -d '\r' < /tmp/p09.sh > /tmp/p09x.sh; bash /tmp/p09x.sh" > latihan\p09\bukti\hasil-sesi.txt 2>&1
```

`tr -d '\r'` membuang CRLF, supaya skripnya tetap jalan kalau Git mengubah akhir baris saat
checkout di Windows. Prosesnya sekitar satu setengah menit karena ada jeda sengaja antar
perintah. Periksa hasilnya:

```bat
findstr /C:"GAGAL" /C:"23514" /C:"25P02" /C:"40001" latihan\p09\bukti\hasil-sesi.txt
```

Ketiga SQLSTATE itu **memang harus muncul** — itu bukti Q5 dan Q7. Yang tidak boleh muncul
adalah `GAGAL`. Skrip ini memeriksa dulu bahwa `lab9.rekening` sudah berisi dua baris sebelum
mulai, dan mengembalikan data ke 1.000.000 per rekening setelah selesai.

Variabel yang bisa ditimpa bila perlu: `DB` (bawaan `pagila`), `USR` (bawaan `msbd`), dan `JEDA`
(bawaan 0.7 detik per perintah).

Cara manual di bawah tetap dipakai untuk Langkah 3–6, karena Q19–Q20 justru perlu dilihat
menunggu dan deadlock-nya secara langsung.

## Menyiapkan dua sesi

Buka **dua jendela Command Prompt**, keduanya di akar repositori, lalu jalankan perintah yang
sama di masing-masing jendela:

```bat
docker compose exec -it postgres psql -U msbd -d pagila
```

Beri tanda jendela mana yang **Sesi A** dan mana **Sesi B** — paling mudah dengan menjalankan
ini sekali di tiap jendela:

```sql
\set PROMPT1 'A=> '
```

```sql
\set PROMPT1 'B=> '
```

Lalu di **kedua** sesi, nyalakan pencetakan SQLSTATE. Tanpa ini, `psql` hanya menampilkan pesan
galat tanpa kodenya, sedangkan soal meminta SQLSTATE dicatat:

```sql
\set VERBOSITY verbose
```

Untuk memastikan kedua jendela benar-benar sesi yang berbeda, bandingkan keluaran ini di
masing-masing; angkanya harus berbeda:

```sql
SELECT pg_backend_pid();
```

## Urutan menjalankan

```text
q00_setup.sql  →  q01_q32_transaksi.sql (Q1 … Q32, berurutan)
```

1. **Setup**, cukup sekali, dari jendela mana pun:

   ```bat
   docker compose exec -T postgres psql -U msbd -d pagila -e < latihan\p09\q00_setup.sql
   ```

   Berkas ini memakai `CREATE TABLE IF NOT EXISTS` dan `ON CONFLICT ... DO UPDATE`, jadi aman
   dijalankan berulang: data selalu kembali ke 1.000.000 per rekening. Catat keluaran
   `version()` dan kelima `SHOW` di bagian **Kondisi uji** `laporan.md`.

2. **Percobaan**, dari `q01_q32_transaksi.sql`. Setiap perintah di berkas itu diawali penanda
   sesi; salin satu perintah ke jendela yang sesuai penandanya, tekan Enter, catat hasilnya,
   baru lanjut ke perintah berikutnya:

   ```text
   -- [A]    jalankan di Sesi A
   -- [B]    jalankan di Sesi B
   -- [A+B]  tidak bergantung konkurensi, boleh di sesi mana pun
   ```

   **Urutannya tidak boleh ditukar**, karena justru urutan itulah yang diuji. Melewati satu
   `COMMIT` saja membuat percobaan berikutnya memberi hasil yang berbeda.

3. **Catat hasilnya** ke `bukti/hasil-sesi.txt`. Berkas itu sudah berisi blok per soal dengan
   baris `--- keluaran ---`; tempel keluaran psql apa adanya di bawah baris tersebut, termasuk
   baris `BEGIN`, `UPDATE 1`, `COMMIT`, dan seluruh pesan `ERROR`.

4. **Pulihkan data** setelah setiap eksperimen. Berkas acuan sudah memuat perintah pemulihannya
   di antara soal-soal:

   ```sql
   UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1, 2);
   ```

## Aturan yang diminta soal

- **Jangan menetapkan timeout global pada server.** Jika sebuah percobaan perlu timeout (Q23,
  Q25), pakai `SET LOCAL` di dalam transaksi, atau `RESET` nilainya segera sesudah percobaan.
- **Transaksi yang gagal wajib di-`ROLLBACK`** sebelum eksperimen berikutnya. Setelah sebuah
  galat, transaksi masuk kondisi *aborted* dan setiap perintah berikutnya ditolak dengan
  SQLSTATE `25P02` — termasuk `SELECT`.
- **Semua perubahan data dikembalikan ke kondisi awal**, atau selisihnya dicatat dengan jelas di
  laporan.
- Hanya skema `lab9`. Jangan menyentuh tabel Pagila maupun `lab5`/`lab6`.

## Isi folder

| Berkas | Soal | Isi |
|---|---|---|
| `q00_setup.sql` | Langkah 1 | Skema `lab9`, tabel `rekening`, data awal, dan kelima `SHOW` untuk Kondisi uji |
| `jalankan_dua_sesi.sh` | Q1–Q10 | Menjalankan kedua sesi otomatis dan menulis `bukti/hasil-sesi.txt` |
| `q01_q32_transaksi.sql` | Q1–Q32 | Seluruh perintah percobaan, berpenanda `[A]` / `[B]`, dengan nilai yang diharapkan sebagai komentar |
| `bukti/isolation-level.md` | Q6–Q11 | Tabel urutan kedua sesi, pesan galat, dan analisis anomali |
| `bukti/deadlock.md` | Q18–Q23 | Row lock, antrean lock, dan deadlock `40P01` |
| `bukti/serializable.md` | Q24–Q29 | SKIP LOCKED, NOWAIT, write skew, dan `SERIALIZABLE` |
| `bukti/hasil-sesi.txt` | Q1–Q32 | Keluaran psql mentah dari kedua sesi, per soal |
| `laporan.md` | — | Laporan kelompok: kondisi uji, jawaban Q1–Q32, ringkasan anomali, kesimpulan |

Berkas SQL dan `bukti/isolation-level.md` sudah terisi untuk Q1–Q11 (Langkah 1 dan 2).
`bukti/deadlock.md` dan `bukti/serializable.md` berisi kerangka pencatatan untuk Langkah 4 dan 5.

## Troubleshooting

| Gejala | Tindakan |
|---|---|
| `service "postgres" is not running` | Jalankan Docker Desktop, lalu `docker compose up -d` |
| Perintah kedua di satu sesi diam saja tanpa prompt | Sesi itu sedang **menunggu lock**. Itu memang hasil yang dicari pada Q19–Q20; catat, lalu `COMMIT`/`ROLLBACK` di sesi yang memegang lock |
| `ERROR: 25P02 current transaction is aborted` | Transaksi sudah gagal; jalankan `ROLLBACK`, lalu ulangi percobaan dari `BEGIN` |
| Pesan galat tampil tanpa SQLSTATE | `\set VERBOSITY verbose` belum dijalankan di sesi itu |
| `SHOW transaction_isolation` tetap `read committed` padahal sudah diminta level lain | Level hanya berlaku per transaksi: setel di `BEGIN TRANSACTION ISOLATION LEVEL ...`, atau `SET TRANSACTION ...` **setelah** `BEGIN` |
| Angka saldo tidak cocok dengan komentar di berkas acuan | Perintah pemulihan terlewat; jalankan `UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);` lalu ulangi soal itu |
| Sesi menggantung dan lupa transaksi mana yang terbuka | `SELECT pid, state, query FROM pg_stat_activity WHERE datname = 'pagila';` lalu `ROLLBACK` di sesi yang `idle in transaction` |
| Sesi menunggu dan ingin tahu siapa yang menghalangi | `SELECT pg_blocking_pids(pg_backend_pid());` dari sesi yang menunggu |
| cmd: perintah `psql` keluar sendiri setelah satu perintah | `-T` atau `<` masih terpakai; untuk latihan ini `psql` harus interaktif (`-it`) |
