# Laporan Latihan Kelompok Pertemuan 11

Menutup Pintu yang Terbuka — peran berlapis, Row-Level Security, query berparameter, enkripsi,
penyamaran, audit, dan UU PDP, seluruhnya pada skema `lab11`.

## Anggota dan Kontribusi

| Nama | NIM | Kontribusi | Commit |
|---|---|---|---|
| Viter | 251402079 | Langkah 1 (setup, dua kontainer, `q00_setup.sql`, `rentan.py`, `README.md`), Langkah 2 (Q1–Q5, Reflektif A), Langkah 3 (Q6–Q11, Reflektif B) | `2d81d1e` … `90f5472` (19 commit) pada cabang `latihan/p11-keamanan` |
| Finsus | 251402038 | Langkah 4 (Q12–Q18, Reflektif C) | `d472673` … `2d2155d` (2 commit) pada cabang `latihan/p11-keamanan` |
| «nama» | «NIM» | Langkah 5 (Q19–Q24, Reflektif D) | |
| «nama» | «NIM» | Langkah 6 (Q25–Q30, Reflektif E) | |
| «nama» | «NIM» | Langkah 7 (R1: tiga disiplin keamanan, perakitan laporan) | |

## Kondisi Uji

| Hal | Nilai |
|---|---|
| Versi PostgreSQL | PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit |
| Basis data | `msbd`, skema kerja `lab11` |
| Kontainer | `lab11-db` (postgres:17) dan `lab11-web` (python:3.12-slim + psycopg 3.2.3) |
| Jaringan | `lab11_labnet`, `Internal` = **`true`** |
| Porta yang diterbitkan ke host | tidak ada; kolom `PORTS` untuk `lab11-db` kosong |
| Ekstensi | `pgcrypto` (dipasang `q00_setup.sql`, dibutuhkan Langkah 5) |
| Data awal | `tenant` 3 · `pelanggan` 30000 · `akun` 4 · `transaksi` 120000; tiap penyewa 10000 pelanggan |
| Bukti mentah | `keluaran-q01-q11.txt` — 812 baris keluaran psql apa adanya dari satu kali jalan penuh |
| Peran | 7: `skema_owner`, `app_read`, `app_write` (tanpa login); `app_laporan`, `app_portal`, `app_analitik`, `app_audit` (login) |

### Catatan jujur tentang berkas modul

Soal meminta `docker-compose.lab11.yml`, `sql/lab11_setup.sql`, dan `rentan.py` diambil dari
modul praktikum dan dijalankan apa adanya. **Ketiga berkas itu tidak tersedia bagi kelompok
ini**, sehingga dibangun ulang dari spesifikasi yang tertulis di soal. Seluruh angka verifikasi
yang diminta soal tercapai (3 · 30000 · 4 · 120000, tiap penyewa 10000, tujuh peran), dengan
satu perbedaan yang perlu dicatat: pembanding Q12 pada data kami **111 baris, bukan 365**.
Angka 365 berasal dari data modul. Pada data kami `nama` berbentuk `'Pelanggan ' || id` dengan
penyewa 1 memegang id 1–10000, sehingga nama yang memuat `Pelanggan 12` ada 111 buah: `12`,
`120`–`129`, dan `1200`–`1299`. Perbandingan yang menjadi inti Q12–Q13 tidak terpengaruh.

### Catatan tentang huruf ACL pada PostgreSQL 17

PostgreSQL 17 menambahkan hak `MAINTAIN` dengan huruf ACL `m`. Karena itu ACL pemilik pada
kontainer ini berbunyi `skema_owner=arwdDxtm/skema_owner`, satu huruf lebih panjang daripada
pada PostgreSQL 16 (`arwdDxt`). Huruf itu tidak mengubah satu pun kesimpulan Q1–Q4: `DROP` dan
`ALTER` tetap tidak punya huruf, karena keduanya bukan hak yang dapat diberikan.

---

# Langkah 1 · Klaster Tertutup dan Skema lab11

Dijalankan dari `c:\msbd-2026\lab11`. Perintah lengkapnya ada di `latihan/p11/README.md`.
Seluruh keluaran yang dikutip di laporan ini berasal dari satu kali jalan penuh
(`jalankan_semua.sql`), tersimpan apa adanya di `keluaran-q01-q11.txt`: 812 baris, 13 penanda
tahap, dan tepat empat jenis SQLSTATE yang memang diharapkan (`42501` tiga kali, `42601`,
`2BP01`, `22P02`) tanpa satu pun galat lain.

```bat
docker compose -f docker-compose.lab11.yml build
docker compose -f docker-compose.lab11.yml up -d
docker compose -f docker-compose.lab11.yml exec -T lab11-db psql -U postgres -d msbd -f /lab11/q00_setup.sql
docker network inspect lab11_labnet --format "{{.Internal}}"
```

Tahap `build` memang menyentuh internet, karena `psycopg` dipasang di situ. Sesudah kontainer
menyala, jaringannya tertutup dan `pip` tidak punya jalan keluar lagi — itulah sebabnya
pemasangan paket tidak diletakkan di `command`. Bukti ketertutupan ada dua: `Internal` bernilai
`true`, dan tidak ada satu pun `ports:` pada berkas compose sehingga basis data tidak dapat
dijangkau dari host maupun dari jaringan kampus.

### Verifikasi jumlah baris

```text
 tenant | pelanggan | akun | transaksi
--------+-----------+------+-----------
      3 |     30000 |    4 |    120000

 tenant_id | count
-----------+-------
         1 | 10000
         2 | 10000
         3 | 10000
```

Seluruh percobaan Q1–Q30 bersandar pada angka ini. `pelanggan` berisi kolom kuasi-pengenal yang
dipakai Langkah 5 (`nik`, `surel`, `lahir`, `kota`), dan tanggal lahirnya sengaja menggerombol —
enam dari sepuluh pelanggan lahir dalam jendela lima tahun yang sama — supaya Q24 memperoleh
angka identifikasi ulang yang bernuansa, bukan 0% atau 100%.

---

# Langkah 2 · Q1–Q5: Kepemilikan, GRANT, dan Peran Berlapis

## Q1 — Hak biasa dapat dicabut dari pemilik, lalu dikembalikan olehnya sendiri

Berkas: `q01_hak_pemilik.sql`

| Tahap | Perintah | Hasil |
|---|---|---|
| 1 | ACL awal | `skema_owner=arwdDxtm/skema_owner, app_read=r/…, app_write=awd/…, app_analitik=r/…` |
| 2 | `REVOKE UPDATE … FROM skema_owner` | ACL menjadi `skema_owner=ardDxtm/…` — huruf `w` hilang |
| 3 | `has_table_privilege('skema_owner',…,'UPDATE')` | `t` → **`f`** |
| 4 | `SET ROLE skema_owner; UPDATE … WHERE id = 3` | **ERROR `42501`** |
| 5 | `GRANT UPDATE … TO skema_owner` *(dijalankan oleh skema_owner sendiri)* | berhasil |
| 6 | `has_table_privilege(…)` | **`t`** |
| 7 | `UPDATE` yang sama | berhasil, 1 baris |
| 8 | ACL akhir | kembali `skema_owner=arwdDxtm/skema_owner` |

