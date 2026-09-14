# Laporan Latihan Kelompok Pertemuan 4

**SQL Lanjutan II: Audit Log, Materialized View, dan Migrasi Aman**

| | |
|---|---|
| Mata kuliah | TIF2104 — Manajemen Sistem Basis Data |
| Pertemuan | 4 — SQL Lanjutan II |
| Basis data | Pagila pada PostgreSQL 17, skema kerja `lab4` |
| Cabang | `latihan/p04-sql2` |
| Repositori | https://github.com/vitermoldy/msbd-2026 |
| Merge request | «tempel tautan MR di sini» |
| Versi PostgreSQL | «tempel keluaran SELECT version()» |
| Tanggal pengerjaan | «tanggal» |

> **Status laporan.** Dokumen ini terisi sampai Langkah 3 (Q0–Q8, Refleksi A dan B).
> Bagian Q9–Q21, Refleksi C–E, serta baris Q12 dan Q13 pada tabel waktu masih menunggu
> pengerjaan. Setiap tanda «…» adalah tempat yang harus diisi dengan keluaran asli dari
> terminal kelompok — jangan diisi dengan perkiraan.

---

## 1. Identitas Kelompok dan Kontribusi

| Nama | NIM | Kontribusi Pertemuan 4 | Commit |
|---|---|---|---|
| Viter Moldy Kesuma | 251402079 | Langkah 1–3 dan `README.md` — `q00_setup.sql`, Q1–Q8, Refleksi A dan B | [`308b093`](https://github.com/vitermoldy/msbd-2026/commit/308b0936db3429b222c934b6b631bd8e264b71c1) · [`739a6cf`](https://github.com/vitermoldy/msbd-2026/commit/739a6cfc12e8e4b4f76b69ba30ca684184057bdf) · [`25203ba`](https://github.com/vitermoldy/msbd-2026/commit/25203bae9a6c7571c321fce057d2e59a7bdc6f07) |
| Siti Naifah Batubara | 251402067 | Langkah 4 — trigger audit Q9–Q13, Refleksi C | «tautan commit» |
| Nadine Tantiara Hutagaol | 251402050 | Langkah 5 — constraint Q14–Q17, Refleksi D | «tautan commit» |
| Gideon Finsus Siburian | 251402038 | Langkah 6 — expand–contract Q18–Q21, Refleksi E, enam pasang migrasi pada `migrations/` | «tautan commit» |
| Rizky Cristian Fero Sihombing | 251402056 | Langkah 7 — penyusunan `laporan.md` terpadu, penggabungan bukti dan tabel waktu | «tautan commit» |

Tiga commit pada baris pertama sudah benar-benar ada di cabang `latihan/p04-sql2`; sisanya
menyusul seiring langkah berikutnya dikerjakan.

Pemeriksaan silang mengikuti cincin tertutup yang sama seperti Pertemuan 3.

---

## 2. Jawaban Q1–Q21

Seluruh berkas jawaban berada di `latihan/p04/` dan dijalankan dari akar repositori
melalui Command Prompt dengan pola:

```bat
docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 -f /dev/stdin < latihan\p04\<berkas>.sql
```

Khusus `q03`, `q04`, `q06`, dan `q07`, opsi `-v ON_ERROR_STOP=1` **tidak** dipakai, karena
keempat berkas itu memang dirancang menghasilkan galat di tengah berkas dan sisa
pernyataannya masih harus dijalankan.

### Q0 — `q00_setup.sql` · Menyiapkan lingkungan lab

**Perintah**

```bat
docker compose up -d
docker compose ps
docker compose exec -T postgres psql -U msbd -d pagila -v ON_ERROR_STOP=1 -f /dev/stdin < latihan\p04\q00_setup.sql
```

**Keluaran**

```text
«tempel keluaran: CREATE SCHEMA, SET, CREATE TABLE AS, ALTER TABLE, INSERT 0 500000,
 ANALYZE, dan hasil SELECT count(*) yang harus bernilai 500000»
```

Verifikasi:

```text
lab4.jejak_akses = «500000»
lab4.film        = «1000»
```

**Alasan keputusan.** Seluruh percobaan ditempatkan pada skema `lab4`, bukan `public`.
Latihan ini memasang trigger, menambah dan menghapus kolom, serta memasang constraint pada
tabel `film` — semuanya merusak bila dikenakan pada data Pagila asli. Skema `lab4` juga
menjaga tabel bantu Pertemuan 3 (`pegawai` dan `notifikasi`) yang masih hidup di skema
`public` pada basis data yang sama. `CREATE TABLE AS TABLE public.film` menyalin tipe kolom
tetapi tidak menyalin default, `NOT NULL`, foreign key, maupun index; karena itu primary key
ditambahkan manual, dan sifat "polos" inilah yang membuat penyisipan uji pada Q2 cukup
mengisi beberapa kolom saja.

Alternatif yang tidak dipakai: bekerja langsung di `public`. Ditolak karena kerusakannya
permanen dan menular ke pertemuan lain.

---

### Q1 — `q01_view_film_murah.sql` · View tanpa check option

**Perintah**

```sql
CREATE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99;
```

**Keluaran**

```text
jumlah_film_murah = «…»

«lima baris pertama view»

table_name  | is_insertable_into | is_updatable
film_murah  | «YES»              | «YES»
```

**Alasan keputusan.** View dibuat tanpa `WITH CHECK OPTION` **dengan sengaja**, karena Q2
menuntut bukti apa yang terjadi ketika aturan view tidak ditegakkan. Kolom yang dipilih
hanya empat sesuai permintaan soal, dan predikatnya satu baris sederhana di atas satu tabel
dasar — bentuk inilah yang membuat PostgreSQL menggolongkannya auto-updatable, terbukti dari
`is_updatable = YES` pada `information_schema.views`. Nilai itu yang menjelaskan mengapa
`INSERT` pada Q2 dapat berhasil tanpa trigger apa pun.

Alternatif yang tidak dipakai: langsung memasang `WITH CHECK OPTION`. Ditolak karena akan
menghapus bahan bukti untuk Q2.

---

### Q2 — `q02_baris_menghilang.sql` · Baris yang menghilang

**Perintah**

```sql
INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9001, 'FILM UJI SELISIH', 4.99, 'PG');
```

**Keluaran**

```text
INSERT 0 1
```

| sumber | jumlah |
|---|---:|
| view | «0» |
| tabel | «1» |

**Penjelasan selisih.** PostgreSQL menerima `INSERT` karena view ini auto-updatable: satu
tabel dasar, tanpa agregasi, tanpa `DISTINCT`, tanpa join. Perintah diterjemahkan menjadi
`INSERT` ke `lab4.film`, barisnya benar-benar tersimpan, dan psql melaporkan `INSERT 0 1`.
Namun predikat view adalah `rental_rate <= 0.99` sedangkan baris yang masuk bernilai `4.99`.
Tanpa `WITH CHECK OPTION`, PostgreSQL tidak memeriksa apakah baris baru masih terlihat lewat
view yang dipakai menulis.

Akibatnya aplikasi merasa berhasil menyimpan, lalu tidak dapat menemukan datanya lagi lewat
jalur yang sama. Data tidak hilang — data itu hanya tidak terlihat dari jendela yang dipakai
menulis. Kegagalan seperti ini berbahaya justru karena senyap: tidak ada galat, tidak ada
peringatan, dan baru ketahuan dari keluhan pengguna.

**Alasan keputusan.** `film_id` diisi sendiri (9001) agar baris uji mudah ditemukan kembali
dan mudah dibersihkan tanpa mengganggu 1000 film asli. Alternatif yang tidak dipakai:
menyisipkan lewat tabel dasar lalu membandingkan — ditolak karena tidak membuktikan apa pun
tentang perilaku view.

---

### Q3 — `q03_check_option.sql` · WITH CASCADED CHECK OPTION

**Perintah**

```sql
CREATE OR REPLACE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99
WITH CASCADED CHECK OPTION;

INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9001, 'FILM UJI SELISIH', 4.99, 'PG');   -- harus gagal

INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9002, 'FILM UJI LOLOS', 0.99, 'PG');     -- harus berhasil
```

**Keluaran** — pesan galat utuh ada di bagian 3 laporan ini.

Penyisipan kedua berhasil (`INSERT 0 1`), dan `SELECT` penutup memperlihatkan hanya
`film_id = 9002` yang ada di view.

**Alasan keputusan.** Dipilih `CASCADED`, bukan `LOCAL`. Keduanya sama-sama memeriksa
predikat view ini sendiri, tetapi `CASCADED` juga memeriksa predikat seluruh rantai view di
bawahnya. Bila kelak ada view lain dibangun di atas `film_murah`, `LOCAL` akan meninggalkan
celah yang persis sama seperti yang dibuktikan Q2 — hanya berpindah satu lapisan ke bawah.
`CASCADED` menutup celah itu sekaligus.

Perlu dicatat: sejak berkas ini dijalankan, `film_murah` selamanya ber-check option. Untuk
mengulang bukti Q2, view harus dikembalikan dulu ke bentuk tanpa check option.

---

### Q4 — `q04_view_pendapatan_kategori.sql` · View beragregasi tidak auto-updatable

**Perintah**

```sql
CREATE VIEW lab4.pendapatan_kategori AS
SELECT c.name AS kategori, count(*) AS jumlah_film,
       round(avg(f.rental_rate), 2) AS rata_tarif,
       sum(f.rental_rate) AS total_tarif
FROM lab4.film f
JOIN public.film_category fc ON fc.film_id = f.film_id
JOIN public.category      c  ON c.category_id = fc.category_id
GROUP BY c.name;

INSERT INTO lab4.pendapatan_kategori (kategori, jumlah_film, rata_tarif, total_tarif)
VALUES ('Kategori Uji', 1, 1.00, 1.00);   -- harus gagal
```

**Keluaran**

```text
«lima baris teratas view, diurutkan menurut total_tarif»

table_name           | is_insertable_into | is_updatable
pendapatan_kategori  | «NO»               | «NO»
```

```text
ERROR:  cannot insert into view "pendapatan_kategori"
DETAIL:  Views containing GROUP BY are not automatically updatable.
HINT:  To enable inserting into the view, provide an INSTEAD OF INSERT trigger or an unconditional ON INSERT DO INSTEAD rule.
```

**Mengapa tidak auto-updatable.** Sebuah view hanya auto-updatable bila PostgreSQL dapat
memetakan satu baris view ke tepat satu baris pada satu tabel dasar. View ini melanggar
syarat itu dua kali sekaligus.

Pertama, ada `GROUP BY` beserta fungsi agregat: satu baris hasil mewakili banyak baris
sumber, dan tidak ada cara membalik `sum()` atau `avg()` menjadi nilai per baris. Kedua, ada
join tiga tabel: bahkan seandainya tidak ada agregasi, tetap tidak jelas ke tabel mana baris
baru harus ditulis — `lab4.film`, `film_category`, atau `category`.

Baris `HINT` menunjukkan jalan keluarnya: aturan penulisan harus ditulis sendiri lewat
trigger `INSTEAD OF`. Artinya keputusan itu dipindahkan dari mesin ke pengembang, dan
konsekuensinya menjadi tanggung jawab manusia.

**Alasan keputusan.** Dipilih bentuk agregasi per kategori dengan join karena realistis
sebagai view laporan sekaligus melanggar dua syarat sekaligus. Alternatif yang tidak dipakai:
view ber-`DISTINCT` saja — ditolak karena hanya menunjukkan satu sebab dan tidak menyerupai
view laporan yang benar-benar dipakai tim.

---

### Q5 — `q05_query_dasar_akses.sql` · Garis dasar agregasi

**Perintah**

```sql
\timing on
SELECT date_trunc('month', a.waktu) AS bulan, a.kanal,
       count(*) AS jumlah_akses, count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2;
```

**Keluaran**

```text
«jumlah baris hasil: sekitar 13 bulan x 4 kanal»

Pengukuran 1: «… ms»
Pengukuran 2: «… ms»
Pengukuran 3: «… ms»
```

**Alasan keputusan.** Query dijalankan apa adanya dengan `\timing on` sebagai garis dasar,
dan diulang tiga kali karena eksekusi pertama masih terganggu cache dingin. Angka yang
dipakai adalah `Time: … ms` dari psql, bukan angka dari `EXPLAIN ANALYZE` — `EXPLAIN` tidak
memasukkan waktu pengiriman hasil, sehingga tidak sebanding dengan waktu `REFRESH` yang
dibandingkan pada Q6 dan Q7.

Yang perlu diperhatikan dari hasilnya: 500000 baris masukan menyusut menjadi hanya puluhan
baris keluaran. Biaya besarnya ada pada pemindaian dan pengelompokan, bukan pada pengiriman
hasil. Inilah alasan materialized view masuk akal untuk kasus ini — hasil akhirnya kecil dan
mahal dihitung.

---

### Q6 — `q06_buat_matview.sql` · Materialized view WITH NO DATA

**Perintah**

```sql
CREATE MATERIALIZED VIEW lab4.ringkasan_akses AS
SELECT date_trunc('month', a.waktu) AS bulan, a.kanal,
       count(*) AS jumlah_akses, count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
WITH NO DATA;

SELECT count(*) FROM lab4.ringkasan_akses;        -- harus gagal
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;   -- catat waktunya
```

**Keluaran**

Galat pembacaan sebelum refresh ada di bagian 3 laporan ini.

```text
REFRESH MATERIALIZED VIEW — «… ms»
baris_matview = «…»
matviewname     | ispopulated
ringkasan_akses | t
```

**Alasan keputusan.** Dipilih `WITH NO DATA` agar pembuatan objek terpisah dari pengisian
data. Dengan begitu dua hal dapat dibuktikan secara terpisah: galat
`has not been populated` yang hanya muncul pada matview yang belum diisi, dan biaya `REFRESH`
yang terukur sendiri tanpa tercampur biaya pembuatan objek. Alternatif yang tidak dipakai:
`WITH DATA` — ditolak karena menggabungkan keduanya sehingga kedua bukti yang diminta soal
tidak bisa dipisahkan.

Perbandingan yang penting untuk laporan: membaca matview setelah terisi selesai dalam
hitungan milidetik, karena hanya membaca puluhan baris hasil, bukan memindai ulang 500000
baris sumber seperti pada Q5.

---

### Q7 — `q07_refresh_concurrently.sql` · Refresh concurrent dan index unik

**Perintah**

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;   -- harus gagal

CREATE UNIQUE INDEX ux_ringkasan_akses ON lab4.ringkasan_akses (bulan, kanal);

REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;   -- catat waktunya
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;                -- pembanding
```

**Keluaran**

Galat percobaan pertama ada di bagian 3 laporan ini.

```text
REFRESH MATERIALIZED VIEW CONCURRENTLY — «… ms»
REFRESH MATERIALIZED VIEW (biasa)      — «… ms»
```

**Alasan pemilihan kolom index.** `UNIQUE INDEX` dipasang pada `(bulan, kanal)` karena
kombinasi itulah kunci `GROUP BY` matview, sehingga dijamin unik untuk setiap baris hasil.
Index juga dibuat tanpa klausa `WHERE`, sesuai syarat PostgreSQL bahwa index harus mencakup
seluruh baris matview. Alternatif yang tidak dipakai: index unik pada `(bulan)` saja —
ditolak karena satu bulan memuat empat kanal, sehingga pembuatan index akan gagal dan refresh
concurrent tetap mustahil.

**Mengapa refresh concurrent lebih lambat.** Refresh biasa boleh bersikap kasar. Ia mengunci
matview dengan `ACCESS EXCLUSIVE`, menghitung ulang seluruh hasil ke penyimpanan baru, lalu
menukar isinya sekaligus. Tidak ada pembaca yang boleh melihat keadaan setengah jadi, jadi
tidak perlu ada perbandingan apa pun.

Refresh concurrent tidak boleh mengusir pembaca, sehingga isi lama harus tetap utuh dan
konsisten sepanjang proses. PostgreSQL karena itu menghitung hasil baru ke tabel sementara,
lalu mencocokkan tabel sementara itu dengan isi matview baris per baris. Pencocokan itulah
yang mensyaratkan index unik: tanpa kunci yang unik, tidak ada cara memasangkan baris lama
dengan baris baru. Dari hasil pencocokan, PostgreSQL menerbitkan `INSERT`, `UPDATE`, dan
`DELETE` hanya untuk baris yang berubah, dan seluruh perubahan itu ikut menulis WAL serta
memelihara index.

Jadi refresh concurrent mengerjakan seluruh pekerjaan refresh biasa, ditambah membangun tabel
sementara, ditambah satu operasi pencocokan, ditambah DML beserta WAL-nya. Yang ditukar
adalah waktu: lebih lambat, tetapi pembaca tidak pernah diblokir.

---

### Q8 — `q08_buktikan_pembaca.sql` · Bukti pembaca tidak terblokir

**Cara pengujian.** Dua sesi psql dijalankan bersamaan. Sesi 1 berperan sebagai penulis, sesi
2 sebagai pembaca. Agar tidak perlu adu cepat berpindah jendela, pembaca dijalankan lebih
dulu secara berulang otomatis memakai `\watch`, baru refresh ditembakkan dari sesi 1.

Sesi 2:

```sql
SELECT clock_timestamp() AS jam, count(*) AS baris, sum(jumlah_akses) AS total
FROM lab4.ringkasan_akses \watch 0.5
```

Sesi 1, dua putaran, masing-masing didahului penyisipan 200000 baris:

```sql
INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1, now(), 'web' FROM generate_series(1, 200000);

REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;   -- putaran 1
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;                -- putaran 2
```

**Keluaran putaran 1 — concurrent**

```text
«cuplikan sesi 2: deretan stempel jam yang maju rapat tanpa jeda selama refresh berjalan»
```

**Keluaran putaran 2 — refresh biasa**

```text
«cuplikan sesi 2: dua stempel jam yang mengapit jeda, besar jeda ≈ durasi refresh»
```

**Bukti penguncian dari `pg_stat_activity`**

```text
«keluaran pg_stat_activity saat sesi 2 menggantung — sesi pembaca muncul dengan
 wait_event_type = Lock dan wait_event = relation»
```

**Ringkasan perilaku**

| Skenario | Perilaku sesi pembaca | Kunci yang diambil penulis |
|---|---|---|
| `REFRESH CONCURRENTLY` | `SELECT` langsung selesai, waktunya tetap milidetik, nilainya masih isi lama sampai refresh selesai | `EXCLUSIVE` — masih mengizinkan `ACCESS SHARE` milik pembaca |
| `REFRESH` biasa | `SELECT` menggantung sampai refresh selesai, waktunya melar mengikuti durasi refresh | `ACCESS EXCLUSIVE` — menolak semua kunci lain, termasuk pembacaan |

**Yang perlu ditegaskan.** Pada mode concurrent, pembaca melihat data lama yang **konsisten**,
bukan campuran lama dan baru. Refresh berjalan dalam satu transaksi, sehingga pembaca selalu
melihat satu keadaan utuh: yang lama seluruhnya, atau yang baru seluruhnya. Kebasian
sementara itulah harga yang dibayar untuk tidak memblokir siapa pun.

**Alasan keputusan.** Dipakai dua sesi psql terpisah dengan `\watch` dan pemeriksaan
`pg_stat_activity`, agar "terblokir" dibuktikan sebagai fakta kunci yang terbaca di katalog,
bukan sekadar kesan bahwa query terasa lama. Alternatif yang tidak dipakai: satu sesi dengan
`pg_sleep` di dalam transaksi — ditolak karena satu sesi tidak pernah memblokir dirinya
sendiri, sehingga tidak membuktikan apa pun tentang penguncian.

**Catatan efek samping.** Q8 menambah 400000 baris permanen ke `lab4.jejak_akses` (200000 per
putaran). Akibatnya angka Q5 tidak lagi dapat diulang pada kondisi data yang sama setelah Q8
dijalankan.

---

### Q9–Q21

«Belum dikerjakan. Q9–Q13 oleh Naifah (Langkah 4), Q14–Q17 oleh Nadine (Langkah 5),
Q18–Q21 oleh Finsus (Langkah 6).»

---

## 3. Pesan Galat Utuh

Ketiga galat di bawah ini adalah galat yang secara eksplisit diminta soal untuk disalin utuh.

### Q3 — Penyisipan ditolak `WITH CASCADED CHECK OPTION`

```text
«tempel apa adanya dari terminal, termasuk baris DETAIL yang memuat seluruh isi baris gagal»
```

Bentuk yang diharapkan:

```text
ERROR:  new row violates check option for view "film_murah"
DETAIL:  Failing row contains (9001, FILM UJI SELISIH, ...).
```

### Q6 — Membaca matview yang belum terisi

```text
«tempel apa adanya dari terminal»
```

Bentuk yang diharapkan:

```text
ERROR:  materialized view "ringkasan_akses" has not been populated
HINT:  Use the REFRESH MATERIALIZED VIEW command.
```

### Q7 — Refresh concurrent tanpa index unik

```text
«tempel apa adanya dari terminal»
```

Bentuk yang diharapkan:

```text
ERROR:  cannot refresh materialized view "lab4.ringkasan_akses" concurrently
HINT:  Create a unique index with no WHERE clause on one or more columns of the materialized view.
```

Sebagai pelengkap, galat Q4 juga dicatat pada bagian jawaban Q4 di atas meskipun tidak
termasuk tiga galat yang diwajibkan.

---

## 4. Refleksi A–E

### Refleksi A — Menempatkan seluruh akses aplikasi di balik view

**Dua keuntungan.**

1. **Kendali kolom dan baris terpusat.** Hak akses cukup diberikan pada view, sehingga kolom
   sensitif tidak pernah ikut terekspos dan penyaringan baris berlaku seragam bagi semua
   pemanggil — tanpa bergantung pada disiplin tiap pengembang mengingat menambahkan `WHERE`.
2. **Bentuk lama dapat dipertahankan saat skema berubah.** View menjadi fasad: struktur di
   bawahnya boleh berpindah sementara nama dan kolom yang dilihat aplikasi lama tetap. Ini
   persis mekanisme yang dipakai pada fase contract Q20 nanti.

**Dua kerugian.**

1. **Kemampuan menulis berkurang dan tidak seragam.** Q1 menunjukkan view satu tabel masih
   bisa disisipi, sedangkan Q4 menunjukkan view beragregasi langsung ditolak. Tim harus tahu
   view mana yang bisa ditulis dan mana yang butuh trigger `INSTEAD OF`, dan pengetahuan itu
   tidak terlihat dari nama viewnya.
2. **Kesalahan menjadi senyap bila aturan tidak ditegakkan.** Q2 membuktikan `INSERT`
   melaporkan sukses padahal barisnya tidak pernah terlihat lagi lewat view yang sama. Galat
   senyap jauh lebih mahal daripada galat berisik, karena baru ketahuan jauh di belakang,
   biasanya dari keluhan pengguna, dan penelusurannya dimulai dari tempat yang salah.

**Satu keadaan konkret yang mempersulit tim.** Fitur "simpan lalu tampilkan kembali".
Formulir menyimpan film promo lewat `lab4.film_murah` dengan tarif 4.99, layar menampilkan
notifikasi berhasil, lalu daftar yang dibaca dari view yang sama tidak memuat baris tersebut.
Tim menghabiskan waktu memburu bug di kode aplikasi dan di cache, padahal penyebabnya ada di
lapisan basis data: view berpredikat tanpa `WITH CHECK OPTION`. Setelah check option dipasang
seperti pada Q3, kasus yang sama berubah menjadi galat langsung di titik penyimpanan,
sehingga dapat diperbaiki di menit yang sama.

### Refleksi B — Laporan yang selalu mutakhir sekaligus selalu cepat

**Trade-off.** Materialized view menukar kesegaran dengan kecepatan. Angka yang dibaca adalah
hasil perhitungan pada saat refresh terakhir, bukan keadaan basis data saat ini. Q5 dan Q6
memberi angkanya: menghitung langsung memakan waktu yang dibayar **setiap kali** laporan
dibuka, sedangkan membaca matview hanya milidetik tetapi biayanya dibayar sekali per refresh.
Selalu mutakhir dan selalu cepat sekaligus hanya mungkin bila perhitungannya memang murah;
begitu data membesar, tim harus memilih besarnya kebasian yang masih dapat diterima. Refresh
concurrent mengurangi gangguan bagi pembaca, tetapi Q7 menunjukkan ia menambah durasi dan
beban tulis — sehingga refresh yang terlalu sering justru membebani sistem yang sama.

**Batas kebasian yang diusulkan.** Laporan operasional harian maksimal basi 15 menit;
laporan penutupan bulanan dihitung ulang sekali setelah tanggal tutup buku dan setelah itu
dianggap beku. Setiap halaman laporan wajib menampilkan stempel waktu refresh terakhir,
sehingga pembaca tahu persis seberapa lama data tertinggal dan tidak perlu menebak.

**Jadwal refresh.** `REFRESH MATERIALIZED VIEW CONCURRENTLY` setiap 15 menit pada jam kerja,
dan setiap jam di luar jam kerja. Pemicunya penjadwal di luar basis data seperti cron atau
pg_cron, bukan trigger, agar kegagalan satu refresh tidak pernah menggagalkan transaksi
pengguna. Sesi refresh dipasangi `lock_timeout` dan `statement_timeout` supaya refresh yang
tersangkut tidak menumpuk. Untuk permintaan yang benar-benar harus real time, disediakan satu
tombol terpisah yang menjalankan query sumber langsung, dengan peringatan bahwa hasilnya
lebih lambat.

**Tindakan saat refresh gagal di tengah jalan.** Refresh berjalan dalam satu transaksi,
sehingga kegagalan berarti matview tetap berisi data lama yang konsisten — tidak pernah ada
kondisi setengah jadi. Tindakannya: catat kegagalan beserta pesannya, coba ulang otomatis
maksimal dua kali dengan jeda, dan bila tetap gagal kirim peringatan ke saluran tim serta
tandai halaman laporan sebagai basi melewati batas. Yang **tidak** boleh dilakukan: menghapus
isi matview, atau diam-diam mengganti matview dengan query langsung. Keduanya mengubah
kegagalan yang terlihat menjadi kelambatan yang membingungkan.

### Refleksi C — Trigger baris lawan trigger pernyataan

«Ditulis oleh Naifah setelah Q12 dan Q13 selesai diukur.»

### Refleksi D — EXCLUDE lawan trigger pemeriksa

«Ditulis oleh Nadine setelah Q17 selesai.»

### Refleksi E — Jarak rilis 0045 ke 0046

«Ditulis oleh Finsus setelah Q20 dan Q21 selesai.»

---

## 5. Ringkasan Waktu

| Tugas | Yang diukur | Waktu | Penafsiran |
|---|---|---:|---|
| Q5 | Agregasi langsung atas 500000 baris, pengukuran 1 | «… ms» | Cache dingin, biasanya paling lambat |
| Q5 | Agregasi langsung, pengukuran 2 | «… ms» | |
| Q5 | Agregasi langsung, pengukuran 3 | «… ms» | Angka yang dipakai sebagai garis dasar |
| Q6 | `REFRESH` biasa pertama | «… ms» | Hitung ulang penuh, tukar isi sekaligus |
| Q6 | Membaca matview setelah terisi | «… ms» | Bandingkan dengan Q5 — inilah keuntungan matview |
| Q7 | `REFRESH CONCURRENTLY` setelah index unik | «… ms» | Lebih lambat: ada tabel sementara, pencocokan, dan DML |
| Q7 | `REFRESH` biasa, kondisi data sama | «… ms» | Pembanding adil untuk baris di atasnya |
| Q12 | UPDATE massal, trigger baris aktif | «belum diukur» | Diisi Naifah |
| Q12 | UPDATE massal, trigger nonaktif | «belum diukur» | |
| Q13 | UPDATE massal, trigger pernyataan | «belum diukur» | Diisi Naifah |

**Penafsiran keseluruhan.**

- **Q5 lawan pembacaan matview.** «Isi setelah angkanya lengkap: berapa kali lipat lebih
  cepat, dan apa artinya bagi laporan yang dibuka berulang kali dalam sehari.»
- **Q6 lawan Q7.** «Isi: selisih refresh biasa dan concurrent, lalu kaitkan dengan pekerjaan
  tambahan yang dijelaskan pada jawaban Q7.»
- **Q12 lawan Q13.** «Diisi Naifah setelah Langkah 4.»

---

## 6. Migrasi, Commit, dan Sesi Pembaca

### Struktur `migrations/`

Folder sudah dibuat di akar repositori dan masih berisi `.gitkeep`. Enam pasang migrasi
0041–0046 disusun pada Q21. Tangkapan layar strukturnya disimpan sebagai
`latihan/p04/struktur_migrations.png` dan dilampirkan di sini setelah Langkah 6 selesai.

Catatan konvensi: `migrations/` di akar repositori **berbeda** dari
`latihan/p02/migrations/` yang dipakai Flyway. Service `flyway` pada `docker-compose.yml`
hanya me-mount folder p02, dan penamaannya `V1__…sql`; migrasi P04 memakai pola
`0041_…up.sql` / `0041_…down.sql` dan tidak dijalankan Flyway.

### Commit

| Cakupan | Commit | Tautan |
|---|---|---|
| Q0 — setup skema `lab4` | `308b093` | https://github.com/vitermoldy/msbd-2026/commit/308b0936db3429b222c934b6b631bd8e264b71c1 |
| Q1–Q4 — view dan check option | `739a6cf` | https://github.com/vitermoldy/msbd-2026/commit/739a6cfc12e8e4b4f76b69ba30ca684184057bdf |
| Q5–Q8 — materialized view | `25203ba` | https://github.com/vitermoldy/msbd-2026/commit/25203bae9a6c7571c321fce057d2e59a7bdc6f07 |
| Q9–Q13 — trigger audit (Naifah) | «menyusul» | |
| Q14–Q17 — constraint (Nadine) | «menyusul» | |
| Q18–Q21 — expand–contract dan migrasi (Finsus) | «menyusul» | |

Seluruh commit berada di cabang `latihan/p04-sql2`.

### Catatan sesi pembaca

Sesi pembaca pada Langkah 6 (Q18–Q20) belum dijalankan. Bagian ini diisi setelah fase
expand–contract dikerjakan, memuat tahap mana yang sempat membuat pembaca menunggu, tahap
mana yang membuatnya gagal, dan urutan salah yang diuji beserta galatnya.

Untuk Langkah 3, perilaku pembaca sudah dicatat pada jawaban Q8: refresh concurrent tidak
pernah memblokir pembaca, sedangkan refresh biasa memblokirnya selama durasi refresh.
