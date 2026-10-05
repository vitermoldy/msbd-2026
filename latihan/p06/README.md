# Latihan P06 — Mengukur Harga Sebuah Index

EXPLAIN ANALYZE, B-Tree, partial, expression, covering, GIN, BRIN, statistik, dan harga tulis,
seluruhnya pada skema `lab6`. Index pada skema `public` Pagila tidak dibuat, diubah, atau dihapus.

## Prasyarat

- Docker Desktop dengan stack proyek aktif (`docker compose up -d`): service `postgres`
  (PostgreSQL 17), user `msbd`, basis data `pagila`
- Python 3.10+ untuk `rangkum_pengukuran.py` (opsional, hanya untuk merangkum pengukuran)
- Git Bash di Windows; perintah dijalankan dari akar repositori `msbd-2026`

## Variabel dan helper

```bash
export DSN="postgresql://msbd:<password>@localhost:5432/pagila"
psqlf() { docker compose exec -T postgres psql -U msbd -d pagila -e < "$1"; }
```

Password dapat diambil dari kontainer agar tidak diketik ulang:

```bash
PGPASS=$(docker compose exec -T postgres printenv POSTGRES_PASSWORD)
export DSN=$(python -c "import sys, urllib.parse as u; print('postgresql://msbd:' + u.quote(sys.argv[1], safe='') + '@localhost:5432/pagila')" "$PGPASS")
```

Keduanya hilang saat terminal ditutup, jadi ulangi di setiap terminal baru.

## Aturan pengukuran

Setiap berkas pengukuran sudah memuat tiga hal yang diwajibkan soal:

```sql
\timing on
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS) ...;   -- dijalankan tiga kali
```

Yang dilaporkan adalah waktu **tercepat** dan **median** dari tiga kali uji, bukan satu angka.

## Urutan menjalankan

Urutannya tidak boleh ditukar. `q07` harus berjalan sebelum ada index pada `customer_id`
atau `terjadi_pada`, dan `q14` harus berjalan sebelum `event_log` pernah di-VACUUM.

```bash
for f in q00_setup q01_ukuran_tabel q02_anatomi_storage q04_hot_update \
         q07_baseline q08_urutan_salah q09_urutan_benar q10_ukuran_index \
         q12_partial_index q13_expression_index q14_covering_index q15_include_vs_tiga_kolom \
         q17_gin_jsonb q18_gin_array q19_brin_vs_btree q20_brin_rentang \
         q22_index_status q23_selektivitas q24_random_page_cost q25_extended_statistics \
         q27_harga_tulis q28_ukuran_dua_keadaan q29_daftar_index q30_rekomendasi_index; do
  echo "== $f"
  psqlf latihan/p06/$f.sql > latihan/p06/explain/$f.txt 2>&1
  grep -c ERROR latihan/p06/explain/$f.txt
done
```

`q00_setup.sql` memuat dua juta baris dan merupakan berkas paling lama; jalankan lebih dulu.
Berkas itu diawali `DROP SCHEMA IF EXISTS lab6 CASCADE`, jadi menjalankannya ulang berarti
mengulang seluruh percobaan dari nol.

## Merangkum pengukuran

```bash
python latihan/p06/rangkum_pengukuran.py latihan/p06/explain > latihan/p06/hasil_pengukuran_terisi.md
```

Skrip ini membaca kembali `explain/*.txt`, mengelompokkan tiga pengulangan setiap query, lalu
mencetak tabel Markdown berisi node, waktu tercepat, median, dan Buffers.

## Isi folder

| Berkas | Soal | Isi |
|---|---|---|
| `q00_setup.sql` | Langkah 1 | Skema `lab6`, tabel `event_log`, dua juta baris |
| `q01_ukuran_tabel.sql` | Q1 | Ukuran tabel, byte per baris, perkiraan dari definisi kolom |
| `q02_anatomi_storage.sql` | Q2, Q3 | Tuple per halaman lewat ctid; `attstorage` dan TOAST |
| `q04_hot_update.sql` | Q4, Q5, Q6 | `fillfactor` 100 lawan 80, `n_tup_hot_upd`, ukuran sesudah UPDATE |
| `q07_baseline.sql` | Q7 | Rencana tanpa index |
| `q08_urutan_salah.sql` | Q8 | `(terjadi_pada, customer_id)` |
| `q09_urutan_benar.sql` | Q9 | `(customer_id, terjadi_pada DESC)` |
| `q10_ukuran_index.sql` | Q10 | Ukuran kedua index + tiga percobaan penyebab perbedaan ukuran |
| `q12_partial_index.sql` | Q12 | Partial index lawan index polos |
| `q13_expression_index.sql` | Q13 | `email =` lawan `lower(email) =` |
| `q14_covering_index.sql` | Q14 | Index-only scan, Heap Fetches sebelum dan sesudah VACUUM |
| `q15_include_vs_tiga_kolom.sql` | Q15 | `INCLUDE` lawan index tiga kolom |
| `q17_gin_jsonb.sql` | Q17 | GIN `jsonb_path_ops` |
| `q18_gin_array.sql` | Q18 | GIN pada `tags` |
| `q19_brin_vs_btree.sql` | Q19 | `correlation`, ukuran BRIN lawan B-Tree |
| `q20_brin_rentang.sql` | Q20 | Rentang tujuh hari: BRIN lawan B-Tree |
| `q22_index_status.sql` | Q22 | Rencana untuk `SUKSES`, `TERTUNDA`, `GAGAL` |
| `q23_selektivitas.sql` | Q23 | Sapuan fraksi 1%–60%, titik peralihan ke Seq Scan |
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

## Troubleshooting

| Gejala | Tindakan |
|---|---|
| INSERT dua juta baris sangat lama | Turunkan `generate_series(1,2000000)` menjadi 500000, catat penyesuaiannya di laporan, dan laporkan angkanya apa adanya |
| `gen_random_uuid` tidak dikenali | PostgreSQL 13+ sudah memuatnya; untuk versi lama `CREATE EXTENSION pgcrypto` atau `md5(random()::text)::uuid` |
| EXPLAIN memakai parallel scan | Pastikan `SET max_parallel_workers_per_gather = 0;` ada di sesi ukur (sudah ada di setiap berkas) |
| Index tidak dipakai | Jalankan `ANALYZE lab6.event_log` dan cocokkan ekspresi query dengan definisi index |
| Heap Fetches besar | Jalankan `VACUUM (ANALYZE) lab6.event_log` lalu bandingkan ulang (lihat Q14) |
| `random_page_cost` masih 1.1 | `RESET random_page_cost;` atau tutup sesi psql; nilai itu hanya berlaku per sesi |
| `pgstatindex` tidak dikenali | `CREATE EXTENSION IF NOT EXISTS pgstattuple;` (dipakai Q10) |
| `password authentication failed` | Set ulang `DSN` dengan dua baris pada bagian Variabel |

## Catatan Command Prompt

Di Command Prompt, fungsi psqlf tidak tersedia. Pola yang dipakai kelompok ini adalah menjalankan psql di dalam kontainer dengan docker compose exec, membaca berkas SQL sebagai masukan, lalu menyimpan keluarannya ke folder explain.