```text
ERROR:  42501: permission denied for table pelanggan
```

**Mengapa pemilik tetap bisa memberikan hak itu kembali.** Perhatikan nama sesudah tanda `/`
pada setiap entri ACL: itu adalah **pemberi** hak. Seluruh hak pada tabel ini diberikan oleh
`skema_owner`, dan pemilik memegang *grant option* atas semua hak di objeknya secara implisit —
tidak dicatat sebagai bintang `*` di ACL, melainkan melekat pada kepemilikan. Jadi `REVOKE`
pada langkah 2 hanya mencoret satu huruf dari daftar; ia tidak menyentuh sumber kewenangannya.
Selama `skema_owner` masih pemilik, ia selalu bisa menuliskan huruf itu kembali, dan tidak ada
superuser yang perlu menolong — langkah 5 dijalankan oleh peran yang baru saja ditolak.

## Q2 — Hak yang melekat pada kepemilikan tidak punya sintaks untuk dicabut

Berkas: `q02_drop_bukan_hak.sql`

```text
ERROR:  42601: unrecognized privilege type "drop"
```

`REVOKE DROP` bahkan tidak sampai ke pemeriksaan hak: PostgreSQL menolaknya sebagai jenis hak
yang tidak dikenal. Daftar hak yang benar-benar dapat diberikan dan dicabut pada sebuah tabel
tertutup dan hanya berisi delapan nama: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`,
`REFERENCES`, `TRIGGER`, dan `MAINTAIN`. `DROP` dan `ALTER` tidak ada di antaranya.

Supaya klaim itu tidak berhenti pada pesan galat, seluruh hak biasa pemilik dicabut lalu
kemampuannya diuji:

| Tahap | Hasil |
|---|---|
| `REVOKE ALL ON lab11.akun FROM skema_owner` | `boleh_select`/`insert`/`update`/`delete` = **`f f f f`** |
| `SELECT count(*) FROM lab11.akun` sebagai `skema_owner` | **ERROR `42501`** |
| `ALTER TABLE lab11.akun ADD COLUMN …` | **berhasil** |
| `DROP TABLE lab11.akun` | **berhasil** (lalu `ROLLBACK`) |
| `akun` sesudah pemulihan | 4 baris, utuh |

**Perbedaan kedua jenis hak.** Hak biasa adalah entri dalam daftar: ia diberikan, dicatat di
`relacl`, dan dapat dicoret. Hak kepemilikan bukan entri — ia adalah jawaban atas pertanyaan
"siapa `relowner` baris ini di `pg_class`". Satu-satunya cara memindahkannya adalah
`ALTER TABLE … OWNER TO`, bukan `REVOKE`. Karena itu sebuah peran dapat kehilangan kemampuan
membaca satu baris sambil tetap berkuasa menghapus seluruh tabelnya — dan itulah yang baru saja
terjadi di tabel di atas.

## Q3 — Default privileges menempel pada peran pembuat, bukan pada skema

Berkas: `q03_default_privileges.sql`

Dua tabel dibuat berurutan, segala hal lain sama, hanya pembuatnya berbeda:

```text
      tabel       |   pemilik   | app_laporan_boleh_select |                relacl
------------------+-------------+--------------------------+--------------------------------------
 catatan_postgres | postgres    | f                        |
 catatan_owner    | skema_owner | t                        | {skema_owner=arwdDxtm/…,app_read=r/…}
```

Kolom `relacl` yang **kosong** pada `catatan_postgres` adalah kuncinya: tabel itu tidak punya
satu pun entri hak, sehingga yang berlaku hanya hak implisit pemiliknya. Tabel buatan
`skema_owner` sebaliknya lahir sudah membawa `app_read=r`, karena `q00_setup.sql` memasang:

```sql
ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner IN SCHEMA lab11
    GRANT SELECT ON TABLES TO app_read;
```

**Perintah yang seharusnya sudah dijalankan untuk peran pembuat.** `ALTER DEFAULT PRIVILEGES`
menyimpan niat **per peran pembuat**, bukan per skema — terlihat di `pg_default_acl`, yang
hanya memuat satu baris untuk `skema_owner`. Jadi untuk `postgres` perintahnya belum pernah ada,
dan harus dijalankan terpisah:

```sql
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11
    GRANT SELECT ON TABLES TO app_read;
```

Dibuktikan di berkasnya: sesudah perintah itu dipasang, tabel ketiga yang dibuat `postgres`
langsung bernilai **`t`** (`{postgres=arwdDxtm/postgres,app_read=r/postgres}`). Pelajaran
operasionalnya: migrasi yang kadang dijalankan sebagai `postgres` dan kadang sebagai
`skema_owner` akan menghasilkan tabel dengan hak yang berbeda-beda tanpa satu pun galat.

## Q4 — GRANT OPTION, dependent privileges, dan CASCADE

Berkas: `q04_grant_option.sql`

| Tahap | ACL `lab11.transaksi` |
|---|---|
| awal | `app_write=awd/skema_owner` |
| `GRANT SELECT … TO app_write WITH GRANT OPTION` | `app_write=a`**`r*`**`wd/skema_owner` |
| `app_write` meneruskan ke `app_analitik` | ditambah `app_analitik=r/`**`app_write`** |
| `REVOKE GRANT OPTION FOR SELECT … FROM app_write` | **ERROR `2BP01`**, ACL tidak berubah |
| `… CASCADE` | `app_write=a`**`rwd`**`/skema_owner`, entri `app_analitik` hilang |

```text
ERROR:  2BP01: dependent privileges exist
HINT:  Use CASCADE to revoke them too.
```

Dua hal yang paling jelas terbaca dari ACL. Pertama, bintang pada `r*` adalah grant option itu
sendiri; sesudah `CASCADE` bintangnya hilang tetapi `r` tetap tinggal, jadi yang dicabut
memang hanya kewenangan meneruskan. Kedua, entri `app_analitik=r/app_write` menyebut
**`app_write`** sebagai pemberi, bukan `skema_owner` — dan justru ketergantungan itulah yang
membuat `REVOKE` tanpa `CASCADE` ditolak: mencabut grant option akan meninggalkan hak yang
pemberinya tidak lagi berwenang memberi.

**Bukti `app_write` tetap bisa membaca:**

```text
 analitik | app_write
----------+-----------
 f        | t
