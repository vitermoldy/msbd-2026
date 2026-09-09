# Latihan Pertemuan 3 — SQL Lanjutan I

Mata kuliah : TIF2104 — Manajemen Sistem Basis Data
Pertemuan   : 3 — SQL Lanjutan I: Query Bertingkat dan Laporan Analitik
Basis data  : Pagila pada PostgreSQL 17

## Tujuan

Menulis dua puluh query bertingkat dan satu laporan analitik terpadu di atas basis
data Pagila. Yang dinilai bukan hanya angka yang benar, tetapi juga alasan pemilihan
bentuk query — karena itu setiap berkas jawaban diawali tiga komentar: apa yang
diminta soal, bentuk query yang dipilih beserta alasannya, dan satu alternatif yang
dipertimbangkan tetapi tidak dipakai.

Materi yang dilatih:

- Subquery skalar, derived table, subquery berkorelasi, `EXISTS`, dan `NOT EXISTS`
- CTE bertingkat dan recursive CTE yang aman terhadap siklus
- Window function untuk peringkat, perbandingan antarbaris, running total, dan moving average
- `ROLLUP`, `GROUPING()`, agregat `FILTER`, dan operasi himpunan
- Mengakses, mencari, mengindeks, dan membentangkan data JSONB

## Anggota dan Tanggung Jawab

| No | NIM       | Nama                          | GitHub         | Tanggung jawab Pertemuan 3                                  |
|----|-----------|-------------------------------|----------------|-------------------------------------------------------------|
| 1  | 251402079 | Viter Moldy Kesuma            | vitermoldy     | Langkah 2 dan 3 — `q00_setup.sql`, Q1–Q5, Refleksi A, `README.md` |
| 2  | 251402038 | Gideon Finsus Siburian        | DeezG-web      | Langkah 4 — Q6–Q9, Refleksi B, uji siklus dan pemulihan data |
| 3  | 251402056 | Rizky Cristian Fero Sihombing | RizkySihombing | Langkah 5 — Q10–Q15, Refleksi C, temuan Q14                  |
| 4  | 251402067 | Siti Naifah Batubara          | naifah13       | Langkah 6 — Q16–Q18, Refleksi D, kurator folder `bukti/`     |
| 5  | 251402050 | Nadine Tantiara Hutagaol      | nadinehutagaol | Langkah 7 dan 8 — Q19, Q20, R1, Refleksi E, `laporan.md`     |

Langkah 1 (verifikasi lingkungan) dikerjakan setiap anggota di komputer masing-masing.

Pemeriksaan silang membentuk cincin tertutup: Viter memeriksa Finsus, Finsus memeriksa
Rizky, Rizky memeriksa Naifah, Naifah memeriksa Nadine, dan Nadine memeriksa Viter.

## Prasyarat

| Perangkat lunak | Catatan |
|-----------------|---------|
| Docker Desktop  | Layanan `postgres` pada `docker-compose.yml` di akar repositori |
| PostgreSQL 17   | Wajib. Q20 memakai `JSON_TABLE` yang baru tersedia sejak versi 17 |
| Basis data `pagila` | Dipulihkan pada Latihan P01 dari `dump/pagila.dump` |

Kredensial lingkungan latihan: pengguna `msbd`, basis data `pagila`, container `msbd-pg`.

### Verifikasi sebelum mulai

```bash
docker compose up -d
docker compose ps                       # msbd-pg harus Up (healthy)

docker compose exec postgres psql -U msbd -d pagila -c "SELECT version();"
docker compose exec postgres psql -U msbd -d pagila -c "SELECT count(*) AS film FROM film;"
```

Hasil yang diharapkan: PostgreSQL 17.x dan tabel `film` berisi 1000 baris.

Bila muncul `database "pagila" does not exist`, pulihkan lebih dulu:

```bash
docker compose exec postgres createdb -U msbd pagila
docker compose exec postgres pg_restore -U msbd -d pagila --no-owner /dump/pagila.dump
```

## Menjalankan Setup

Berkas `q00_setup.sql` membuat tabel bantu `pegawai` (dipakai Q6–Q9) dan `notifikasi`
(dipakai Q19–Q20). Berkas ini idempoten, aman dijalankan berulang kali.

```bash
docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 \
  -f /dev/stdin < latihan/p03/q00_setup.sql
```

Pada Command Prompt Windows, ganti pemisah jalur menjadi backslash:

```bat
docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 -f /dev/stdin < latihan\p03\q00_setup.sql
```

Verifikasi:

```bash
docker compose exec postgres psql -U msbd -d pagila -c "SELECT count(*) FROM pegawai;"     # 7
docker compose exec postgres psql -U msbd -d pagila -c "SELECT count(*) FROM notifikasi;"  # 3
```

## Menjalankan Jawaban

Pola yang sama dipakai untuk seluruh berkas jawaban, cukup ganti nama berkasnya:

```bash
docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 \
  -f /dev/stdin < latihan/p03/q01_tarif_di_atas_rata.sql
```

