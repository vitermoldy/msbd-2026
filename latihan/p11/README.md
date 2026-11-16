# Latihan P11 — Menutup Pintu yang Terbuka

Peran berlapis, Row-Level Security, query berparameter, enkripsi, penyamaran, audit, dan UU PDP,
seluruhnya pada skema `lab11` di dalam klaster lab tertutup. Skema `public` Pagila dan skema
latihan pertemuan lain (`lab5`, `lab6`, `lab9`) tidak disentuh.

## ⚠️ Batas percobaan

Seluruh percobaan di folder ini — termasuk payload injection pada Langkah 4 — **hanya sah di
dalam kontainer `lab11` milik sendiri, pada jaringan `lab11_labnet` yang bertanda
`internal: true`**. Payload yang dipakai semata membaca (`SELECT`) dan tidak mengubah atau
merusak data penyewa mana pun. Menjalankan hal yang sama di sistem lain — sistem kampus, situs
mana pun, basis data teman — adalah tindak pidana dan tidak dilindungi status mahasiswa.
Pernyataan etika di `laporan.md` wajib ditandatangani seluruh anggota; tanpa itu laporan tidak
dinilai.

## Catatan penting: berkas modul

Soal meminta `docker-compose.lab11.yml`, `sql/lab11_setup.sql`, dan `rentan.py` diambil dari
modul praktikum dan dijalankan apa adanya. Ketiga berkas itu **tidak tersedia bagi kelompok
ini**, sehingga keduanya dibangun ulang dari spesifikasi yang tertulis di soal. Konsekuensinya
perlu dicatat jujur di laporan:

| Hal | Angka yang diminta soal | Angka pada setup kelompok ini |
|---|---|---|
| `tenant` \| `pelanggan` \| `akun` \| `transaksi` | 3 \| 30000 \| 4 \| 120000 | **sama** |
| Baris per penyewa | 10000 | **sama** |
| Jumlah peran | 7 | **sama** |
| Q12 `rentan.py "Pelanggan 12"` | 365 baris | **111 baris** |

Angka 365 berasal dari data modul yang tidak kami miliki. Pada data kami, `nama` berbentuk
`'Pelanggan ' || id` dengan penyewa 1 memegang id 1–10000, sehingga nama yang memuat
`Pelanggan 12` ada 111 buah: `12`, `120`–`129`, dan `1200`–`1299`. Pelajaran Q12–Q13 tidak
bergantung pada angka itu, melainkan pada **perbandingannya** dengan hasil payload, dan
perbandingan itu justru lebih tajam: 111 → 30000 tanpa RLS, 111 → 10000 setelah RLS menyala.

## Prasyarat

- Docker Desktop aktif
- Perintah dijalankan dari akar repositori `msbd-2026`
- Tidak ada Python di host yang diperlukan: `rentan.py` berjalan di dalam `lab11-web`, yang
  sudah memuat `psycopg` sejak tahap build

## Struktur

```text
msbd-2026/
├── lab11/                          klaster lab, tidak ikut dinilai
│   ├── docker-compose.lab11.yml
│   └── web/Dockerfile
└── latihan/p11/                    yang dikumpulkan
    ├── README.md
    ├── laporan.md
    ├── jalankan_semua.sql           penggerak: q00 sampai q11 berurutan
    ├── q00_setup.sql
    ├── q01_hak_pemilik.sql … q29_hapus_dan_sisa.sql
    ├── q30_peta_uu_pdp.md
    └── rentan.py
```

`latihan/p11/` di-mount ke kedua kontainer: sebagai `/lab11` (hanya baca) di `lab11-db`, dan
sebagai `/app` di `lab11-web`. Jadi berkas disunting dari Windows dan langsung terpakai di dalam
kontainer — tidak perlu `docker cp` setiap kali berubah.

## Langkah 1 · Menyalakan klaster dan memuat lab11

```bat
cd c:\msbd-2026\lab11
docker compose -f docker-compose.lab11.yml build
docker compose -f docker-compose.lab11.yml up -d
```

`build` dijalankan lebih dulu dan **memang butuh internet**, karena `psycopg` dipasang pada
tahap itu. Setelah kontainer menyala, jaringannya tertutup dan `pip` tidak punya jalan keluar
lagi — itulah sebabnya pemasangan tidak ditaruh di `command`.