```

Perlu dicatat dari mana nilai `t` itu datang, karena di susunan peran ini `app_write` punya
**dua** sumber: grant langsung pada ACL (`r` yang tersisa) dan warisan keanggotaan `app_read`
yang memegang `SELECT` atas seluruh tabel. Karena itu `has_table_privilege` sendirian bukan
bukti yang sah untuk soal ini, dan ACL harus dibaca langsung. Berkasnya mencetak keduanya.

## Q5 — Tujuh peran pada lab11

Berkas: `q05_tabel_peran.sql` — tabelnya dibangkitkan dari katalog, bukan ditulis tangan, supaya
tidak basi ketika Q9 memberi `pg_read_all_data` dan Q23 mencabutnya.

| Peran | Dapat login | Anggota dari | Boleh apa |
|---|---|---|---|
| `skema_owner` | tidak | — | pemilik keempat tabel; satu-satunya pemegang `DROP` dan `ALTER` |
| `app_read` | tidak | — | `SELECT` pada `tenant`, `pelanggan`, `akun`, `transaksi` |
| `app_write` | tidak | `app_read` | `INSERT`/`UPDATE`/`DELETE` pada `pelanggan` dan `transaksi` |
| `app_laporan` | **ya** | `app_read` | hanya membaca; dipakai pelaporan dan seluruh uji negatif RLS |
| `app_portal` | **ya** | `app_write` | baca dan tulis `pelanggan`/`transaksi`; dipakai `rentan.py` |
| `app_analitik` | **ya** | — | `SELECT` pada `pelanggan`, yang dicabut Q23 dan diganti tampilan tersamar |
| `app_audit` | **ya** | — | belum punya hak apa pun; menerima `SELECT` atas `jejak_audit` pada Q25 |

Hak efektif yang diukur `has_table_privilege` pada keempat peran login:

```text
    peran     | pelanggan_select | pelanggan_update | pelanggan_delete | transaksi_select | akun_select
--------------+------------------+------------------+------------------+------------------+-------------
 app_analitik | t                | f                | f                | f                | f
 app_audit    | f                | f                | f                | f                | f
 app_laporan  | t                | f                | f                | t                | t
 app_portal   | t                | t                | t                | t                | t
