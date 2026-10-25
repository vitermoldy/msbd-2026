# Latihan P06 — Mengukur Harga Sebuah Index

EXPLAIN ANALYZE, B-Tree, partial, expression, covering, GIN, BRIN, statistik, dan harga tulis,
seluruhnya pada skema `lab6`. Index pada skema `public` Pagila tidak dibuat, diubah, atau
dihapus.

## Prasyarat

- Docker Desktop dengan stack proyek aktif (`docker compose up -d`): service `postgres`
  (PostgreSQL 17), user `msbd`
- Python 3.10+ untuk `rangkum_pengukuran.py` (hanya membaca berkas teks, tidak menyambung ke
  basis data)
- Perintah dijalankan dari akar repositori `msbd-2026`

Tidak ada variabel `DSN` yang perlu disetel: seluruh query dijalankan lewat
`docker compose exec`, dan satu-satunya skrip Python di folder ini hanya membaca berkas di
`explain/`.

## Basis data yang dipakai

Skema `lab6` berdiri sendiri dan tidak merujuk tabel Pagila mana pun, jadi ia boleh dibuat di
basis data `pagila` maupun `latihan` pada kontainer masing-masing anggota. Yang penting,
**tulis basis data yang kamu pakai pada bagian Kondisi Uji di `laporan.md`**, karena ukuran dan
waktu bergantung pada mesin dan keadaan kontainer masing-masing.

## Pola menjalankan satu berkas

Command Prompt:

```bat
docker compose exec -T postgres psql -U msbd -d pagila -e < latihan\p06\q07_baseline.sql > latihan\p06\explain\q07_baseline.txt 2>&1
findstr /C:"ERROR" latihan\p06\explain\q07_baseline.txt
powershell -Command "Get-Content latihan\p06\explain\q07_baseline.txt -Tail 30"
```

PowerShell tidak mendukung `<`, jadi bentuknya menjadi:

```powershell
Get-Content latihan\p06\q07_baseline.sql | docker compose exec -T postgres psql -U msbd -d pagila -e 2>&1 | Out-File -Encoding utf8 latihan\p06\explain\q07_baseline.txt
```

Git Bash:

```bash
psqlf() { docker compose exec -T postgres psql -U msbd -d pagila -e < "$1"; }
psqlf latihan/p06/q07_baseline.sql > latihan/p06/explain/q07_baseline.txt 2>&1
```

Keluaran setiap berkas **wajib** disimpan ke `explain/` karena itulah bukti yang diminta soal,
dan karena `rangkum_pengukuran.py` membaca ulang berkas-berkas itu.

## Aturan pengukuran

Soal mewajibkan tiga hal pada setiap sesi ukur:

```sql
\timing on
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS) ...;   -- query yang sama dijalankan tiga kali
```

Yang dilaporkan adalah waktu **tercepat** dan **median** dari tiga kali uji, bukan satu angka,
dan keluaran `BUFFERS` selalu ikut disalin.

## Urutan menjalankan

Urutannya tidak boleh ditukar:

1. `q00_setup` memuat dua juta baris dan merupakan berkas paling lama; jalankan lebih dulu.
   Berkas itu diawali `DROP SCHEMA IF EXISTS lab6 CASCADE`, jadi menjalankannya ulang berarti
   mengulang seluruh percobaan dari nol.
2. `q07_baseline` harus berjalan **sebelum** ada index pada `customer_id` atau `terjadi_pada`.
3. Berkas Q14 harus berjalan **sebelum** `event_log` pernah di-VACUUM.
4. `q29_daftar_index` dijalankan **paling akhir**, supaya `idx_scan` memuat seluruh pemakaian
   dari Q7 sampai Q28.

Urutan lengkapnya:

```text
q00_setup → q01_ukuran_tabel → q02_anatomi_storage → q04_hot_update
→ q07_baseline → q08_urutan_salah → q09_urutan_benar → q10_ukuran_index
→ q12_partial_index_gagal → q13_expression_index_email → q14_covering_index_only_scan
→ q15_covering_vs_tigakolom
→ q17_gin_payload → q18_gin_tags → q19_brin_correlation → q20_brin_vs_btree
→ q22_index_status → q23_fraksi_status → q24_random_page_cost → q25_extended_statistics
→ q27_harga_tulis → q28_ukuran_dua_keadaan → q29_daftar_index → q30_rekomendasi_index
```

Satu ekstensi dibutuhkan Q10, cukup dijalankan sekali per basis data:

```bat
docker compose exec -T postgres psql -U msbd -d pagila -c "CREATE EXTENSION IF NOT EXISTS pgstattuple;"
```

## Merangkum pengukuran

```bat
python latihan\p06\rangkum_pengukuran.py latihan\p06\explain > latihan\p06\hasil_pengukuran_terisi.md
```

Skrip ini membaca ulang `explain/*.txt`, mengelompokkan pengulangan setiap query berdasarkan
label `===== Qxx · run N`, lalu mencetak tabel Markdown berisi node, waktu tercepat, median,
dan Buffers. Periksa kolom `n`: untuk query yang diukur tiga kali nilainya harus 3.