Tunggu sampai basis datanya siap. Pada penyalaan pertama, `initdb` butuh beberapa detik, dan
perintah `psql` yang dijalankan terlalu cepat akan gagal dengan
`connection to server on socket … No such file or directory`:

```bat
docker compose -f docker-compose.lab11.yml exec -T lab11-db bash -c "until pg_isready -U postgres -d msbd -q; do sleep 1; done; echo SIAP"
```

Berkas compose sudah memuat `healthcheck`, jadi `lab11-web` tidak akan menyala sebelum basis
datanya sehat; perintah di atas hanya diperlukan karena `docker compose exec` tidak menunggu
healthcheck.

Lalu muat skema dan jalankan seluruh rangkaian Q1–Q11 dengan **satu** perintah:

```bat
docker compose -f docker-compose.lab11.yml exec -T lab11-db psql -U postgres -d msbd -f /lab11/jalankan_semua.sql > keluaran-p11.txt 2>&1
```

`jalankan_semua.sql` memuat kedua belas berkas berurutan dengan `\ir`, yang mencari berkas
relatif terhadap letak skrip itu sendiri. Satu perintah dipilih dengan sengaja: perulangan `FOR`
di Command Prompt mudah tertelan oleh perintah sebelumnya yang masih berjalan.

Memuat skemanya saja, tanpa percobaan:

```bat
docker compose -f docker-compose.lab11.yml exec -T lab11-db psql -U postgres -d msbd -f /lab11/q00_setup.sql
```

Buktikan jaringannya benar-benar tertutup, lalu salin keluarannya ke laporan:

```bat
docker network inspect lab11_labnet --format "{{.Internal}}"
```

Harus mencetak `true`. Bukti kedua, dari dalam kontainer — tidak ada porta basis data yang
diterbitkan ke host:

```bat
docker compose -f docker-compose.lab11.yml ps
```

Kolom `PORTS` untuk `lab11-db` harus kosong.

### Verifikasi yang disalin ke laporan

`q00_setup.sql` sudah mencetak sendiri seluruh angka verifikasinya di bagian akhir: `version()`,
jumlah baris keempat tabel, jumlah baris per penyewa, tabel tujuh peran beserta kolom
`bisa_login`, kepemilikan keempat tabel, dan pembanding Q12. Seluruh percobaan berikutnya
bersandar pada angka-angka itu.

## Menjalankan rentan.py

```bat
docker compose -f docker-compose.lab11.yml exec lab11-web python rentan.py "Pelanggan 12"
docker compose -f docker-compose.lab11.yml exec lab11-web python rentan.py --aman "zz' OR '1'='1' --"
```

Peran dan penyewa diatur lewat environment, sehingga Q14 hanya berganti peran tanpa menyentuh
satu baris kode:

```bat
docker compose -f docker-compose.lab11.yml exec -e LAB11_USER=app_laporan -e LAB11_PASSWORD=lab11-laporan lab11-web python rentan.py "zz' OR '1'='1' --"
```

Kata sandi keempat peran login hanya berlaku di kontainer lab tertutup ini dan tertulis apa
adanya di `q00_setup.sql`: `app_laporan`/`lab11-laporan`, `app_portal`/`lab11-portal`,
`app_analitik`/`lab11-analitik`, `app_audit`/`lab11-audit`.

## Tujuh peran

| Peran | Login | Boleh apa |
|---|---|---|
| `skema_owner` | tidak | pemilik keempat tabel; DROP dan ALTER melekat padanya |
| `app_read` | tidak | grup penampung hak `SELECT` |
| `app_write` | tidak | grup penampung `INSERT`/`UPDATE`/`DELETE`, anggota `app_read` |
| `app_laporan` | ya | anggota `app_read`; dipakai pelaporan dan uji negatif RLS |
| `app_portal` | ya | anggota `app_write`; dipakai aplikasi portal dan `rentan.py` |
| `app_analitik` | ya | hanya tampilan tersamar (Q23); `SELECT` langsung dicabut |
| `app_audit` | ya | hanya membaca `jejak_audit` (dibuat pada Q25) |

