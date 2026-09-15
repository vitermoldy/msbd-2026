# Latihan Pertemuan 4 — SQL Lanjutan II

Mata kuliah : TIF2104 — Manajemen Sistem Basis Data
Pertemuan   : 4 — SQL Lanjutan II: Audit Log, Materialized View, dan Migrasi Aman
Basis data  : Pagila pada PostgreSQL 17, seluruh percobaan pada skema `lab4`

## Tujuan

Menerapkan aturan dan perubahan skema pada PostgreSQL 17: view fasad dan `WITH CHECK
OPTION`, materialized view beserta refresh concurrent, trigger audit level baris dan level
pernyataan, penegakan aturan lewat `CHECK`, unique index parsial, foreign key, dan `EXCLUDE`,
serta penggantian kolom pada tabel berisi data melalui pola expand–contract tanpa membuat
pembaca lama gagal.

Seperti Pertemuan 3, yang dinilai bukan hanya hasil yang benar tetapi juga alasan pemilihan
bentuk SQL. Karena itu setiap berkas jawaban diawali tiga komentar: apa yang diminta soal,
bentuk yang dipilih beserta alasannya, dan satu alternatif yang dipertimbangkan tetapi tidak
dipakai.

## Anggota dan Tanggung Jawab

| No | NIM | Nama | GitHub | Tanggung jawab Pertemuan 4 |
|----|-----------|-------------------------------|----------------|------------------------------------------------|
| 1 | 251402079 | Viter Moldy Kesuma | vitermoldy | Langkah 1–3 — `q00_setup.sql`, Q1–Q8, Refleksi A dan B, `README.md` |
| 2 | 251402067 | Siti Naifah Batubara | naifah13 | Langkah 4 — Q9–Q13, Refleksi C |
| 3 | 251402050 | Nadine Tantiara Hutagaol | nadinehutagaol | Langkah 5 — Q14–Q17, Refleksi D |
| 4 | 251402038 | Gideon Finsus Siburian | DeezG-web | Langkah 6 — Q18–Q21, Refleksi E, enam pasang migrasi `migrations/` |
| 5 | 251402056 | Rizky Cristian Fero Sihombing | RizkySihombing | Langkah 7 — `laporan.md` terpadu, penggabungan bukti dan tabel waktu |

Pemeriksaan silang mengikuti cincin tertutup yang sama seperti Pertemuan 3.

## Prasyarat

| Perangkat lunak | Catatan |
|-----------------|---------|
| Docker Desktop | Layanan `postgres` pada `docker-compose.yml` di akar repositori |
| PostgreSQL 17 | Wajib. Container `msbd-pg` |
| Basis data `pagila` | Dipulihkan pada Latihan P01 dari `dump/pagila.dump` |
| Ekstensi `btree_gist` | Dipasang otomatis oleh `q17`; diperlukan constraint `EXCLUDE` |
| Dua terminal | Q8 dan Q18–Q20 menuntut dua sesi psql berjalan bersamaan |

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

`q00_setup.sql` membuat skema `lab4`, menyalin `public.film` menjadi `lab4.film`, dan mengisi
`lab4.jejak_akses` dengan 500000 baris. Seluruh percobaan destruktif latihan ini terjadi di
`lab4`, sehingga data Pagila asli dan tabel bantu Pertemuan 3 di skema `public` tetap aman.

Command Prompt:

```bat
docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 -f /dev/stdin < latihan\p04\q00_setup.sql
```

PowerShell — operator `<` tidak berlaku, gunakan pipe:

```powershell
Get-Content -Raw latihan\p04\q00_setup.sql | docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 -f /dev/stdin
```

Verifikasi. Jangan melanjutkan bila salah satu tidak sesuai:

```bash
docker compose exec postgres psql -U msbd -d pagila -c "SELECT count(*) FROM lab4.jejak_akses;"  # 500000
docker compose exec postgres psql -U msbd -d pagila -c "SELECT count(*) FROM lab4.film;"         # 1000
```

> **Peringatan.** `q00_setup.sql` memuat `DROP TABLE ... CASCADE`. Menjalankannya ulang di
> tengah latihan akan menghapus seluruh hasil Q1–Q20. Jalankan ulang hanya bila memang ingin
> mulai dari nol, dan bila diulang kerjakan kembali Q1–Q21 secara berurutan.

## Menjalankan Jawaban

Pola yang sama dipakai untuk seluruh berkas jawaban, cukup ganti nama berkasnya:

```bat
docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 -f /dev/stdin < latihan\p04\q01_view_film_murah.sql
```

Opsi `-v ON_ERROR_STOP=1` penting. Tanpa opsi itu psql melanjutkan ke perintah berikutnya
setelah menemui galat lalu keluar dengan status sukses, sehingga berkas yang separuh isinya
gagal tampak berjalan mulus.

