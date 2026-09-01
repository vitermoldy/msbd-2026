# Latihan 2 — Sistem Helpdesk & Pelaporan Fasilitas Kampus

Mata kuliah : TIF2104 — Manajemen Sistem Basis Data
Pertemuan   : 2 — Dari Kebutuhan ke Skema Berversi
Kelompok    : (isi nama kelompok)

| No | NIM       | Nama                          | GitHub         | Tanggung jawab Pertemuan 2                          |
|----|-----------|-------------------------------|----------------|-----------------------------------------------------|
| 1  | 251402079 | Viter Moldy Kesuma            | vitermoldy     | Langkah 1, Langkah 2 — `kebutuhan.md`, `README.md`  |
| 2  | 251402067 | Siti Naifah Batubara          | naifah13       | Langkah 3 — `erd.png`, serta kurator folder `bukti/` |
| 3  | 251402056 | Rizky Cristian Fero Sihombing | RizkySihombing | Langkah 4 — service Flyway, migration V1 dan V2      |
| 4  | 251402038 | Gideon Finsus Siburian        | DeezG-web      | Langkah 5 — migration V3–V5, eksperimen locking      |
| 5  | 251402050 | Nadine Tantiara Hutagaol      | nadinehutagaol | Langkah 6 — seed data, serta `laporan.md`            |

Pembagian pertanyaan (jawaban ditulis di dalam `laporan.md`):

| Pertanyaan | Ada di    | Narasumber | Penulis jawaban |
|------------|-----------|------------|-----------------|
| 1          | Langkah 1 | Viter      | Nadine          |
| 2          | Langkah 2 | Viter      | Nadine          |
| 3 dan 4    | Langkah 3 | Naifah     | Nadine          |
| 5          | Langkah 4 | Rizky      | Nadine          |
| 6          | Langkah 5 | Finsus     | Nadine          |
| 7          | Langkah 6 | Nadine     | Nadine          |

Setiap pemegang langkah menyerahkan catatan hasil kerjanya ke `bukti/catatan-langkahN.md`
sebagai bahan mentah bagi penulis laporan.

---

## Prasyarat

- Docker Desktop berjalan
- Seluruh perintah dijalankan dari **root repositori** (`C:\msbd-2026`), bukan dari
  dalam folder `latihan/p02`, karena `docker-compose.yml` dan path volume Flyway
  bersifat relatif terhadap root

### Kredensial basis data

Diambil dari `docker-compose.yml` repositori ini — **bukan** `postgres/postgres`:

| Item              | Nilai       |
|-------------------|-------------|
| Service Compose   | `postgres`  |
| User              | `msbd`      |
| Password          | `msbd2026`  |
| Database bawaan   | `latihan`   |
| Database latihan  | `proyek_dev`, `proyek_test` |

Setiap perintah `psql` wajib menyertakan `-d`. Tanpa itu psql memakai nama user
sebagai nama database dan gagal dengan `FATAL: database "msbd" does not exist`.

---

## 1. Menjalankan lingkungan

```
docker compose up -d
docker compose ps
```

Pastikan container `msbd-pg` berstatus `Up (healthy)`.

## 2. Membuat database latihan (sekali saja)

```
docker compose exec postgres psql -U msbd -d latihan -c "CREATE DATABASE proyek_dev;"
docker compose exec postgres psql -U msbd -d latihan -c "CREATE DATABASE proyek_test;"
```

Verifikasi:

```
docker compose exec postgres psql -U msbd -d latihan -l | findstr proyek
```

> Di Git Bash / Linux / macOS, ganti `findstr` menjadi `grep`.

Bila muncul `ERROR: database "proyek_dev" already exists`, itu bukan kegagalan —
database tersebut memang sudah dibuat sebelumnya.

## 3. Menjalankan migration

Service `flyway` harus sudah ditambahkan pada `docker-compose.yml` (lihat Langkah 4).

```
docker compose run --rm flyway migrate
docker compose run --rm flyway info
```

Memeriksa riwayat migration:

```
docker compose exec postgres psql -U msbd -d proyek_dev -c "SELECT installed_rank, version, description, success FROM flyway_schema_history ORDER BY installed_rank;"
```

## 4. Membangun ulang database dari nol

Digunakan untuk membuktikan seluruh skema dapat dibangun ulang hanya dari migration:

```
docker compose exec postgres psql -U msbd -d latihan -c "DROP DATABASE proyek_dev; CREATE DATABASE proyek_dev;"
docker compose run --rm flyway migrate
docker compose run --rm flyway info
```

## 5. Menjalankan seed data

Seed bersifat idempoten — aman dijalankan berkali-kali tanpa menghasilkan data ganda.

Command Prompt (jalankan satu baris per satu baris):

```
docker compose exec -T postgres psql -U msbd -d proyek_dev < latihan\p02\seeds\01_peran.sql
docker compose exec -T postgres psql -U msbd -d proyek_dev < latihan\p02\seeds\02_kategori_masalah.sql
docker compose exec -T postgres psql -U msbd -d proyek_dev < latihan\p02\seeds\03_lokasi_fasilitas.sql
```

Git Bash / Linux / macOS:

```
for f in latihan/p02/seeds/*.sql; do
  docker compose exec -T postgres psql -U msbd -d proyek_dev < "$f"
done
```

Memeriksa hasilnya:

```
docker compose exec postgres psql -U msbd -d proyek_dev -c "SELECT (SELECT count(*) FROM peran) AS peran, (SELECT count(*) FROM kategori_masalah) AS kategori, (SELECT count(*) FROM lokasi) AS lokasi, (SELECT count(*) FROM fasilitas) AS fasilitas;"
```

Berapa kali pun seed dijalankan, jumlah baris harus tetap: 6 peran, 6 kategori,
3 lokasi, 3 fasilitas.

---

## Struktur folder

```
latihan/p02/
├── kebutuhan.md      dokumen kebutuhan data (lingkup + KD-01 s/d KD-08)
├── erd.png           ERD konseptual — 10 entitas
├── migrations/       skema berversi yang dikelola Flyway
│   ├── V1__skema_awal.sql
│   ├── V2__transaksi_tiket.sql
│   ├── V3__petugas_langkah1_tambah_nullable.sql
│   ├── V4__petugas_langkah2_isi_data_lama.sql
│   └── V5__petugas_langkah3_pasang_constraint.sql
├── seeds/            data acuan idempoten
│   ├── 01_peran.sql
│   ├── 02_kategori_masalah.sql
│   └── 03_lokasi_fasilitas.sql
├── bukti/            screenshot dan catatan hasil tiap langkah
├── laporan.md        laporan pengerjaan Pertemuan 2
└── README.md         berkas ini
```

---

## Aturan kerja kelompok

1. **Migration yang sudah diterapkan tidak boleh diubah.** Flyway menyimpan checksum
   tiap file di `flyway_schema_history`; mengubah file lama membuat anggota lain gagal
   `migrate` dengan `checksum mismatch`. Perbaikan apa pun dituangkan ke migration
   baru bernomor lebih tinggi.
2. **Jangan menjalankan `git add .`** dari root repositori. Tambahkan hanya file yang
   menjadi bagian kalian, agar riwayat kontribusi tetap jelas.
3. **Setiap anggota melakukan commit dengan akun sendiri.** Atur sekali di tiap
   komputer:

   ```
   git config user.name  "Nama Anggota"
   git config user.email "email-akun-github@contoh.com"
   ```

   Memeriksa kontribusi seluruh anggota:

   ```
   git shortlog -sne -- latihan/p02/
   ```