## Isi folder

| Berkas | Soal | Isi |
|---|---|---|
| `q00_setup.sql` | Langkah 1 | Skema `lab6`, tabel `event_log`, dua juta baris |
| `q01_ukuran_tabel.sql` | Q1 | Ukuran tabel, byte per baris, perkiraan dari definisi kolom |
| `q02_anatomi_storage.sql` | Q2, Q3 | Tuple per halaman lewat `ctid`; `attstorage` dan TOAST |
| `q04_hot_update.sql` | Q4, Q5, Q6 | `fillfactor` 100 lawan 80, `n_tup_hot_upd`, ukuran sesudah UPDATE |
| `q07_baseline.sql` | Q7 | Rencana tanpa index |
| `q08_urutan_salah.sql` | Q8 | `(terjadi_pada, customer_id)` |
| `q09_urutan_benar.sql` | Q9 | `(customer_id, terjadi_pada DESC)` |
| `q10_ukuran_index.sql` | Q10 | Ukuran kedua index dan penyebab perbedaannya |
| `q12_partial_index_gagal.sql` | Q12 | Partial index `status='GAGAL'` lawan index polos |
| `q13_expression_index_email.sql` | Q13 | `email =` lawan `lower(email) =` |
| `q14_covering_index_only_scan.sql` | Q14 | Index-only scan, Heap Fetches sebelum dan sesudah VACUUM |
| `q15_covering_vs_tigakolom.sql` | Q15 | `INCLUDE` lawan index tiga kolom |
| `q17_gin_payload.sql` | Q17 | GIN `jsonb_path_ops` pada `payload` |
| `q18_gin_tags.sql` | Q18 | GIN pada `tags` |
| `q19_brin_correlation.sql` | Q19 | `correlation`, ukuran BRIN lawan B-Tree |
| `q20_brin_vs_btree.sql` | Q20 | Rentang tujuh hari: BRIN lawan B-Tree |
| `q22_index_status.sql` | Q22 | Rencana untuk `SUKSES`, `TERTUNDA`, `GAGAL` |
| `q23_fraksi_status.sql` | Q23 | Fraksi tiap status dan titik peralihan ke Seq Scan |
| `q24_random_page_cost.sql` | Q24 | Pergeseran titik peralihan, lalu `RESET` |
| `q25_extended_statistics.sql` | Q25 | `dependencies` dan `ndistinct` pada wilayah–kota |
| `q27_harga_tulis.sql` | Q27 | INSERT 200000 baris: tanpa index lawan lima index |
| `q28_ukuran_dua_keadaan.sql` | Q28 | Ukuran total kedua keadaan |
| `q29_daftar_index.sql` | Q29 | Seluruh index `lab6`, `idx_scan`, ukuran |
| `q30_rekomendasi_index.sql` | Q30 | Bahan rekomendasi dan kandidat gabung |
| `rangkum_pengukuran.py` | — | Merangkum `explain/*.txt` menjadi tabel waktu dan Buffers |
| `explain/` | Q7–Q30 | Keluaran EXPLAIN apa adanya |
| `hasil_pengukuran.md` | — | Tabel waktu, Buffers, dan ukuran |
| `laporan.md` | — | Laporan kelompok, jawaban Q1–Q31, rekomendasi akhir |

Nama berkas bukti di `explain/` mengikuti berkas SQL-nya. Satu berkas SQL boleh menghasilkan
lebih dari satu berkas bukti bila percobaannya dipisah, misalnya `q13_tanpa_ekspresi.txt` dan
`q13_dengan_ekspresi.txt`, atau `q14_sebelum_vacuum.txt` dan `q14_sesudah_vacuum.txt`.

## Troubleshooting

| Gejala | Tindakan |
|---|---|
| INSERT dua juta baris sangat lama | Turunkan `generate_series(1,2000000)` menjadi 500000, catat penyesuaiannya di laporan, laporkan angkanya apa adanya |
| `gen_random_uuid` tidak dikenali | PostgreSQL 13+ sudah memuatnya; untuk versi lama `CREATE EXTENSION pgcrypto` |
| EXPLAIN memakai parallel scan | Pastikan `SET max_parallel_workers_per_gather = 0;` ada di berkasnya |
| Index tidak dipakai | Jalankan `ANALYZE lab6.event_log` dan cocokkan ekspresi query dengan definisi index |
| Heap Fetches besar | Jalankan `VACUUM (ANALYZE) lab6.event_log` lalu bandingkan ulang (lihat Q14) |
| `random_page_cost` masih 1.1 | `RESET random_page_cost;` atau tutup sesi psql; nilai itu hanya berlaku per sesi |
| `pgstatindex` tidak dikenali | `CREATE EXTENSION IF NOT EXISTS pgstattuple;` (dipakai Q10) |
| cmd: "cannot find the **file**" | Berkas SQL masukannya belum ada |
| cmd: "cannot find the **path**" | Folder `latihan\p06\explain` belum ada |
| PowerShell: operator `<` ditolak | Pakai bentuk `Get-Content ... \| docker compose exec ...`, atau ketik `cmd` lebih dulu |