> **Pengecualian.** Berkas `q03`, `q04`, `q06`, `q07`, `q14`, `q15`, `q16`, dan `q17` memang
> dirancang menghasilkan galat di tengah berkas, dan sisa pernyataannya masih harus
> dijalankan. Untuk kedelapan berkas itu, jalankan **tanpa** `-v ON_ERROR_STOP=1`.

## Urutan Menjalankan

Jalankan berurutan. Urutannya tidak boleh diacak: setiap soal bergantung pada objek dan data
yang dibuat soal sebelumnya.

| Urutan | Berkas | Isi |
|--------|--------|-----|
| 1  | `q00_setup.sql`                       | Skema `lab4`, salinan `film`, 500000 jejak akses |
| 2  | `q01_view_film_murah.sql`             | View tanpa check option |
| 3  | `q02_baris_menghilang.sql`            | Bukti baris menghilang |
| 4  | `q03_check_option.sql`                | `WITH CASCADED CHECK OPTION` — **galat disengaja** |
| 5  | `q04_view_pendapatan_kategori.sql`    | View beragregasi tidak auto-updatable — **galat disengaja** |
| 6  | `q05_query_dasar_akses.sql`           | Garis dasar waktu agregasi |
| 7  | `q06_buat_matview.sql`                | Matview `WITH NO DATA` — **galat disengaja** |
| 8  | `q07_refresh_concurrently.sql`        | Refresh concurrent dan index unik — **galat disengaja** |
| 9  | `q08_buktikan_pembaca.sql`            | Bukti pembaca tidak terblokir — **dua sesi** |
| 10 | `q09_trigger_audit_baris.sql`         | Trigger audit level baris |
| 11 | `q10_uji_audit_baris.sql`             | Tiga kasus uji audit |
| 12 | `q11_null_pada_trigger.sql`           | `<>` lawan `IS DISTINCT FROM` — **mengubah data, lihat catatan** |
| 13 | `q12_biaya_trigger_baris.sql`         | Biaya trigger per baris |
| 14 | `q13_trigger_pernyataan.sql`          | Trigger level pernyataan dan transition table |
| 15 | `q14_check_not_valid.sql`             | `CHECK` dua tahap `NOT VALID` lalu `VALIDATE` |
| 16 | `q15_unique_soft_delete.sql`          | Unique index parsial untuk soft delete |
| 17 | `q16_fk_aksi_referensial.sql`         | `NO ACTION`, `CASCADE`, `SET NULL` |
| 18 | `q17_exclude_harga.sql`               | `EXCLUDE` periode harga tidak tumpang tindih |
| 19 | `q18_expand_tulis_ganda.sql`          | Fase expand — **sesi pembaca harus hidup** |
| 20 | `q19_backfill_bertahap.sql`           | Backfill potongan 1000 film, verifikasi harus nol |
| 21 | `q20_contract_view_fasad.sql`         | Fase contract — **dua sesi, tidak dapat diurungkan penuh** |
| 22 | `q21_migrasi_berversi.md`             | Enam pasang migrasi pada `migrations/` |

## Soal yang Membutuhkan Dua Sesi

### Q8 — membuktikan pembaca tidak terblokir

Buka dua Command Prompt, keduanya:

```bat
cd C:\msbd-2026
docker compose exec -it postgres psql -U msbd -d pagila
```

Di kedua sesi ketik `\timing on` lalu `SET search_path = lab4, public;` — satu baris per
Enter, karena meta-command psql tidak boleh dicampur SQL di baris yang sama.

Sesi 2 dijalankan **lebih dulu** sebagai pembaca berulang, baru refresh ditembakkan dari
sesi 1. Tanpa urutan ini, refresh sering selesai sebelum sempat berpindah jendela:

```sql
SELECT clock_timestamp() AS jam, count(*) AS baris, sum(jumlah_akses) AS total
FROM lab4.ringkasan_akses \watch 0.5
```

Dijalankan dua putaran: satu dengan `REFRESH MATERIALIZED VIEW CONCURRENTLY` dan satu dengan
`REFRESH MATERIALIZED VIEW` biasa. Pada putaran concurrent, detak `\watch` tidak pernah
berhenti. Pada putaran biasa, detaknya melompat sebesar durasi refresh — itulah bukti
pembaca terblokir. Hentikan `\watch` dengan Ctrl+C.

> Q8 menambah 400000 baris permanen ke `lab4.jejak_akses` (200000 per putaran). Setelahnya
> angka Q5 tidak dapat diulang pada kondisi data yang sama. Pastikan pengukuran Q5 sudah
> dicatat sebelum menjalankan Q8.

### Q18–Q20 — sesi pembaca selama expand–contract

Sesi kedua berperan sebagai aplikasi lama dan **dibiarkan hidup sepanjang Q18 sampai Q20**:

```sql
SELECT now() AS waktu_baca, title, rental_rate FROM lab4.film LIMIT 5 \watch 2
```