Aplikasi tidak pernah login sebagai `skema_owner`: hak kepemilikan tidak dapat dicabut dengan
`REVOKE` (Q1, Q2), jadi satu-satunya cara membatasinya adalah tidak pernah memegangnya.

## Urutan menjalankan Q1–Q30

Urutannya tidak boleh ditukar; beberapa soal bergantung pada keadaan yang ditinggalkan soal
sebelumnya.

```text
q00_setup
→ Langkah 2  q01 q02 q03 q04 q05          (peran dan kepemilikan)
→ Langkah 3  q06 q07 q08 q09 q10 q11      (RLS; q06 wajib sebelum ada kebijakan)
→ Langkah 4  q12 q13 q14 q15 q16 q17 q18  (injection; sesudah RLS menyala)
→ Langkah 5  q19 q20 q21 q22 q23 q24      (hashing, enkripsi, penyamaran)
→ Langkah 6  q25 q26 q27 q28 q29          (audit, retensi, penghapusan)
→ Langkah 7  q30 + laporan.md             (peta UU PDP dan laporan terpadu)
```

Tiga ketergantungan yang mudah terlewat:

1. **Q6 wajib dijalankan sebelum satu pun kebijakan dibuat.** Begitu Q7 membuat kebijakan,
   keadaan "RLS menyala tanpa kebijakan" tidak bisa diamati lagi tanpa menghapus kebijakannya.
2. **Q12–Q14 dijalankan setelah Langkah 3**, karena bagian "apa yang tetap" pada Q14 adalah
   kebijakan penyewa yang membatasi ledakan payload.
3. **Q23 mencabut `pg_read_all_data` yang diberikan Q9.** Menjalankan Q23 sebelum Q9 membuat
   `REVOKE`-nya tidak bermakna.

## Troubleshooting

| Gejala | Penyebab lazim | Tindakan |
|---|---|---|
| `pip` gagal saat kontainer jalan | Jaringan `labnet` memang tertutup | Pasang paket pada tahap `build`, bukan saat jalan |
| `connection to server on socket … No such file or directory` | `psql` dijalankan sebelum `initdb` selesai | Jalankan dulu perintah `until pg_isready` di bagian Langkah 1 |
| Perintah kedua yang dipaste tidak pernah jalan | Command Prompt menelan masukan selagi perintah sebelumnya berjalan | Pakai `jalankan_semua.sql`, satu perintah untuk seluruh rangkaian |
| Sesudah RLS, semua query 0 baris | Belum ada kebijakan, atau `app.tenant` belum disetel di session itu | `SELECT current_setting('app.tenant', true);` — bila NULL atau kosong, jalankan `SET LOCAL` di dalam transaksi |
| Kebijakan tampak tidak berpengaruh | Session berjalan sebagai pemilik tabel atau superuser | Bandingkan `current_user` dengan `pg_tables.tableowner`, lalu nyalakan `FORCE ROW LEVEL SECURITY` |
| `invalid input syntax for type integer: ""` | `app.tenant` berisi string kosong lalu di-cast | Bungkus `nullif(current_setting('app.tenant', true), '')::int` |
| `REVOKE` jalan tetapi hak masih ada | Hak dari kepemilikan, keanggotaan peran, atau PUBLIC | Periksa berurutan: `pg_tables.tableowner`, `pg_has_role`, hak PUBLIC |
| `generation expression is not immutable` | Kolom tenggat memakai `GENERATED` dengan `timestamptz + interval` | Ganti dengan `DEFAULT now() + interval '72 hours'` |
| `permission denied for sequence jejak_audit_id_seq` | Peran aplikasi menulis `jejak_audit` langsung | Itu memang yang diinginkan; audit hanya ditulis lewat trigger |
| `pgcrypto` tidak ditemukan | Ekstensi belum dibuat di basis data yang dipakai | Sudah dipasang `q00_setup.sql`; ekstensi bersifat per basis data |
| `docker network inspect` tidak menemukan `lab11_labnet` | Compose dijalankan dari folder lain sehingga nama proyeknya berubah | Jalankan dari `c:\msbd-2026\lab11`; berkas compose sudah memaksa `name: lab11` |
