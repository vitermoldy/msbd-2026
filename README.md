# msbd-2026

Repositori tim untuk mata kuliah **Manajemen Sistem Basis Data (MSBD)**
S-1 Teknologi Informasi · Fakultas Ilmu Komputer dan Teknologi Informasi
Kelas 1011-TIF2104-B-20261 · Ganjil T.A. 2026/2027

Berisi lingkungan kerja basis data, hasil latihan, dan artefak pembelajaran selama satu semester.

---

## Daftar Isi

1. [Anggota Tim](#anggota-tim)
2. [Lingkungan](#lingkungan)
3. [Prasyarat](#prasyarat)
4. [Mulai Cepat](#mulai-cepat)
5. [Langkah Pengerjaan Latihan P01](#langkah-pengerjaan-latihan-p01)
6. [Struktur Direktori](#struktur-direktori)
7. [Aturan Repositori](#aturan-repositori)
8. [Catatan Pengguna Windows](#catatan-pengguna-windows)
9. [Pemecahan Masalah](#pemecahan-masalah)

---

## Anggota Tim

| No | NIM | Nama | Akun GitHub | Bagian yang dikerjakan |
|----|-----|------|-------------|------------------------|
| 1 | [NIM] | [Nama Lengkap] | [@username] | `docker-compose.yml`, `.gitignore` |
| 2 | [NIM] | [Nama Lengkap] | [@username] | `README.md` |
| 3 | [NIM] | [Nama Lengkap] | [@username] | `latihan/p01/verifikasi.sql` |
| 4 | [NIM] | [Nama Lengkap] | [@username] | `latihan/p01/perintah.md` |
| 5 | [NIM] | [Nama Lengkap] | [@username] | `latihan/p01/laporan.md`, `bukti/` |

---

## Lingkungan

Seluruh basis data dijalankan sebagai container Docker. Tidak ada perangkat lunak basis data yang perlu dipasang langsung ke sistem operasi.

| Layanan | Image | Port host | Nama container |
|---------|-------|-----------|----------------|
| PostgreSQL | `postgres:17` | 5432 | `msbd-pg` |
| MongoDB | `mongo:8` | 27017 | `msbd-mongo` |
| Redis | `redis:7-alpine` | 6379 | `msbd-redis` |

**Kredensial (khusus lingkungan latihan):**

| Parameter | Nilai |
|-----------|-------|
| Username | `msbd` |
| Password | `msbd2026` |
| Database awal | `latihan` |
| Database contoh | `pagila` |

> Kredensial ini ditulis apa adanya karena hanya dipakai di lingkungan latihan lokal. Pada proyek nyata, nilai seperti ini dipindahkan ke berkas `.env` yang tidak pernah di-commit, lalu dirujuk sebagai `${POSTGRES_PASSWORD}` di dalam `docker-compose.yml`.

---

## Prasyarat

| Perangkat lunak | Catatan |
|-----------------|---------|
| Docker Desktop | Windows memerlukan WSL 2 aktif |
| Git | Sudah dikonfigurasi `user.name` dan `user.email` |
| DBeaver Community Edition | Java sudah termasuk dalam installer |
| `pagila.dump` | Diunduh dari LMS — **tidak disertakan dalam repositori ini** |

---

## Mulai Cepat

```bash
git clone https://github.com/NAMA-TIM/msbd-2026.git
cd msbd-2026
docker compose up -d
docker compose ps
```

Tunggu sampai `msbd-pg` berstatus `Up ... (healthy)`. Penjalanan pertama mengunduh sekitar 600 MB image.

Lalu unduh `pagila.dump` dari LMS ke folder `dump/`, dan lanjutkan ke [Langkah 4](#langkah-4--restore-pagila-dan-verifikasi).

---

## Langkah Pengerjaan Latihan P01

Bagian ini mendokumentasikan seluruh langkah agar siapa pun dapat mereproduksi hasil latihan dari nol.

### Langkah 1 · Verifikasi Docker

```bash
docker --version
docker compose version
docker run --rm hello-world
```

**Hasil yang diharapkan:** perintah ketiga menampilkan baris `Hello from Docker!`

Pada penjalanan pertama, Docker akan mengunduh image `hello-world` lebih dulu dan menampilkan baris `Unable to find image 'hello-world:latest' locally`. Baris ini tidak muncul lagi pada penjalanan berikutnya karena image sudah tersimpan lokal.

---

### Langkah 2 · Menjalankan Docker Compose

Validasi berkas konfigurasi tanpa menjalankan apa pun:

```bash
docker compose config
```

Jalankan lingkungan:

```bash
docker compose up -d
docker compose ps
```

**Hasil yang diharapkan:**

```
NAME         IMAGE            SERVICE    STATUS
msbd-mongo   mongo:8          mongo      Up (n) minutes
msbd-pg      postgres:17      postgres   Up (n) minutes (healthy)
msbd-redis   redis:7-alpine   redis      Up (n) minutes
```

Bila `msbd-pg` masih bertuliskan `(health: starting)`, tunggu 20–30 detik lalu ulangi. PostgreSQL sedang melakukan inisialisasi cluster untuk pertama kali.

Melihat log:

```bash
docker compose logs postgres | tail -20                    # Linux/macOS
docker compose logs postgres | Select-Object -Last 20      # PowerShell
```

> **Catatan tentang pesan `FATAL: database "msbd" does not exist` di log.**
> Ini normal dan tidak berbahaya. Blok `healthcheck` menjalankan `pg_isready -U msbd` tanpa menyebut database, sehingga PostgreSQL memakai aturan bawaannya: mencari database yang namanya sama dengan username. Database `msbd` memang tidak ada — yang ada adalah `latihan`. Namun karena server sanggup membalas, `pg_isready` tetap menganggapnya sukses dan status container tetap `healthy`. Bila ingin log bersih, ubah menjadi `pg_isready -U msbd -d latihan`.

**Penjelasan blok konfigurasi:**

| Bagian | Fungsi |
|--------|--------|
| `image: postgres:17` | Versi disebut eksplisit agar lingkungan identik di semua komputer |
| `environment:` | Membuat superuser `msbd` dan database awal `latihan` — hanya berlaku saat volume masih kosong |
| `ports: "5432:5432"` | Pemetaan `HOST:CONTAINER`, agar DBeaver di Windows bisa menembus ke dalam container |
| `pgdata:/var/lib/postgresql/data` | Named volume — membuat data bertahan setelah container dihapus |
| `./dump:/dump` | Bind mount — folder `dump/` lokal muncul sebagai `/dump` di dalam container |
| `healthcheck:` | Menentukan status `healthy`, sehingga layanan lain bisa menunggu lewat `depends_on` |

---

### Langkah 3 · Akses melalui psql dan DBeaver

#### psql

```bash
docker compose exec postgres psql -U msbd -d latihan
```

Di dalam prompt `latihan=#`:

```sql
SELECT version();
\l
\dt
\dn
\du
SHOW data_directory;
SHOW shared_buffers;
\timing on
\q
```

| Perintah | Hasil yang diharapkan |
|----------|----------------------|
| `SELECT version();` | `PostgreSQL 17.x (Debian ...) on x86_64-pc-linux-gnu` |
| `\l` | `latihan`, `postgres`, `template0`, `template1` |
| `\dt` | `Did not find any relations.` — benar, database `latihan` memang kosong |
| `\dn` | Hanya skema `public` |
| `\du` | Role `msbd` dengan atribut `Superuser, Create role, Create DB` |
| `SHOW data_directory;` | `/var/lib/postgresql/data` — titik pasang volume `pgdata` |
| `SHOW shared_buffers;` | `128MB` |

> **Perintah berawalan `\` adalah meta-command psql, bukan SQL — tidak memakai titik koma.** `\timing on;` akan ditolak dengan pesan `Boolean expected`; yang benar `\timing on`. Sebaliknya, perintah SQL wajib diakhiri titik koma.

> **Kaitan dengan teori.** `SHOW data_directory` dan `SHOW shared_buffers` memperlihatkan lapisan fisik. Memindahkan direktori data ke disk lain atau menaikkan `shared_buffers` tidak mengubah satu pun perintah `SELECT` — inilah yang disebut **kemandirian data fisik**.

#### DBeaver

| Parameter | Nilai |
|-----------|-------|
| Host | `localhost` |
| Port | `5432` |
| Database | `pagila` |
| Username | `msbd` |
| Password | `msbd2026` |

Agar `pagila` terlihat di navigator: klik kanan koneksi → **Edit Connection** → tab **PostgreSQL** → centang **Show all databases** → OK → reconnect.

ER Diagram: `pagila` → **Schemas** → **public** → tab **ER Diagram**.

---

### Langkah 4 · Restore Pagila dan Verifikasi

Letakkan `pagila.dump` di folder `dump/`, lalu:

```bash
docker compose exec postgres createdb -U msbd pagila
docker compose exec postgres pg_restore -U msbd -d pagila --no-owner /dump/pagila.dump
docker compose exec postgres psql -U msbd -d pagila -c "\dt"
```

| Bagian | Alasan |
|--------|--------|
| `createdb` | `pg_restore` tidak membuat database tujuan untuk dump format custom |
| `--no-owner` | Mengabaikan role pemilik asli yang tidak ada di server ini; semua objek menjadi milik `msbd` |
| `/dump/pagila.dump` | Jalur **di dalam container**, hasil bind mount `./dump:/dump` |

**Hasil yang diharapkan: 21 relasi.**

Perincian 21 tersebut: 14 tabel biasa, 1 tabel terpartisi (`payment`), dan 6 partisi (`payment_p2017_01` sampai `payment_p2017_06`). Data pembayaran memang dipecah per bulan.

#### Query verifikasi

Seluruhnya tersimpan di [`latihan/p01/verifikasi.sql`](latihan/p01/verifikasi.sql).

```bash
docker compose exec -T postgres psql -U msbd -d pagila -f /dump/verifikasi.sql
```

| Query | Isi | Hasil rujukan |
|-------|-----|---------------|
| V1 | Jumlah tabel pada skema `public` | `21` |
| V2 | Sepuluh tabel terbesar beserta ukurannya | `rental` dan `payment` teratas |
| V3 | Lima film dengan penyewaan terbanyak | sekitar 33–34 penyewaan per judul teratas |
| V4 | `EXPLAIN ANALYZE` atas query agregasi V3 | pohon rencana eksekusi |

Catatan singkat tiap query:

- **V1** memakai `information_schema`, katalog standar SQL. Syarat `table_type = 'BASE TABLE'` penting karena Pagila juga berisi beberapa view.
- **V2** memakai `pg_total_relation_size`, yang menghitung ukuran termasuk indeks dan data TOAST. Pengurutan dilakukan pada nilai byte aslinya, bukan pada teks hasil `pg_size_pretty` — kalau diurutkan berdasarkan teks, `"9 MB"` akan dianggap lebih besar daripada `"10 MB"`.
- **V3** membutuhkan dua JOIN berantai karena `rental` menunjuk ke `inventory` (keping fisik DVD), dan barulah `inventory` menunjuk ke `film`.
- **V4** benar-benar menjalankan query dan melaporkan waktu nyata. `cost=` adalah perkiraan optimizer dalam unit biaya internal; `actual time=` adalah waktu terukur dalam milidetik.

---

### Langkah 5 · Repositori Git

```bash
git init
git add .
git status                                    # pastikan pagila.dump TIDAK muncul
git commit -m "chore: menyiapkan lingkungan MSBD"
git branch -M main
git remote add origin https://github.com/NAMA-TIM/msbd-2026.git
git push -u origin main
```

Alur untuk anggota berikutnya:

```bash
git clone https://github.com/NAMA-TIM/msbd-2026.git
cd msbd-2026
git config --global user.name "Nama Lengkap"
git config --global user.email "email-github@contoh.com"

# setelah menyunting berkas bagiannya
git pull --rebase
git add latihan/p01/verifikasi.sql
git commit -m "feat: menambahkan query verifikasi V1-V4"
git push
```

Memverifikasi kontribusi seluruh anggota:

```bash
git shortlog -sne
git log --pretty=format:"%h  %an  %ad  %s" --date=short
```

---

### Langkah 6 · Pengumpulan

Empat berkas yang harus lengkap sebelum dikumpulkan:

| Berkas | Isi |
|--------|-----|
| `latihan/p01/laporan.md` | Laporan utama sesuai daftar isi minimal |
| `latihan/p01/verifikasi.sql` | Query V1–V4 |
| `latihan/p01/perintah.md` | Catatan perintah dan keluarannya |
| `latihan/p01/bukti/` | Tangkapan layar pendukung |

Kirim URL repositori ini lewat aktivitas pengumpulan di Moodle.

---

### Tantangan Tambahan · Efek Indeks

```sql
\timing on

CREATE TABLE besar AS
SELECT g AS id, md5(g::text) AS nilai
FROM generate_series(1, 2000000) g;

SELECT nilai FROM besar WHERE id = 1234567;

EXPLAIN ANALYZE SELECT * FROM besar WHERE nilai = '<nilai-md5>';

CREATE INDEX ON besar(nilai);
ANALYZE besar;

EXPLAIN ANALYZE SELECT * FROM besar WHERE nilai = '<nilai-md5>';
```

| Kondisi | Jenis pemindaian | Execution Time |
|---------|------------------|----------------|
| Tanpa indeks | `Seq Scan` (2.000.000 baris) | ± 180–450 ms |
| Dengan indeks B-tree | `Index Scan` | ± 0,05–1 ms |

Indeks tidak gratis: ia memakan ruang penyimpanan tambahan dan memperlambat `INSERT`, `UPDATE`, serta `DELETE` karena ikut diperbarui setiap kali data berubah.

---

## Struktur Direktori

```
msbd-2026/
├── docker-compose.yml      # definisi lingkungan tiga layanan
├── .gitignore              # pengecualian berkas dump dan kredensial
├── README.md
├── dump/                   # berkas .dump lokal diabaikan Git
├── latihan/
│   └── p01/
│       ├── perintah.md     # catatan perintah dan keluarannya
│       ├── verifikasi.sql  # query V1–V4
│       ├── laporan.md      # laporan latihan
│       └── bukti/          # tangkapan layar pendukung
└── proyek/
    └── docs/               # dokumen proyek
```

---

## Aturan Repositori

- Berkas `*.dump`, `.env`, dan kredensial **tidak boleh** masuk repositori. Setiap anggota mengunduh `pagila.dump` sendiri ke folder `dump/`.
- Setiap anggota melakukan commit menggunakan akun masing-masing.
- Jalankan `git pull --rebase` sebelum `push`.
- `git add` menyebut nama berkas spesifik; hindari `git add .` setelah commit awal.

**Konvensi pesan commit:**

| Awalan | Untuk |
|--------|-------|
| `feat:` | Menambah sesuatu yang baru |
| `fix:` | Memperbaiki kesalahan |
| `docs:` | Dokumentasi, laporan, catatan |
| `chore:` | Pekerjaan penunjang, konfigurasi |

---

## Catatan Pengguna Windows

Beberapa perintah pada modul ditulis untuk terminal Linux/macOS. Padanannya di PowerShell:

| Modul (Linux/macOS) | PowerShell |
|---------------------|------------|
| `... \| tail -20` | `... \| Select-Object -Last 20` |
| `printf '...' > .gitignore` | `Set-Content .gitignore "baris1","baris2"` |
| `touch .gitkeep` | `New-Item -ItemType File .gitkeep` |
| `mkdir -p a/b/c` | `New-Item -ItemType Directory -Force a\b\c` |

Simpan folder kerja di luar direktori yang disinkronkan OneDrive (mis. langsung di `C:\`). OneDrive dapat mengganti berkas dengan penanda kosong, yang merusak repositori Git dan membuat bind mount Docker gagal membaca berkas dump.

---

## Pemecahan Masalah

| Gejala | Penyebab | Solusi |
|--------|----------|--------|
| `error during connect ... dockerDesktopLinuxEngine` | Docker Desktop belum berjalan | Buka Docker Desktop, tunggu **Engine running** |
| `docker: The term 'docker' is not recognized` | Jendela terminal dibuka sebelum Docker terpasang, atau dibuka sebagai Administrator (instalasi *per-user*) | Tutup dan buka PowerShell baru tanpa Run as administrator |
| `Connection refused` di DBeaver | Container tidak berjalan | `docker compose up -d`, tunggu `(healthy)` |
| `port is already allocated` | Port 5432 dipakai PostgreSQL lain | Ubah ke `"5433:5432"`, gunakan port 5433 di DBeaver |
| `no configuration file provided` | Tidak berada di folder repositori, atau berkas tersimpan sebagai `docker-compose.yml.txt` | `cd` ke folder repositori; periksa nama berkas dengan `dir` |
| `yaml: line N: did not find expected key` | Indentasi YAML salah atau memakai Tab | Gunakan spasi, kelipatan dua; validasi dengan `docker compose config` |
| `could not open input file /dump/pagila.dump` | Berkas tidak ada di `dump/`, atau bernama `pagila.dump.txt` | Aktifkan tampilan ekstensi berkas, periksa dengan `dir dump -Force` |
| V1 menjawab `0` | Masih tersambung ke database `latihan` | Pastikan prompt bertuliskan `pagila=#` |
| `pagila` tidak terlihat di DBeaver | *Show all databases* belum diaktifkan | Edit Connection → tab PostgreSQL → centang opsi tersebut |
| Push ditolak, `Updates were rejected` | Ada anggota lain yang push lebih dulu | `git pull --rebase` lalu `git push` |

---

## Progres Latihan

- [x] **P01** — Menyiapkan lingkungan kerja basis data