Setiap tahap yang dijalankan di sesi 1 harus diamati di sesi 2, dan dicatat apakah pembaca
sempat menunggu, dan apakah sampai gagal. Menunggu sesaat pada tahap rename bukan kegagalan;
galat `column ... does not exist` atau `relation ... does not exist` adalah kegagalan, dan
menandakan urutan tahapnya salah.

## Catatan Penting

### Q11 mengubah data

`q11_null_pada_trigger.sql` sengaja memasang trigger cacat berkondisi `<>` lalu mengisi
`rental_rate` dengan `NULL` untuk membuktikan logika tiga nilai. Berkas itu mengembalikan
trigger ke `IS DISTINCT FROM` di bagian akhir. Bila eksekusinya terputus di tengah, periksa
dan bereskan sebelum lanjut ke Q12:

```sql
UPDATE lab4.film SET rental_rate = 0.99 WHERE rental_rate IS NULL;
```

Trigger yang tertinggal dalam bentuk `<>` akan membuat pengukuran Q12 dan Q13 tidak
sebanding.

### Q20 dan migrasi 0046 tidak dapat dipulihkan secara penuh

Fase contract menghapus kolom `lab4.film.rental_rate` setelah nilainya dipindahkan ke
`lab4.harga_film`. Berkas `0046_contract_drop_kolom_lama.down.sql` **hanya dapat membuat
kolomnya kembali**, lalu mengisinya ulang dari `lab4.harga_film`. Artinya yang kembali adalah
harga terkini hasil rekonstruksi — bukan nilai historis kolom lama beserta seluruh riwayat
perubahannya.

Perlakukan 0046 sebagai pintu satu arah. Jangan menjalankannya sebelum seluruh syarat ini
terpenuhi:

1. Verifikasi Q19 menghasilkan nol, dan diulang beberapa kali, bukan sekali tepat setelah backfill.
2. Nilai pada `lab4.harga_film` terbukti cocok dengan kolom lama untuk seluruh film.
3. Tidak ada film yang memiliki lebih dari satu periode harga berjalan.
4. Sesi pembaca terbukti stabil di atas view fasad, dengan catatan waktunya.
5. Cadangan atau snapshot terbaru tersedia.

Tahap contract juga harus dijalankan dalam urutan yang benar. Membalik urutannya akan
membuat pembaca lama gagal:

| Urutan salah | Yang dialami pembaca lama |
|---|---|
| Drop kolom sebelum fasad dipasang | `ERROR: column "rental_rate" does not exist` |
| Rename tabel tanpa membuat view di transaksi yang sama | `ERROR: relation "lab4.film" does not exist` |
| Hentikan tulis ganda sebelum backfill diverifikasi | Tidak ada galat, tetapi perubahan harga hilang diam-diam |
| Drop kolom sebelum trigger dilepas | `ERROR: cannot drop column ... because other objects depend on it` |

### Folder `migrations/` di akar repositori

Enam pasang migrasi 0041–0046 disimpan di `migrations/` pada akar repositori, **bukan** di
`latihan/p02/migrations/`. Keduanya berbeda: service `flyway` pada `docker-compose.yml` hanya
me-mount folder p02 dengan penamaan `V1__…sql`, sedangkan migrasi P04 memakai pola
`0041_…up.sql` dan `0041_…down.sql` serta dijalankan manual dengan psql.

Menguji seluruh rangkaian sebelum dikumpulkan, pada basis data uji dan bukan pada lab yang
sudah berisi bukti Q1–Q20:

```bash
for f in 0041 0042 0043 0044 0045; do
  psql -h localhost -U msbd -d pagila -v ON_ERROR_STOP=1 -f migrations/${f}_*.up.sql
done
```

Uji 0046 terpisah dan paling akhir.

## Struktur Folder

```
latihan/p04/
├── README.md                        # berkas ini
├── laporan.md                       # laporan, pesan galat utuh, refleksi A–E, tabel waktu
├── q00_setup.sql                    # skema lab4 dan 500000 jejak akses
├── q01 … q20 .sql                   # jawaban Q1–Q20
├── q21_migrasi_berversi.md          # catatan migrasi berversi
└── struktur_migrations.png          # tangkapan layar struktur migrations/

migrations/                          # di akar repositori
├── 0041_expand_buat_harga_film.up.sql / .down.sql
├── 0042_expand_trigger_tulis_ganda.up.sql / .down.sql
├── 0043_migrate_backfill.up.sql / .down.sql
├── 0044_migrate_verifikasi.up.sql / .down.sql
├── 0045_contract_view_fasad.up.sql / .down.sql
└── 0046_contract_drop_kolom_lama.up.sql / .down.sql
```

## Pengumpulan

Seluruh pekerjaan berada di cabang `latihan/p04-sql2`. Sebelum membuka merge request,
pastikan `q19` sudah menghasilkan nol, `laporan.md` lengkap dengan seluruh bukti dan
refleksi, enam pasang migrasi tersedia dan sudah diuji naik lalu turun, serta setiap anggota
memiliki commit atas namanya sendiri.