Bentuk yang lebih singkat, memakai nama container langsung:

```bash
docker exec -i msbd-pg psql -U msbd -d pagila < latihan/p03/q01_tarif_di_atas_rata.sql
```

Opsi `-v ON_ERROR_STOP=1` penting. Tanpa opsi itu psql melanjutkan ke perintah
berikutnya setelah menemui galat lalu keluar dengan status sukses, sehingga berkas
yang separuh isinya gagal tampak seolah berjalan mulus.

## Urutan Menjalankan

Jalankan berurutan. `q00_setup.sql` wajib lebih dulu karena Q6–Q9 dan Q19–Q20
bergantung pada tabel yang dibuatnya.

| Urutan | Berkas | Isi |
|--------|--------|-----|
| 1  | `q00_setup.sql`                        | Tabel bantu `pegawai` dan `notifikasi` |
| 2  | `q01_tarif_di_atas_rata.sql`           | Subquery skalar |
| 3  | `q02_kategori_lebih_60.sql`            | Derived table dan HAVING |
| 4  | `q03_pelanggan_pembayaran_besar.sql`   | EXISTS berkorelasi |
| 5  | `q04_film_tidak_pernah_disewa.sql`     | NOT IN dan NOT EXISTS |
| 6  | `q05_tarif_tertinggi_per_toko.sql`     | Subquery berkorelasi dengan max() |
| 7  | `q06_cte_kategori.sql`                 | CTE bertingkat |
| 8  | `q07_hierarki_pegawai.sql`             | Recursive CTE |
| 9  | `q08_bawahan_bima.sql`                 | Recursive CTE dengan anchor tersaring |
| 10 | `q09_rekursi_tahan_siklus.sql`         | Rekursi tahan siklus — **mengubah data, lihat catatan di bawah** |
| 11 | `q10_tiga_peringkat_tarif.sql`         | ROW_NUMBER, RANK, DENSE_RANK |
| 12 | `q11_tiga_film_tertinggi.sql`          | Window function disaring di lapisan luar |
| 13 | `q12_perubahan_omzet_harian.sql`       | LAG dan persentase perubahan |
| 14 | `q13_kumulatif_rerata_7hari.sql`       | Frame ROWS eksplisit |
| 15 | `q14_rows_vs_range.sql`                | Perbandingan ROWS dan RANGE |
| 16 | `q15_riwayat_pembayaran_pelanggan.sql` | PARTITION BY per pelanggan |
| 17 | `q16_rollup_kategori_rating.sql`       | ROLLUP dan GROUPING() |
| 18 | `q17_filter_per_kategori.sql`          | Agregat FILTER dan CASE WHEN |
| 19 | `q18_rekonsiliasi_inventory_rental.sql`| EXCEPT dan UNION ALL |
| 20 | `q19_notifikasi_lunas.sql`             | JSONB dan indeks GIN |
| 21 | `q20_bentangkan_kontak.sql`            | JSON_TABLE dan LEFT JOIN LATERAL |
| 22 | `r1_laporan_bulanan.sql`               | Laporan pendapatan bulanan terpadu |

Menjalankan seluruhnya sekaligus pada Pagila yang bersih:

```bash
for f in latihan/p03/q*.sql latihan/p03/r1_*.sql; do
  echo "=== $f"
  docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 \
    -f /dev/stdin < "$f" || break
done
```

## Catatan Penting — Q9 Mengubah Data

`q09_rekursi_tahan_siklus.sql` sengaja membuat siklus pada tabel `pegawai` untuk
menguji ketahanan recursive CTE:

```sql
UPDATE pegawai SET atasan_id = 6 WHERE pegawai_id = 1;
```

**Data wajib dipulihkan segera setelah pengujian selesai:**

```sql
UPDATE pegawai SET atasan_id = NULL WHERE pegawai_id = 1;
```

Verifikasi pemulihan — `atasan_id` milik Rina (`pegawai_id` 1) harus kembali kosong:

```bash
docker compose exec postgres psql -U msbd -d pagila \
  -c "SELECT pegawai_id, nama, atasan_id FROM pegawai ORDER BY 1;"
```

Bila data tertinggal dalam keadaan bersiklus, Q7 dan Q8 tidak lagi menghasilkan
apa pun karena tidak ada baris dengan `atasan_id IS NULL` sebagai anchor.

Query rekursif tanpa pengaman dapat terus berjalan dan menghabiskan memori.
Siapkan Ctrl-C sebelum menjalankan Q9. Bila layanan tidak responsif:

```bash
docker compose restart postgres
```

## Struktur Folder

```
latihan/p03/
├── README.md          # berkas ini
├── laporan.md         # laporan, jawaban reflektif A–E, temuan Q14
├── q00_setup.sql      # tabel bantu
├── q01 … q20 .sql     # jawaban Q1–Q20
├── r1_laporan_bulanan.sql
├── r1_10_baris.png    # tangkapan layar sepuluh baris pertama R1
└── bukti/             # tangkapan layar pendukung
```