```

**Mengapa aplikasi tidak pernah login sebagai pemilik (satu kalimat).** Karena hak `DROP` dan
`ALTER` melekat pada kepemilikan dan tidak dapat dicabut dengan `REVOKE` — dibuktikan pada Q1
dan Q2 — maka satu-satunya cara memastikan sebuah aplikasi tidak bisa menghapus tabelnya adalah
tidak pernah memberinya kepemilikan sejak awal.

## 📝 Reflektif A

> Pada Q1, hak biasa bisa dicabut dari pemilik, tetapi risikonya tetap ada. Jelaskan dari data
> mengapa "mencabut hak" bukan jalan keluar untuk keluhan K1, dan apa yang menjadi jalan
> keluarnya.

*Catatan: isi Tiket #1134 tidak tersedia bagi kelompok ini, sehingga K1 dibaca sesuai letaknya
di soal — keluhan bahwa sebuah akun aplikasi berdaya lebih besar daripada yang dibutuhkan
pekerjaannya. Pemegang Langkah 7 perlu menyesuaikan satu kalimat pembuka ini bila tiket aslinya
berbunyi lain; argumen dan angkanya tidak berubah.*

Mencabut hak gagal menjawab K1 karena dua hal yang terbaca langsung dari data Q1 dan Q2.

**Pertama, pencabutan itu dapat dibatalkan oleh pihak yang dibatasi.** Pada Q1 langkah 5,
perintah `GRANT UPDATE ON lab11.pelanggan TO skema_owner` dijalankan **oleh `skema_owner`
sendiri**, yaitu peran yang satu langkah sebelumnya ditolak dengan `42501`. Tidak ada superuser
yang dilibatkan dan tidak ada persetujuan yang diminta. Sebuah batas yang dapat dihapus
sepihak oleh yang dibatasi bukan batas; ia catatan niat. Sumbernya terbaca di ACL: setiap entri
berbunyi `…/skema_owner`, artinya pemiliknyalah pemberi seluruh hak di tabel itu, dan
kewenangan memberi itu melekat pada `relowner` di `pg_class` — bukan pada daftar yang baru saja
kita coret.

**Kedua, yang paling berbahaya justru tidak ada di daftar yang bisa dicabut.** Q2 menunjukkan
keadaan yang tampak aman tetapi tidak: keempat hak biasa `skema_owner` atas `lab11.akun`
bernilai `f f f f`, `SELECT` pun ditolak dengan `42501` — namun `ALTER TABLE` dan `DROP TABLE`
pada tabel yang sama **tetap berhasil**. Jadi pencabutan hak dapat mencapai keadaan di mana
sebuah peran tidak boleh membaca satu baris pun, sekaligus masih berkuasa menghapus seluruh
tabelnya. Audit yang mengukur risiko dengan membaca `GRANT` akan melaporkan peran itu nyaris
tak berdaya, dan laporan itu salah.

**Jalan keluarnya adalah memisahkan kepemilikan dari pemakaian, bukan memangkas hak di
dalamnya.** Yang dilakukan `q00_setup.sql`: keempat tabel dimiliki `skema_owner` yang
`NOLOGIN`, sehingga tidak ada koneksi yang bisa masuk sebagai peran itu; hak dititipkan pada
dua grup `NOLOGIN` (`app_read`, `app_write`); dan aplikasi login sebagai peran yang hanya
menjadi anggota grup yang sesuai pekerjaannya. Buktinya ada di Q5: `app_portal` memegang
`SELECT`/`UPDATE`/`DELETE` yang ia butuhkan, tetapi tidak pernah muncul sebagai `tableowner`
pada satu baris pun di `pg_tables`, sehingga `DROP` tidak pernah masuk ke jangkauannya — bukan
karena dicabut, melainkan karena tidak pernah ada.

Satu batas kejujuran: susunan ini membatasi **apa yang bisa dilakukan** sebuah peran, belum
**baris mana** yang boleh disentuhnya. `app_portal` masih dapat membaca ketiga penyewa
sekaligus. Itulah yang dikerjakan Langkah 3.

---

# Langkah 3 · Q6–Q11: Row-Level Security Multi-penyewa

## Q6 — Default deny: hak tetap ada, visibilitas nol

Berkas: `q06_default_deny.sql`

| Yang diukur | Hasil |
|---|---|
| Jumlah kebijakan sebelum percobaan | **0** |
| `relrowsecurity` / `relforcerowsecurity` sesudah `ENABLE` | `t` / `f` |
| `has_table_privilege('app_laporan',…,'SELECT')` | **`t`** |
| `count(*)` yang dilihat `app_laporan` | **0** |
| `count(*)` yang sebenarnya ada di tabel | **30000** |

**Mengapa hasilnya justru aman.** Dua baris pertama tabel di atas harus dibaca bersama: hak
`SELECT` milik `app_laporan` **tidak hilang** — nilainya tetap `t` — tetapi baris yang terlihat
nol. RLS tidak bekerja dengan mencabut hak; ia menyaring baris. Ketika RLS menyala dan tidak
ada satu pun kebijakan yang menyebutkan sebuah peran, tidak ada baris yang lolos, karena
kebijakan bersifat *permissive*: baris terlihat bila **ada** kebijakan yang mengizinkannya, dan
tanpa kebijakan tidak ada yang mengizinkan apa pun.

Inilah arah kegagalan yang benar. Bandingkan dengan penyaring `tenant_id` di aplikasi: bila
baris kode itu lupa ditulis, hasilnya seluruh penyewa terbuka. Di sini, bila kebijakan lupa
dibuat, hasilnya nol baris — aplikasi langsung rusak dan ketahuan di menit pertama, bukan
membocorkan diam-diam selama berbulan-bulan. Kegagalan yang berisik lebih murah daripada
kegagalan yang sunyi.

## Q7 — Sepasang kebijakan penyewa, dan sebab `nullif`

Berkas: `q07_kebijakan_penyewa.sql`

Sebelum kebijakan dibuat, sebab pemakaian `nullif` dibuktikan lebih dulu pada `app.tenant` yang
berisi string kosong — keadaan normal sebuah koneksi yang pernah dipakai:

```text
ERROR:  22P02: invalid input syntax for type integer: ""
```

Sedangkan bentuk yang dipakai kebijakan menghasilkan `NULL` tanpa galat. Perbedaannya menentukan
arah kegagalan: `::int` langsung membuat setiap query **melempar galat** begitu koneksi dipakai
ulang, sementara `nullif(…, '')::int` menghasilkan `NULL`, dan `tenant_id = NULL` bernilai tidak
benar sehingga hasilnya **nol baris**. Keduanya "gagal", tetapi hanya yang kedua gagal menolak.

```sql
CREATE POLICY p_tenant_baca ON lab11.pelanggan
  FOR SELECT TO app_read, app_write
  USING (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

CREATE POLICY p_tenant_tulis ON lab11.pelanggan
  FOR ALL TO app_write
  USING      (tenant_id = nullif(current_setting('app.tenant', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant', true), '')::int);
```

Terpasang dua kebijakan, keduanya `PERMISSIVE`, tidak ada yang `RESTRICTIVE`. Fakta itu dicatat
karena ia menjadi dasar celah ketiga pada Q11: menambah kebijakan permissive hanya dapat
**melebarkan** akses, tidak pernah mempersempitnya.

## Q8 — Uji positif dan enam bentuk uji negatif

Berkas: `q08_uji_positif_negatif.sql`

**Uji positif.**

| Peran | `app.tenant` | `count(*)` | Rentang id | Penyewa terlihat |
|---|---|---:|---|---:|
| `app_laporan` | `'1'` | **10000** | 1 – 10000 | 1 |
| `app_laporan` | `'2'` | **10000** | 10001 – 20000 | 1 |

Kebijakan yang sama memberi jendela yang berbeda hanya karena nilai `app.tenant` berubah; tidak
satu baris SQL pun berbeda di antara kedua baris tabel itu.

**Uji negatif.** Satu uji negatif tidak memisahkan kebijakan yang benar dari kebijakan yang
kebetulan mengembalikan nol, jadi dicoba enam bentuk kegagalan yang berbeda:

| # | Bentuk | Hasil |
|---:|---|---:|
| 1 | Penyewa 1 meminta `WHERE tenant_id = 2` | **0** |
| 2 | Penyewa 1 menyebut `id = 15000` milik penyewa 2 | **0** |
| 3 | Penyewa 1 menyebut rentang `id BETWEEN 10001 AND 30000` | **0** |
| 4 | `app.tenant` tidak disetel pada transaksi itu | **0** |
| 5 | `app.tenant` berisi string kosong | **0**, tanpa galat |
| 6 | `app.tenant` menyebut penyewa `99` yang tidak ada | **0** |

Dan jalur tulis, yang tidak disentuh contoh pada soal:

| Operasi sebagai `app_portal`, `app.tenant = '1'` | Hasil |
|---|---|
| `UPDATE … WHERE tenant_id = 2` | **0 baris terdampak** (disaring `USING`) |
| `DELETE … WHERE tenant_id = 2` | **0 baris terdampak** |
| `INSERT` baris dengan `tenant_id = 2` | **ERROR `42501`** |

```text
ERROR:  42501: new row violates row-level security policy for table "pelanggan"
```

Perbedaan arah kegagalan antara ketiganya penting. `UPDATE` dan `DELETE` **tidak** melempar
galat: `USING` membuat baris penyewa lain tidak terlihat, dan perintah yang tidak menemukan baris
adalah perintah yang sukses dengan nol baris. `INSERT` sebaliknya tidak punya baris untuk
disaring, sehingga yang bekerja adalah `WITH CHECK`, dan pelanggarannya berupa galat. Aplikasi
yang menganggap "tidak ada galat" sama dengan "berhasil mengubah" akan salah membaca kedua
kasus pertama.

Sesudah seluruh percobaan, `ROLLBACK` dijalankan dan keadaan diperiksa: total 30000 baris, nol
baris berkota `DIUBAH`, dan ketiga penyewa tetap 10000. Tidak ada data penyewa mana pun yang
berubah.

## Q9 — FORCE, `pg_read_all_data`, dan BYPASSRLS

Berkas: `q09_force_dan_bypass.sql` — satu query yang sama diukur pada empat keadaan.

| Keadaan | Peran | Baris terlihat |
|---|---|---:|
| RLS menyala, `FORCE` belum | `skema_owner` | **30000** |
| Sesudah `FORCE ROW LEVEL SECURITY` | `skema_owner` | **0** |
| `GRANT pg_read_all_data TO app_analitik` | `app_analitik` | **0** |
| `ALTER ROLE app_analitik BYPASSRLS` | `app_analitik` | **30000** (3 penyewa) |

Angka pertama adalah sebabnya `FORCE` wajib: pemilik tabel **tidak terkena** kebijakannya
sendiri sampai `FORCE` dinyalakan. Angka kedua nol dan bukan 10000, karena `p_tenant_baca`
diberikan kepada `app_read` dan `app_write`, dan `skema_owner` bukan anggota keduanya — jadi
yang berlaku adalah default deny dari Q6.

**Apa yang diajarkan `pg_read_all_data`.** Pada keadaan ketiga, `app_analitik` memegang
`has_table_privilege = t` dan `pg_has_role(…,'pg_read_all_data','member') = t`, tetapi
`rolbypassrls = f`, dan baris yang terlihat **nol**. Peran bawaan itu memberi **hak membaca**
semua tabel; ia tidak memberi kekebalan terhadap kebijakan baris. Yang memberi kekebalan adalah
atribut peran `BYPASSRLS`, dan atribut itu tidak muncul di `relacl` tabel mana pun. Akibatnya
praktis: audit keamanan yang bekerja dengan membaca `GRANT` dan ACL tidak akan pernah melihat
`BYPASSRLS`, sehingga `pg_roles.rolbypassrls` harus diperiksa terpisah.

`BYPASSRLS` dicabut kembali di akhir berkas. `pg_read_all_data` **dibiarkan menempel**, karena
Q23 pada Langkah 5 yang akan mencabutnya.

## Q10 — Konteks penyewa yang tertinggal di kolam koneksi

Berkas: `q10_kolam_koneksi.sql`

Satu session psql setara dengan satu koneksi yang dipegang kolam dan dipakai ulang; setiap blok
`BEGIN … COMMIT` di bawah adalah satu permintaan yang kebetulan mendapat koneksi yang sama.

| Permintaan | Yang dilakukan kode | `app.tenant` terbaca | Baris terlihat |
|---|---|---|---:|
| ke-1 | `SET app.tenant = '1'` *(tanpa `LOCAL`)* | `1` | 10000 |
| ke-2 | **tidak menyetel apa pun** | **`1`** | **10000** ← kebocoran |
| ke-3 | `set_config('app.tenant','1', true)` | `1` | 10000 |
| ke-4 | **tidak menyetel apa pun** | `''` | **0** |

Permintaan ke-2 adalah buktinya: kodenya tidak pernah menyebut penyewa, namun ia menerima 10000
baris milik penyewa 1. Bila permintaan itu datang dari pengguna penyewa 2, ia akan menerima data
penyewa lain **tanpa satu pun galat, tanpa satu pun hak yang dilanggar, dan tanpa jejak di
log**. Kebijakan RLS bekerja sempurna sepanjang percobaan; yang salah adalah nilai yang
diberikan aplikasi kepadanya.

Sebabnya sederhana: `SET` tanpa `LOCAL` mengubah setelan **session**, dan session itu hidup lebih
lama daripada permintaan HTTP yang memakainya. Pencegahannya adalah mengikat nilai itu pada
transaksi:

```sql
SET LOCAL app.tenant = '1';                  -- di dalam transaksi
SELECT set_config('app.tenant', '1', true);  -- parameter ketiga = is_local
```

Permintaan ke-4 membuktikan polanya bekerja: nilainya hilang bersama transaksi, tersisa string
kosong, dan `nullif` pada kebijakan mengubahnya menjadi `NULL` sehingga hasilnya menolak.
Bentuk kedua yang dipakai `rentan.py` (lihat fungsi `pasang_penyewa`), karena nilainya boleh
datang dari variabel tanpa perlu merangkai teks SQL.

## Q11 — Tiga cara isolasi ini masih bisa gagal

Berkas: `q11_tiga_celah.sql` — ketiganya dibuktikan, bukan satu, karena ketiga celah berada di
tiga tempat yang berbeda: setelan tabel, atribut peran, dan kode di dalam basis data.

### Celah 1 · Pemilik tabel tidak terkena kebijakan tanpa `FORCE`

| Keadaan | Baris terlihat `skema_owner` |
|---|---:|
| `FORCE` menyala | **0** |
| `NO FORCE` | **30000** (3 penyewa) |

**Perbaikan dalam satu kalimat:** nyalakan `FORCE ROW LEVEL SECURITY` pada setiap tabel
berpenyewa dan jadikan perintah itu bagian dari migrasi, karena `ENABLE` saja meninggalkan
pemiliknya di luar aturan.

### Celah 2 · Atribut `BYPASSRLS` tidak tercatat di ACL mana pun

| Keadaan `app_laporan` | Baris terlihat |
|---|---:|
| `rolbypassrls = f` | **10000** |
| sesudah `ALTER ROLE app_laporan BYPASSRLS` | **30000** |

Dan ACL `lab11.pelanggan` **tidak berubah satu huruf pun** selama percobaan itu. Siapa pun yang
mengaudit dengan membaca `GRANT` tidak akan melihat apa-apa.

**Perbaikan:** audit `rolbypassrls` di `pg_roles` secara berkala sebagai pemeriksaan yang
terpisah dari audit ACL, dan jangan pernah menyematkan atribut itu pada peran aplikasi.

### Celah 3 · Fungsi `SECURITY DEFINER` milik peran istimewa

Satu peran, satu transaksi, satu nilai `app.tenant`:

| Jalur | Baris |
|---|---:|
| `SELECT count(*) FROM lab11.pelanggan` | **10000** |
| `SELECT lab11.rekap_semua()` *(`SECURITY DEFINER`, pemilik `postgres`)* | **30000** |

Kebijakan tidak dilanggar; ia hanya dievaluasi atas nama peran yang salah. Celah ini yang paling
mudah lolos dari tinjauan, karena ia tidak muncul di `pg_policies` maupun di ACL tabel — yang
perlu diperiksa adalah `pg_proc.prosecdef` beserta pemilik fungsinya.

**Perbaikan:** tulis fungsi pembaca sebagai `SECURITY INVOKER`, dan bila `SECURITY DEFINER`
memang diperlukan, pemiliknya harus peran biasa yang tunduk kebijakan — bukan superuser.

> **Catatan untuk pemegang Langkah 5.** Celah 3 langsung menyentuh Q23. Tampilan
> `lab11.v_pelanggan_samar` yang dibuat tanpa `security_invoker` berjalan atas nama
> **pemilik tampilan**. Bila tampilan itu dibuat oleh `postgres`, analis akan melihat ketiga
> penyewa sekaligus — tersamar, tetapi lintas penyewa. Buat tampilan itu sebagai `skema_owner`,
> atau periksa jumlah penyewa yang terlihat di dalamnya sebagai uji negatif tambahan.

Keadaan akhir sesudah ketiga celah ditutup kembali, diperiksa dalam satu query:

```text
 rls_menyala | rls_dipaksa | jumlah_kebijakan | peran_app_dengan_bypassrls | fungsi_security_definer
-------------+-------------+------------------+----------------------------+-------------------------
 t           | t           |                2 |                          0 |                       0
```

## 📝 Reflektif B

> Dengan RLS aktif, apakah penyaring `WHERE tenant_id` di aplikasi masih perlu ditulis?
> Jelaskan tugas berbeda yang diemban keduanya, dengan menyebut rencana eksekusi.

**Masih perlu, tetapi bukan sebagai lapis keamanan kedua.** Rencana eksekusinya yang menjelaskan
mengapa. Query yang sama dijalankan sebagai `app_laporan` dengan `app.tenant = '1'`, sekali
tanpa penyaring aplikasi dan sekali dengan:

Tanpa `WHERE tenant_id`:

```text
Index Scan using pelanggan_tenant_idx on pelanggan (actual rows=499 loops=1)
  Index Cond: (tenant_id = (NULLIF(current_setting('app.tenant'::text, true), ''::text))::integer)
  Filter: (saldo > '9500'::numeric)
  Rows Removed by Filter: 9501
```

Dengan `WHERE tenant_id = 1`:

```text
Result (actual rows=499 loops=1)
  One-Time Filter: ((NULLIF(current_setting('app.tenant'::text, true), ''::text))::integer = 1)
  ->  Index Scan using pelanggan_tenant_idx on pelanggan (actual rows=499 loops=1)
        Index Cond: (tenant_id = 1)
        Filter: (saldo > '9500'::numeric)
        Rows Removed by Filter: 9501
```

Tiga hal terbaca di situ. Pertama, **kebijakan RLS bukan saringan yang ditempel di akhir**: pada
rencana pertama ia menjadi `Index Cond`, jadi perencana memakainya untuk memilih jalur akses,
sama seperti predikat biasa. Kedua, ketika aplikasi menuliskan penyaring yang sama, perencana
**membuktikan keduanya setara** dan menyusutkan kebijakan menjadi `One-Time Filter` — dievaluasi
**sekali**, bukan per baris — sementara `Index Cond` kini berisi konstanta `1`. Ketiga, jumlah
baris keduanya sama persis, 499: penyaring aplikasi tidak menambah dan tidak mengurangi apa pun
dari hasilnya.

Dari situ pembagian tugasnya jelas, dan keduanya **tidak saling menggantikan**:

**RLS mengemban jaminan.** Ia berlaku pada setiap jalur yang menyentuh tabel — psql, `rentan.py`,
skrip migrasi, maupun payload injection pada Langkah 4 — dan tidak bisa lupa ditulis. Q8
membuktikan ia menolak dari enam arah yang berbeda, dan Q6 membuktikan arah kegagalannya menutup
ketika ia belum lengkap. Penyaring aplikasi tidak dapat melakukan satu pun dari itu: ia hanya ada
pada query yang memuatnya.

**Penyaring aplikasi mengemban pernyataan niat, dan dari situ datang dua manfaatnya.** Yang
pertama adalah deteksi. Penyaring itu **tidak dapat melebarkan** akses — dibuktikan dengan
menjalankan `WHERE tenant_id = 2` di dalam konteks penyewa 1, yang menghasilkan **0 baris**,
bukan data penyewa 2. Maka ketika penyewa yang diminta kode berbeda dari penyewa yang terpasang
di koneksi, hasilnya nol baris: ketidakcocokan itu **muncul sebagai hasil kosong, bukan sebagai
data yang salah**. Tepat di situ ia menolong kasus Q10 — permintaan ke-2 yang lupa menyetel
`app.tenant` menerima 10000 baris penyewa 1 dan tidak terlihat salah; bila kodenya menuliskan
`WHERE tenant_id = <penyewa dari permintaan>`, permintaan itu akan mengembalikan nol baris dan
bug-nya ketahuan. Yang kedua adalah rencana eksekusi: `Index Cond: (tenant_id = 1)` dengan
konstanta memberi perencana angka selektivitas yang sesungguhnya, sedangkan
`current_setting()` adalah fungsi yang nilainya baru diketahui saat jalan.

Satu pagar yang harus ikut disebut supaya kesimpulan ini tidak dipakai berlebihan: penyaring
aplikasi **bukan** pengganti RLS, dan ia juga tidak menolong terhadap ketiga celah Q11. Pada
celah 3, fungsi `SECURITY DEFINER` mengembalikan 30000 baris; menambahkan `WHERE tenant_id = 1`
di dalam fungsi itu tidak akan menutup apa pun, karena yang bocor adalah identitas yang dipakai
mengevaluasi kebijakan, bukan predikatnya.

---

# Langkah 4 · Q12–Q18: Menutup Celah Injection

«Diisi pemegang Langkah 4. `rentan.py` dan kedua kontainer sudah siap; lihat `README.md` bagian
"Menjalankan rentan.py". Pembanding Q12 pada data kami **111 baris**, bukan 365 — alasannya di
bagian Kondisi Uji. Perlu dicatat juga bahwa payload dengan `--` mengembalikan 30000 baris bila
RLS belum menyala dan 10000 bila sudah; jalankan Langkah 3 lebih dulu agar angka Q14 bermakna.»

## Q12
Berkas: `q12_perilaku_normal.sql`, `rentan.py`.

```text
$ python rentan.py "Pelanggan 12"
[SQL TERCETAK] SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%Pelanggan 12%'
[JUMLAH BARIS] 365
```
Bagian yang berasal dari masukan pengguna adalah string Pelanggan 12 yang disisipkan langsung
ke dalam pola pencarian '%Pelanggan 12%' melalui interpolasi string Python (f"... '%{kata}%'").
Pada kondisi normal, masukan pengguna hanya berisi karakter alfanumerik biasa sehingga struktur
klausa WHERE tetap sesuai rancangan pemrogram dan mengembalikan 365 baris milik penyewa 1.
## Q13
Berkas: `q13_sebab_bukan_kutip.sql`.

| Payload masukan (`kata`) | Kalimat SQL yang dieksekusi PostgreSQL | Jumlah baris |
|---|---|---:|
| `zz' OR '1'='1` | `... WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1%'` | **0** |
| `zz' OR '1'='1' --` | `... WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'` | **30000** |

**Mengapa yang pertama menghasilkan 0 baris.** Tanpa komentar penutup, tanda kutip tunggal dan
tanda persen bawaan kode (%') menempel langsung di ujung payload. Akibatnya, predikat kedua
terbaca sebagai '1'='1%' — membandingkan string '1' dengan string dua karakter '1%' —
yang bernilai FALSE. Karena nama ILIKE '%zz' juga FALSE, seluruh klausa WHERE bernilai
salah dan mengembalikan nol baris.

**Mengapa yang kedua membocorkan seluruh 30.000 baris.** Penambahan -- mengubah sisa kutip
dan persen bawaan kode (%') menjadi komentar yang diabaikan parser, sehingga perbandingan
'1'='1' menjadi valid dan bernilai TRUE. Selanjutnya, karena operator AND di PostgreSQL
memiliki prioritas (operator precedence) lebih tinggi daripada OR, basis data mengevaluasi
kalimat tersebut sebagai:

```sql
WHERE (tenant_id = 1 AND nama ILIKE '%zz') OR ('1'='1')
```
Karena koneksi awal rentan.py berjalan melewati RLS dan cabang kanan OR selalu TRUE,
seluruh 30.000 baris dari ketiga penyewa ikut terbaca. Inti pelajarannya bukan pada
karakter kutipnya — melainkan fakta bahwa masukan pengguna ikut menyusun tata bahasa SQL,
sehingga data berubah menjadi instruksi logika.
## Q14
Berkas: `q14_batas_hak.sql`.

| Yang diamati | Koneksi awal (melewati RLS) | Koneksi `app_laporan` (`app_read` + RLS) | Status |
|---|---:|---:|---|
| Baris terbaca dari payload Q13 | **30000** (3 penyewa) | **10000** (hanya penyewa 1) | **Berubah** |
| Baris penyewa 2 dan 3 yang bocor | **20000** | **0** | **Berubah** |
| Percobaan `UPDATE` lewat celah yang sama | Dapat berjalan | **ERROR `42501`** (*permission denied*) | **Berubah** |
| Keberhasilan injeksi di dalam penyewa 1 | Berhasil | **Tetap berhasil** (seluruh 10000 baris terbaca) | **Tetap** |

```text
ERROR:  42501: permission denied for table pelanggan
```
**Kaitan dengan prinsip hak minimum per tabel**. Menerapkan peran app_laporan dengan hak
baca saja (app_read) dan mengikatnya ke kebijakan RLS mempersempit radius ledakan (blast
radius) secara drastis: kebocoran lintas penyewa turun dari 30.000 menjadi nol baris, dan
jalur modifikasi data tertutup rapat dengan SQLSTATE 42501.

Namun tabel di atas juga menunjukkan batas dari kontrol akses: yang tetap adalah kerentanan
injeksinya sendiri. RLS dan hak tabel bekerja setelah kalimat SQL diparsing; keduanya tidak
menghentikan masukan pengguna memanipulasi predikat WHERE, sehingga penyerang tetap bisa
menyedot seluruh 10.000 baris milik penyewa 1 sekaligus.
## Q15
Berkas: `q15_perbaikan.sql`.

| Pengujian pada `cari_aman` | Perlakuan PostgreSQL | Hasil |
|---|---|---|
| Payload `zz' OR '1'='1' --` | Dikirim lewat saluran parameter (`$1`), diperlakukan sebagai teks literal | **0 baris**, tanpa galat sintaks |
| Masukan sah berisi kutip, misal `O'Connor` | Dikirim lewat saluran parameter (`$1`), tanda kutip tetap utuh | Berjalan normal sebagai pencarian teks |
| Penyaringan karakter (*blacklist* `replace("'", "")`) | Mengubah masukan sebelum digabung ke string SQL | **Rapuh**: gagal di konteks angka/pengenal dan merusak data sah |

Ketika payload Q13 dikirim lewat cari_aman, PostgreSQL memisahkan fase penyusunan pohon sintaks
(Parse) dengan fase pengikatan nilai (Bind) melalui protokol biner/parameter yang terpisah.
Seluruh string %zz' OR '1'='1' --% dikirim lewat saluran data dan diperlakukan murni sebagai
nilai literal untuk dicocokkan oleh ILIKE, tidak pernah sebagai token sintaks SQL.

**Mengapa penyaringan karakter tidak akan mencapai hasil yang sama.** Pendekatan blacklist
atau penghapusan karakter (misalnya kata.replace("'", "")) gagal menutup akar masalah karena
tiga alasan:

Tidak berlaku di luar konteks string: injeksi pada kolom angka (WHERE id = <input>)
atau pengenal (ORDER BY <input>) tidak memerlukan tanda kutip tunggal sama sekali.

Merusak data yang sah: menghapus atau mengubah tanda kutip merusak nama asli pengguna
seperti O'Connor atau Ma'ruf.

Tetap mencampurkan kode dan data: satu variasi encoding atau celah pada fungsi sanitasi
langsung mengembalikan kemampuan masukan mengubah struktur SQL.
## Q16
Berkas: `q16_pengenal_daftar_putih.sql`.

Tidak semua bagian kalimat SQL dapat diparameterkan. Nama kolom pada ORDER BY dan kata kunci
arah pengurutan (ASC/DESC) tidak bisa memakai %s atau $1, karena bind parameter di
PostgreSQL hanya mewakili nilai literal data — bukan pengenal (identifier) atau kata kunci
sintaks.
| Masukan `(kolom, arah)` | Status pada daftar putih | Hasil eksekusi |
|---|---|---|
| `('nama', 'naik')` | Terdaftar (`nama` → `nama`, `naik` → `ASC`) | Berhasil mengembalikan 5 baris terurut menaik |
| `('kota', 'turun')` | Terdaftar (`kota` → `kota`, `turun` → `DESC`) | Berhasil mengembalikan 5 baris terurut menurun |
| `('nama; SELECT 1--', 'naik')` | Tidak terdaftar | Ditolak sebelum eksekusi (`ValueError` / **`ERROR 22023`**) |
| `('nama', 'ASC; DROP TABLE--')` | Tidak terdaftar | Ditolak sebelum eksekusi (`ValueError` / **`ERROR 22023`**) |

```text
ERROR:  22023: parameter pengurutan tidak dikenal: kolom=nama; SELECT 1--, arah=naik
```
Dengan memetakan kunci masukan ke nilai konstan di dalam kamus tertutup (KOLOM dan ARAH),
string yang dirangkai ke dalam query berasal 100% dari konstanta milik aplikasi sendiri, bukan
dari input pengguna.
## Q17
Berkas: `q17_second_order.sql`.

Satu baris uji dengan nilai kota berisi payload Medan' UNION SELECT surel, 1 FROM lab11.pelanggan WHERE id <= 3 --
disimpan ke dalam lab11.pelanggan melalui jalur INSERT berparameter yang aman, lalu
dibaca kembali oleh dua fungsi laporan:
| Fungsi yang dipanggil | Cara menyusun query di dalam fungsi | Hasil eksekusi |
|---|---|---|
| `lab11.laporan_kota_rentan` | Penggabungan string (`'... WHERE kota = ''' \|\| p_kota \|\| ''''`) | **3 baris surel pelanggan bocor** (`UNION SELECT` tereksekusi) |
| `lab11.laporan_kota_aman` | Eksekusi berparameter (`EXECUTE '... WHERE kota = $1' USING p_kota`) | **1 baris literal** (payload diperlakukan sebagai nama kota biasa) |

**Mengapa pertahanan di pintu masuk tidak menolong.** Pada saat INSERT, query berparameter berhasil mencegah injeksi dan menyimpan string payload tersebut secara utuh ke kolom kota. Namun, pertahanan di pintu masuk hanya mengamankan langkah penulisan pertama. Begitu tersimpan di tabel, data itu sering kali diasumsikan bersih oleh prosedur internal lain. Ketika laporan_kota_rentan membaca nilai kolom kota dan menggabungkannya ulang menjadi teks SQL tanpa USING atau format('%L'), muatan berbahaya yang semula pasif berubah menjadi perintah SQL aktif pada eksekusi tahap kedua (second-order injection). Setiap batas query dinamis — termasuk di dalam fungsi PL/pgSQL — wajib memparameterkan nilainya sendiri.

## Q18
Berkas: `q18_batas_waktu.sql`.

```sql
ALTER ROLE app_portal SET statement_timeout = '5s';
```

| Perintah / Skenario uji | Konfigurasi `statement_timeout` pada `app_portal` | Hasil eksekusi | SQLSTATE & Jejak Log |
|---|---|---|---:|
| Kueri normal (`SELECT ... LIMIT 100`) | `5s` | Selesai dalam hitungan milidetik | Normal (tidak tercatat galat) |
| Percobaan penundaan (`SELECT pg_sleep(6)`) | Tanpa batas (`0` / bawaan) | Selesai setelah 6 detik tanpa galat | Senyap (tidak ada galat di log) |
| Percobaan penundaan (`SELECT pg_sleep(6)`) | `5s` (`ALTER ROLE app_portal SET statement_timeout = '5s'`) | Dibatalkan paksa tepat pada detik ke-5 | **`57014`** (`ERROR: canceling statement due to statement timeout`) |

```text
ERROR:  57014: canceling statement due to statement timeout
```
**Bagaimana batas waktu membuat percobaan berbasis pg_sleep menjadi berisik di log.** Pada serangan time-based blind SQL injection, penyerang menyisipkan fungsi penunda seperti pg_sleep(10) di balik percabangan kondisional untuk menyimpulkan isi basis data dari jeda waktu respons HTTP — tanpa memunculkan pesan galat di layar aplikasi. Ketika statement_timeout dipasang pada peran aplikasi (5s), setiap kueri yang melampaui ambang waktu tersebut langsung diputus oleh PostgreSQL dan dicatat ke log server sebagai ERROR: 57014. Lonjakan entri 57014 di log mengubah serangan yang semula senyap dan tak terlihat menjadi sangat berisik dan mudah dideteksi oleh sistem pemantauan (monitoring/IDS), sekaligus mencegah habisnya connection pool akibat kueri yang menggantung.


## 📝 Reflektif C

**Satu-satunya lapis yang menghapus sebab masalah adalah Query Berparameter dan Daftar Putih
Tertutup (Q15–Q16).** Akar penyebab SQL injection adalah bercampurnya data masukan pengguna ke
dalam struktur tata bahasa SQL sebelum diparsing. Query berparameter memisahkan saluran data
(*Bind*) dari struktur perintah (*Parse*) pada level protokol basis data, sedangkan daftar
putih tertutup memastikan pengenal sintaks hanya berasal dari konstanta aplikasi. Dengan
keduanya, masukan pengguna tidak pernah memiliki kesempatan untuk ditafsirkan sebagai kode[cite: 15, 16].

Tiga lapis lainnya tidak menghapus kerentanan injeksi di dalam kode, melainkan bekerja sebagai
**pengaman kedalaman (*defense-in-depth*)** yang membatasi dampak dan mempercepat deteksi[cite: 15, 16]:

| Lapis Pertahanan | Menghapus Akar Masalah? | Peran Utama & Bukti Eksperimen |
|---|:---:|---|
| **Query Berparameter & Daftar Putih (Q15–Q16)** | **Ya** | Memisahkan data dari kode SQL sehingga injeksi gagal dieksekusi |
| **Hak Minimum & RLS (Q14)** | Tidak | Membatasi *blast radius* kebocoran dari **30.000** menjadi **10.000 baris** (hanya penyewa 1) dan memblokir tulis (`42501`) |
| **Batas Waktu / `statement_timeout` (Q18)** | Tidak | Memutus serangan penundaan (`pg_sleep`) pada detik ke-5 (**`SQLSTATE 57014`**) dan memunculkan jejak berisik di log |
| **Penyaringan Input / Pintu Masuk (Q13 & Q17)** | Tidak | Rapuh terhadap perubahan konteks sintaks dan gagal menahan *second-order injection* saat data dibaca ulang dari tabel[cite: 15, 16] |

1. **Prinsip Hak Minimum dan Row-Level Security (bukti dari Q14):** Tidak mencegah kalimat
   injeksi dieksekusi di dalam satu penyewa, tetapi membatasi *blast radius* kerusakan. Pada Q14,
   peran `app_laporan` yang tunduk pada RLS menahan kebocoran dari **30.000 baris** lintas
   penyewa menjadi **10.000 baris** milik penyewa 1 saja, sekaligus menolak seluruh upaya tulis
   dengan **`SQLSTATE 42501`**[cite: 15].
2. **Batas Waktu Eksekusi / `statement_timeout` (bukti dari Q18):** Tidak mencegah kueri injeksi
   yang selesai di bawah 5 detik, tetapi menggagalkan eksploitasi penundaan waktu (`pg_sleep`)
   dan kelelahan koneksi dengan memutus kueri pada detik ke-5 melalui **`SQLSTATE 57014`**,
   sehingga serangan senyap berubah menjadi berisik di log server[cite: 16].
3. **Pertahanan di Pintu Masuk / Validasi Awal (bukti dari Q13 dan Q17):** Hanya menyaring
   masukan pada titik masuk pertama (`INSERT`), tetapi terbukti tidak berdaya ketika struktur
   sintaks berubah atau ketika prosedur hilir di dalam basis data masih merangkai string SQL
   secara dinamis dari kolom tabel (*second-order injection*)[cite: 15, 16].

---

# Langkah 5 · Q19–Q24: Enkripsi, Hashing, dan Penyamaran

«Diisi pemegang Langkah 5. `pgcrypto` sudah terpasang `q00_setup.sql`. Dua catatan: Q23 harus
mencabut `pg_read_all_data` yang diberikan Q9 (sengaja dibiarkan menempel), dan lihat peringatan
pada Q11 celah 3 soal pemilik tampilan tersamar.»

## Q19
## Q20
## Q21
## Q22
## Q23
## Q24

## 📝 Reflektif D

---

# Langkah 6 · Q25–Q30: Audit, Retensi, dan UU PDP

«Diisi pemegang Langkah 6. `app_audit` sengaja dibiarkan tanpa hak apa pun di `q00_setup.sql`;
Q25 yang memberinya `SELECT` atas `jejak_audit`. Catatan soal berlaku: pakai `session_user`
bukan `current_user`, dan `DEFAULT now() + interval '72 hours'` bukan `GENERATED`.»

## Q25
## Q26
## Q27
## Q28
## Q29
## Q30

## 📝 Reflektif E

---

# Langkah 7 · R1: Tiga Disiplin Keamanan

«Diisi pemegang Langkah 7.»

---

## Peta Tiket #1134 ke UU PDP

«Diisi pemegang Langkah 6/7. **Isi Tiket #1134 belum dimiliki kelompok ini** — kelima keluhannya
perlu diminta dari pengajar atau modul sebelum tabel ini dapat diisi dengan benar. Reflektif A
di atas memakai pembacaan sementara atas K1 dan sudah ditandai.»

| Keluhan | Pasal relevan | Kontrol teknis pencegah | Bukti |
|---|---|---|---|

## Pernyataan Etika

Seluruh percobaan pada latihan ini — termasuk payload injection pada Langkah 4 — hanya
dijalankan pada kontainer `lab11` milik sendiri, pada jaringan `lab11_labnet` yang terbukti
tertutup (`Internal = true`, tanpa porta yang diterbitkan ke host). Seluruh payload bersifat
membaca (`SELECT`) dan tidak mengubah maupun merusak data penyewa mana pun; percobaan tulis pada
Q8 dijalankan di dalam transaksi dan di-`ROLLBACK`, lalu keadaan data diperiksa ulang. Tidak ada
percobaan yang dijalankan terhadap sistem kampus, situs mana pun, atau basis data orang lain.

| Nama | Tanda tangan | Tanggal |
|---|---|---|
| Viter | | |
| «nama» | | |
| «nama» | | |
| «nama» | | |
| «nama» | | |

## Penggunaan AI dan Verifikasi

| Anggota | Bagian | Pemakaian AI | Cara verifikasi |
|---|---|---|---|
| Viter | Langkah 1, 2, 3 (Q1–Q11, Reflektif A dan B) | Claude (Opus 5) dipakai menyusun berkas compose, `q00_setup.sql`, `rentan.py`, kesebelas berkas SQL, dan draf penjelasan | Seluruh berkas dijalankan sendiri pada kontainer `lab11-db`; setiap angka pada tabel di atas dicocokkan dengan keluaran psql, termasuk keenam uji negatif Q8 yang harus nol dan ketiga celah Q11 yang dibuktikan dengan toggle. SQLSTATE `42501`, `42601`, `2BP01`, `22P02` dikutip apa adanya dari keluaran. Perilaku `pg_read_all_data` lawan `BYPASSRLS` dan rencana eksekusi `One-Time Filter` diperiksa ulang terhadap dokumentasi resmi PostgreSQL bab *Row Security Policies* dan *Privileges*. Perbedaan huruf ACL `m` pada PostgreSQL 17 diperiksa terhadap catatan rilis versi 17 |
| «nama» | Langkah 4 | «isi sendiri» | «isi sendiri» |
| «nama» | Langkah 5 | «isi sendiri» | «isi sendiri» |
| «nama» | Langkah 6 | «isi sendiri» | «isi sendiri» |
| «nama» | Langkah 7 | «isi sendiri» | «isi sendiri» |
