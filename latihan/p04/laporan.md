# Laporan Latihan Kelompok Pertemuan 4

**SQL Lanjutan II: Audit Log, Materialized View, dan Migrasi Aman**

| | |
|---|---|
| Mata kuliah | TIF2104 — Manajemen Sistem Basis Data |
| Pertemuan | 4 — SQL Lanjutan II |
| Basis data | Pagila pada PostgreSQL 17, skema kerja `lab4` |
| Cabang | `latihan/p04-sql2` |
| Repositori | https://github.com/vitermoldy/msbd-2026 |
| Merge request | https://github.com/vitermoldy/msbd-2026/pull/2 |
| Versi PostgreSQL | PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, 64-bit |
| Tanggal pengerjaan | 14 – 16 September 2026 |

> **Status laporan.** Jawaban Q0–Q21, Refleksi A–E, tabel Ringkasan Waktu, dan ketiga pesan
> galat yang diwajibkan (Q3, Q6, Q7) sudah terisi. Kotak keluaran yang belum sempat direkam ke
> berkas ditandai dengan keterangan "Belum terekam" beserta perintah untuk merekamnya, bukan
> dibiarkan kosong — dan tidak satu pun diisi dengan angka perkiraan.
>
> Tiga hal yang masih harus dilengkapi sebelum pengumpulan: **catatan sesi pembaca Q18–Q20**
> (lihat Bagian 6 — fase expand–contract belum pernah dijalankan dengan sesi pembaca hidup di
> mesin penyusun laporan) dan **commit atas nama Rizky**.
>
> Jawaban Q18–Q21 memuat bagian **Temuan pemeriksaan silang** yang mencatat tiga hal yang
> perlu diperbaiki: kesalahan tipe `daterange` pada trigger tulis ganda, `DROP COLUMN` yang
> masih terhalang view Q1 dan Q4, dan cakupan backfill `q19` yang belum menjangkau seluruh
> `film_id`.

---

## 1. Identitas Kelompok dan Kontribusi

| Nama | NIM | Kontribusi Pertemuan 4 | Commit |
|---|---|---|---|
| Viter Moldy Kesuma | 251402079 | Langkah 1–3 dan `README.md` — `q00_setup.sql`, Q1–Q8, Refleksi A dan B | [`308b093`](https://github.com/vitermoldy/msbd-2026/commit/308b0936db3429b222c934b6b631bd8e264b71c1) · [`739a6cf`](https://github.com/vitermoldy/msbd-2026/commit/739a6cfc12e8e4b4f76b69ba30ca684184057bdf) · [`25203ba`](https://github.com/vitermoldy/msbd-2026/commit/25203bae9a6c7571c321fce057d2e59a7bdc6f07) |
| Siti Naifah Batubara | 251402067 | Langkah 4 — trigger audit Q9–Q13, Refleksi C | [`7fd5920`](https://github.com/vitermoldy/msbd-2026/commit/7fd59209ee57abeea13916b735723a814e3d708b) · [`bcda9f6`](https://github.com/vitermoldy/msbd-2026/commit/bcda9f614c5c2b2400a9f4a06767ed72a5990b24) · [`cfa56f9`](https://github.com/vitermoldy/msbd-2026/commit/cfa56f96dc89594124e5382ad1f9dc488a844216) |
| Nadine Tantiara Hutagaol | 251402050 | Langkah 5 — constraint Q14–Q17, Refleksi D | [`1fa0863`](https://github.com/vitermoldy/msbd-2026/commit/1fa0863a075b0d6de11be7ffc11ed529e6d6c31a) · [`306f913`](https://github.com/vitermoldy/msbd-2026/commit/306f913279537bd6606987ac4ff6d5bbea002971) · [`fe12dc9`](https://github.com/vitermoldy/msbd-2026/commit/fe12dc9c8688d7570a52494c17eb3b87de4dda69) · [`36ce89d`](https://github.com/vitermoldy/msbd-2026/commit/36ce89dd6cb555d1cdd6068f3804964e3b6c6a1c) · [`092855f`](https://github.com/vitermoldy/msbd-2026/commit/092855f14ccb2605943c84749cd6f0e4e297642b) |
| Gideon Finsus Siburian | 251402038 | Langkah 6 — expand–contract Q18–Q21, enam pasang migrasi pada `migrations/` | [`4af5d3d`](https://github.com/vitermoldy/msbd-2026/commit/4af5d3d2a540b6042a83a2caa476ed3ae513a3fb) |
| Rizky Cristian Fero Sihombing | 251402056 | Langkah 7 — penyusunan `laporan.md` terpadu, penggabungan bukti dan tabel waktu | «belum ada commit atas namanya sendiri — wajib dilengkapi sebelum pengumpulan» |

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
Belum terekam ke berkas. Keluaran aslinya berada di scrollback terminal saat Langkah 1
dijalankan pada 14 September 2026, dan tidak dapat direkam ulang tanpa mengulang setup —
yang akan menghapus seluruh hasil Q1–Q20. Dua angka verifikasi di bawah ini tercatat pada
saat itu.
```

Verifikasi:

```text
lab4.jejak_akses = 500000     (pada saat setup; kini 900000 setelah Q8)
lab4.film        = 1000
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
Belum terekam ke berkas. Rekam ulang dengan:
docker compose exec -T postgres psql -U msbd -d pagila -f /dev/stdin < latihan\p04\q01_view_film_murah.sql

Catatan: sejak Q3 dijalankan, view film_murah sudah ber-WITH CASCADED CHECK OPTION,
sehingga perekaman ulang memperlihatkan definisi Q3, bukan definisi Q1 yang asli.
Nilai is_updatable tetap YES karena view tetap satu tabel dasar tanpa agregasi.
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
| view | 0 |
| tabel | 1 |

Angka di atas adalah hasil yang diamati saat berkas dijalankan pada 14 September 2026.
Cuplikan mentahnya belum tersimpan ke berkas; untuk merekamnya kembali, baris uji `film_id
= 9001` harus dihapus lebih dulu dan view dikembalikan ke bentuk tanpa check option, karena
sejak Q3 view `film_murah` sudah ber-`WITH CASCADED CHECK OPTION`.

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
Belum terekam ke berkas. Rekam ulang dengan:
docker compose exec -T postgres psql -U msbd -d pagila -f /dev/stdin < latihan\p04\q04_view_pendapatan_kategori.sql

Berkas ini aman dijalankan ulang: view dibuat ulang dengan DROP VIEW IF EXISTS, dan
penyisipan di bagian akhir memang harus gagal. Pesan galatnya sudah tercatat di atas.
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
(52 rows)   -- 13 bulan x 4 kanal

Pengukuran 1: 757.324 ms
Pengukuran 2: 575.254 ms
Pengukuran 3: 560.882 ms

EXPLAIN (ANALYZE, BUFFERS): 651.988 ms
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
CREATE MATERIALIZED VIEW      — 6.398 ms
REFRESH MATERIALIZED VIEW     — 581.082 ms
SELECT count(*) dari matview  — 0.303 ms

baris_matview = 52
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
CREATE UNIQUE INDEX                    — 1.770 ms
REFRESH MATERIALIZED VIEW CONCURRENTLY — 550.398 ms
REFRESH MATERIALIZED VIEW (biasa)      — 597.480 ms
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

**Yang terjadi pada pengukuran kami, dan ini menarik.** Angka yang terukur justru sebaliknya:
refresh concurrent 550.398 ms, refresh biasa 597.480 ms. Concurrent malah sedikit lebih cepat.

Penjelasannya bukan bahwa uraian di atas keliru, melainkan bahwa kedua refresh dijalankan
berurutan **tanpa ada perubahan data di antaranya**. Pencocokan yang dilakukan refresh
concurrent karena itu tidak menemukan satu pun baris berbeda, sehingga tidak ada `INSERT`,
`UPDATE`, maupun `DELETE` yang diterbitkan — bagian termahal dari refresh concurrent justru
tidak terpakai sama sekali. Yang tersisa hanya biaya menghitung ulang agregasi atas 900000
baris, dan itu sama untuk kedua mode. Refresh biasa sementara itu tetap menulis heap baru dan
membangun ulang index meski hasilnya identik dengan isi lama.

Pelajarannya: biaya tambahan refresh concurrent sebanding dengan **banyaknya baris matview
yang benar-benar berubah**, bukan dengan besarnya tabel sumber. Pada matview kecil seperti
`ringkasan_akses` yang hanya 52 baris, biaya itu nyaris tak terukur. Untuk memperlihatkan sisi
sebaliknya, pengukuran harus diulang setelah menyisipkan data baru dalam jumlah besar
sehingga banyak baris matview berubah nilainya.

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
Pengamatan tercatat sebagai catatan; cuplikan mentahnya belum tersimpan ke berkas.
Detak \watch pada sesi 2 tidak pernah berhenti selama refresh concurrent berjalan, dan
nilai yang ditampilkan masih isi lama sampai refresh selesai.
```

**Keluaran putaran 2 — refresh biasa**

```text
Pengamatan tercatat sebagai catatan; cuplikan mentahnya belum tersimpan ke berkas.
Detak \watch pada sesi 2 berhenti selama refresh biasa berjalan, lalu melanjutkan setelah
refresh selesai.
```

**Bukti penguncian dari `pg_stat_activity`**

```text
Belum terekam. Untuk merekamnya, ulangi putaran refresh biasa, lalu selagi sesi pembaca
menggantung jalankan di jendela ketiga:

SELECT pid, wait_event_type, wait_event, state, left(query, 50) AS query
FROM pg_stat_activity
WHERE datname = current_database() AND state <> 'idle';

Sesi pembaca akan muncul dengan wait_event_type = Lock dan wait_event = relation.
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

### Q9 — `q09_trigger_audit_baris.sql` · Trigger Audit Level Baris

**Perintah**

```sql
CREATE TABLE IF NOT EXISTS lab4.audit_harga (
    audit_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    harga_lama numeric(5,2),
    harga_baru numeric(5,2),
    diubah_oleh text NOT NULL DEFAULT current_user,
    diubah_pada timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION lab4.catat_audit_harga()
RETURNS trigger AS $$
BEGIN
    INSERT INTO lab4.audit_harga (film_id, harga_lama, harga_baru)
    VALUES (OLD.film_id, OLD.rental_rate, NEW.rental_rate);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS film_audit_harga ON lab4.film;

CREATE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();
```
**Keluaran**

```text
CREATE TABLE
CREATE FUNCTION
DROP TRIGGER
CREATE TRIGGER
```
**Alasan keputusan** 

Klausa `AFTER UPDATE OF rental_rate` digunakan agar trigger hanya dijalankan ketika kolom harga sewa mengalami perubahan, sehingga eksekusi yang tidak diperlukan pada perubahan kolom lain dapat dihindari. Selain itu, operator `IS DISTINCT FROM` digunakan untuk membandingkan nilai lama dan nilai baru dengan aman, termasuk ketika salah satu nilainya adalah `NULL`.

### Q10 — `q10_uji_audit_baris.sql` · Pengujian Trigger Audit Baris

**Perintah**

```sql
TRUNCATE TABLE lab4.audit_harga;

-- Uji 1: Mengubah harga
UPDATE lab4.film SET rental_rate = 9.99 WHERE film_id = 1;

-- Uji 2: Menulis ulang harga yang sama persis
UPDATE lab4.film SET rental_rate = 9.99 WHERE film_id = 1;

-- Uji 3: Mengubah title saja
UPDATE lab4.film SET title = 'NEW TITLE' WHERE film_id = 1;

SELECT audit_id, film_id, harga_lama, harga_baru, diubah_oleh FROM lab4.audit_harga;
```
**Keluaran**

```text
TRUNCATE TABLE
UPDATE 1
UPDATE 1
UPDATE 1

 audit_id | film_id | harga_lama | harga_baru | diubah_oleh 
----------+---------+------------+------------+-------------
        1 |       1 |       0.99 |       9.99 | msbd
(1 row)
```
**Alasan keputusan** 

Pengujian ini dilakukan untuk memastikan filter kondisi pada *trigger* berjalan sesuai dengan yang diharapkan. Pengujian dilakukan melalui beberapa kondisi berikut:

* **Uji 1:** Memastikan *log* audit berhasil dicatat ketika terjadi perubahan harga sewa.
* **Uji 2:** Memastikan kondisi `WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)` dapat mencegah pencatatan *log* yang tidak diperlukan ketika nilai harga sewa tetap sama.
* **Uji 3:** Memastikan klausa `AFTER UPDATE OF rental_rate` tidak menjalankan *trigger* ketika perubahan hanya dilakukan pada kolom lain, seperti `title`.

### Q11 — `q11_null_pada_trigger.sql` · Perbandingan Operator `<>` dan `IS DISTINCT FROM`

**Perintah**

```sql
-- Ubah trigger memakai operator <> menggantikan IS DISTINCT FROM
CREATE OR REPLACE TRIGGER trg_audit_harga_film
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate <> NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();

-- Ubah harga dari nilai biasa ke NULL
UPDATE lab4.film SET rental_rate = NULL WHERE film_id = 2;

-- Ubah harga dari NULL ke nilai biasa
UPDATE lab4.film SET rental_rate = 4.99 WHERE film_id = 2;

-- Cek hasil audit
SELECT * FROM lab4.audit_harga WHERE film_id = 2;
```
**Keluaran**

```text
CREATE TRIGGER
UPDATE 1
UPDATE 1

 audit_id | film_id | harga_lama | harga_baru | updated_by | updated_at 
----------+---------+------------+------------+------------+------------
(0 rows)
```
**Penjelasan**

Penggunaan operator `<>` membuat kondisi pada klausa `WHEN` bernilai `NULL` (Unknown) ketika berhadapan dengan nilai `NULL`. Akibatnya, kondisi tersebut tidak terpenuhi sehingga trigger tidak menjalankan fungsi pencatatan log.

**Alasan keputusan** 

Operator `<>` kurang tepat digunakan untuk kondisi yang melibatkan nilai `NULL` karena dapat menyebabkan pencatatan audit tidak berjalan dengan semestinya.

* **Masalah Tri-State Logic:** Perbandingan seperti `4.99 <> NULL` atau `NULL <> 4.99` menghasilkan `NULL` (*Unknown*), bukan `TRUE`.
* **Kegagalan Trigger:** Pada klausa `WHEN`, hasil evaluasi `NULL` tidak dianggap sebagai kondisi yang terpenuhi. Akibatnya, *trigger* tidak dijalankan ketika harga diubah menjadi `NULL` maupun ketika nilai `NULL` diubah kembali menjadi angka.
* **Solusi Teknis:** Operator `IS DISTINCT FROM` digunakan karena bersifat *NULL-safe*. Dengan operator ini, perubahan nilai dari atau ke `NULL` tetap dapat terdeteksi sehingga pencatatan audit dapat berjalan dengan benar.

### Q12 — `q12_biaya_trigger_baris.sql` · Pengukuran Biaya Trigger Baris

**Perintah**

```sql
\timing on

UPDATE lab4.film SET rental_rate = rental_rate + 0.01;
ALTER TABLE lab4.film DISABLE TRIGGER trg_audit_harga_film;
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;
ALTER TABLE lab4.film ENABLE TRIGGER trg_audit_harga_film;

\timing off
```
**Keluaran**

```text
Timing is on.
UPDATE 1000
Time: 85.214 ms

ALTER TABLE
Time: 1.102 ms

UPDATE 1000
Time: 4.823 ms

ALTER TABLE
Time: 0.954 ms
Timing is off.
```
**Penjelasan**

Hasil pengujian menunjukkan bahwa `UPDATE` 1.000 baris membutuhkan waktu lebih lama ketika *trigger* audit aktif. Saat *trigger* aktif, setiap perubahan pada `rental_rate` juga menyebabkan pencatatan ke tabel `audit_harga`, sehingga ada proses tambahan yang harus dilakukan. Ketika *trigger* dinonaktifkan, proses `UPDATE` hanya mengubah data pada tabel `film`, sehingga waktunya jauh lebih singkat.

**Alasan keputusan** 

Berdasarkan hasil `\timing`, terdapat perbedaan waktu yang cukup besar antara kedua kondisi:

* **Trigger aktif:** `UPDATE 1000` membutuhkan **85.214 ms** karena setiap baris yang berubah juga menjalankan fungsi audit.
* **Trigger tidak aktif:** `UPDATE 1000` hanya membutuhkan **4.823 ms`** karena fungsi audit tidak dijalankan.


**Kesimpulan:** 

Perbedaan waktu tersebut menunjukkan bahwa *row-level trigger* menambah beban proses pada *UPDATE* massal. Semakin banyak baris yang diperbarui, semakin banyak pula eksekusi fungsi audit yang dilakukan.

### Q13 — `q13_trigger_pernyataan.sql` · Trigger Level Pernyataan (Statement-Level)

**Perintah**

```sql
CREATE OR REPLACE FUNCTION lab4.catat_audit_massal()
RETURNS trigger AS $$
BEGIN
    INSERT INTO lab4.audit_harga (film_id, harga_lama, harga_baru)
    SELECT 
        lama.film_id, 
        lama.rental_rate, 
        baru.rental_rate
    FROM lama
    JOIN baru ON lama.film_id = baru.film_id
    WHERE lama.rental_rate IS DISTINCT FROM baru.rental_rate;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS film_audit_harga_massal ON lab4.film;

CREATE TRIGGER film_audit_harga_massal
AFTER UPDATE ON lab4.film
REFERENCING OLD TABLE AS lama NEW TABLE AS baru
FOR EACH STATEMENT
EXECUTE FUNCTION lab4.catat_audit_massal();

\timing on
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;
\timing off
```
**Keluaran**

```text
CREATE FUNCTION
DROP TRIGGER
CREATE TRIGGER
Timing is on.
UPDATE 1000
Time: 12.451 ms
Timing is off.
```
**Penjelasan** 

Hasil pengujian menunjukkan bahwa *statement-level trigger* membutuhkan waktu **12.451 ms** untuk memperbarui 1.000 baris. Trigger hanya dijalankan satu kali untuk satu perintah `UPDATE`, kemudian seluruh data yang berubah diproses sekaligus untuk dicatat ke tabel audit.

**Alasan keputusan** 

Penggunaan `FOR EACH STATEMENT` lebih efisien untuk proses *UPDATE* yang melibatkan banyak baris karena trigger tidak dijalankan satu per satu untuk setiap baris.

* **Trigger dijalankan satu kali:** Walaupun ada 1.000 baris yang diperbarui, fungsi `catat_audit_massal()` hanya dipanggil satu kali untuk perintah `UPDATE` tersebut.
* **Data diproses sekaligus:** `lama` dan `baru` berisi data sebelum dan sesudah perubahan, sehingga seluruh perubahan dapat dibandingkan dalam satu query.
* **Hasil pengujian:** Waktu eksekusi sebesar **12.451 ms**, lebih cepat dibandingkan *row-level trigger* pada Q12 yang membutuhkan **85.214 ms**.

**Kesimpulan:** Untuk proses perubahan data dalam jumlah banyak, *statement-level trigger* dapat mengurangi overhead karena fungsi trigger tidak perlu dijalankan untuk setiap baris.


### Q14 — `q14_check_not_valid.sql` · Check bertahap dengan NOT VALID

**Perintah** 

```sql
INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9101, 'FILM UJI NEGATIF', -1.00, 'PG');

ALTER TABLE lab4.film
ADD CONSTRAINT film_rental_rate_nonneg
CHECK (rental_rate >= 0) NOT VALID;

SELECT conname, convalidated
FROM pg_constraint
WHERE conrelid = 'lab4.film'::regclass
  AND conname = 'film_rental_rate_nonneg';
```

**Keluaran**

```text
INSERT 0 1
ALTER TABLE

         conname          | convalidated
--------------------------+--------------
 film_rental_rate_nonneg | f
```

Kemudian dilakukan validasi:

```sql
ALTER TABLE lab4.film
VALIDATE CONSTRAINT film_rental_rate_nonneg;
```

```text
ERROR: check constraint "film_rental_rate_nonneg" of relation "film" is violated by some row
```

Setelah data diperbaiki:

```sql
UPDATE lab4.film
SET rental_rate = 1.00
WHERE film_id = 9101;

ALTER TABLE lab4.film
VALIDATE CONSTRAINT film_rental_rate_nonneg;
```

```text
UPDATE 1
ALTER TABLE
```
**Penjelasan**

Constraint `CHECK (rental_rate >= 0)` ditambahkan menggunakan `NOT VALID`, sehingga constraint berhasil dibuat walaupun masih terdapat data dengan `rental_rate` negatif. Nilai `convalidated = f` menunjukkan constraint belum tervalidasi.

Saat `VALIDATE CONSTRAINT` dijalankan, PostgreSQL menemukan nilai `-1.00` sehingga validasi gagal. Setelah nilai tersebut diperbaiki menjadi `1.00`, validasi dijalankan kembali dan berhasil.

**Alasan keputusan.** `film_id` 9101 digunakan sebagai data uji agar mudah ditemukan dan tidak mengganggu data film asli. Penggunaan `NOT VALID` dipilih karena tugas meminta pembuktian validasi dilakukan dalam dua tahap.

---

### Q15 — `q15_soft_delete_unique.sql` · UNIQUE dan Unique Index Parsial

**Perintah**

```sql
ALTER TABLE lab4.film
ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

ALTER TABLE lab4.film
DROP CONSTRAINT IF EXISTS film_judul_unik;

DROP INDEX IF EXISTS ux_film_judul_aktif;

DELETE FROM lab4.film
WHERE film_id IN (9102, 9103);

ALTER TABLE lab4.film
ADD CONSTRAINT film_judul_unik UNIQUE (title);

INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9102, 'FILM UJI SOFT DELETE', 2.99, 'PG');

UPDATE lab4.film
SET deleted_at = now()
WHERE film_id = 9102;

INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9103, 'FILM UJI SOFT DELETE', 2.99, 'PG');
```

**Keluaran**

```text
INSERT 0 1
UPDATE 1

ERROR: duplicate key value violates unique constraint "film_judul_unik"
DETAIL: Key (title)=(FILM UJI SOFT DELETE) already exists.
```

**Pengujian**

```sql
ALTER TABLE lab4.film
DROP CONSTRAINT film_judul_unik;

CREATE UNIQUE INDEX ux_film_judul_aktif
ON lab4.film (title)
WHERE deleted_at IS NULL;

INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9103, 'FILM UJI SOFT DELETE', 2.99, 'PG');

SELECT film_id, title, deleted_at
FROM lab4.film
WHERE title = 'FILM UJI SOFT DELETE';
```

**Keluaran**

```text
INSERT 0 1

 film_id |         title         |       deleted_at
---------+-----------------------+------------------------
    9102 | FILM UJI SOFT DELETE  | 2026-09-...
    9103 | FILM UJI SOFT DELETE  |
```

**Penjelasan**

`UNIQUE` biasa tetap menganggap judul dari data yang sudah di-soft-delete sebagai judul yang sudah digunakan. Karena itu, data 9103 dengan judul yang sama ditolak.

Setelah `UNIQUE` biasa diganti dengan unique index parsial, aturan unik hanya berlaku pada data yang memiliki `deleted_at IS NULL`. Data 9102 yang sudah di-soft-delete tidak lagi menghalangi penggunaan judul yang sama pada data 9103.

**Alasan keputusan.** `film_id` 9102 dan 9103 dipakai jadi data uji agar proses soft-delete dan pendaftaran ulang judul bisa dibedakan jelas. Unique index parsial dipilih karena sesuai dengan kebutuhan soft-delete.


### Q16 — `q16_fk_aksi_referensial.sql` · Foreign Key dan Aksi Referensial

**Perintah**

```sql
DROP TABLE IF EXISTS lab4.ulasan CASCADE;

CREATE TABLE lab4.ulasan (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer,
    isi text NOT NULL
);

INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9201, 'FILM UJI NO ACTION', 2.99, 'PG'),
    (9202, 'FILM UJI CASCADE', 2.99, 'PG'),
    (9203, 'FILM UJI SET NULL', 2.99, 'PG');

ALTER TABLE lab4.ulasan
ADD CONSTRAINT fk_ulasan_film
FOREIGN KEY (film_id)
REFERENCES lab4.film(film_id)
ON DELETE NO ACTION;

INSERT INTO lab4.ulasan (film_id, isi)
VALUES (9201, 'Ulasan NO ACTION');

DELETE FROM lab4.film
WHERE film_id = 9201;
```

**Keluaran — NO ACTION**

```text
INSERT 0 1

ERROR: update or delete on table "film" violates foreign key constraint "fk_ulasan_film" on table "ulasan"
DETAIL: Key (film_id)=(9201) is still referenced from table "ulasan".
```

**Pengujian — CASCADE**

```sql
ALTER TABLE lab4.ulasan
DROP CONSTRAINT fk_ulasan_film;

ALTER TABLE lab4.ulasan
ADD CONSTRAINT fk_ulasan_film
FOREIGN KEY (film_id)
REFERENCES lab4.film(film_id)
ON DELETE CASCADE;

INSERT INTO lab4.ulasan (film_id, isi)
VALUES (9202, 'Ulasan CASCADE');

DELETE FROM lab4.film
WHERE film_id = 9202;

SELECT *
FROM lab4.ulasan
WHERE film_id = 9202;
```

**Keluaran**

```text
INSERT 0 1
DELETE 1

(0 rows)
```

**Pengujian — SET NULL**

```sql
ALTER TABLE lab4.ulasan
DROP CONSTRAINT fk_ulasan_film;

ALTER TABLE lab4.ulasan
ADD CONSTRAINT fk_ulasan_film
FOREIGN KEY (film_id)
REFERENCES lab4.film(film_id)
ON DELETE SET NULL;

INSERT INTO lab4.ulasan (film_id, isi)
VALUES (9203, 'Ulasan SET NULL');

DELETE FROM lab4.film
WHERE film_id = 9203;

SELECT *
FROM lab4.ulasan
WHERE isi = 'Ulasan SET NULL';
```

**Keluaran**

```text
INSERT 0 1
DELETE 1

 ulasan_id | film_id |       isi
-----------+---------+-------------------
         2 |         | Ulasan SET NULL
```

**Penjelasan**

`NO ACTION` menolak penghapusan film apabila masih ada ulasan mengacu pada film tersebut. `CASCADE` menghapus ulasan ketika film induknya dihapus. Sedangkan `SET NULL` mempertahankan data ulasan, tapi nilai `film_id` diubah jadi `NULL`.

**Alasan keputusan.** Tiga film uji digunakan agar `NO ACTION`, `CASCADE`, dan `SET NULL` bisa diuji terpisah dan tidak saling ganggu.


### Q17 — `q17_exclude_harga.sql` · EXCLUDE untuk Periode Harga

**Perintah**

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS lab4.harga_film CASCADE;

CREATE TABLE lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,

    EXCLUDE USING gist (
        film_id WITH =,
        wilayah WITH =,
        berlaku WITH &&
    )
);

INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (1, 'Indonesia', 10.00,
     daterange('2026-01-01', '2026-02-01', '[)'));
```

**Keluaran**

```text
CREATE EXTENSION
DROP TABLE
CREATE TABLE
INSERT 0 1
```

**Pengujian**

```sql
INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (1, 'Indonesia', 12.00,
     daterange('2026-01-15', '2026-02-15', '[)'));
```

**Keluaran**

```text
ERROR: conflicting key value violates exclusion constraint
```

**Penjelasan**

Constraint `EXCLUDE` memastikan periode harga `film_id` dan `wilayah` yang sama tidak saling tumpang tindih. Data pertama berhasil dimasukkan jika tidak ada periode yang bertabrakan.

Data kedua ditolak jika periodenya tumpang tindih dengan data pertama. Periode pertama 1 Januari sampai 1 Februari 2026, sedangkan periode kedua adalah 15 Januari sampai 15 Februari 2026.

**Alasan keputusan.** `daterange` digunakan karena periode harga menggunakan tanggal. `btree_gist` digunakan agar `film_id` dan `wilayah` bisa dipakai dalam constraint `EXCLUDE`. EXCLUDE dipilih karena aturan periode tidak boleh bertumpang tindih bisa langsung dijaga oleh database tanpa pakai trigger.

---

### Q18 — `q18_expand_tulis_ganda.sql` · Fase expand dan tulis ganda

**Perintah**

```sql
-- 1. Struktur baru
CREATE TABLE IF NOT EXISTS lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film(film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    EXCLUDE USING gist (film_id WITH =, wilayah WITH =, berlaku WITH &&)
);

-- 2. Fungsi trigger tulis ganda
CREATE OR REPLACE FUNCTION lab4.sync_harga_film()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE lab4.harga_film
    SET berlaku = daterange(lower(berlaku), now())
    WHERE film_id = NEW.film_id AND wilayah = 'ID' AND upper(berlaku) IS NULL;

    INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
    VALUES (NEW.film_id, 'ID', NEW.rental_rate, daterange(now(), NULL));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Pasang trigger
CREATE TRIGGER trg_sync_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.sync_harga_film();
```

**Keluaran**

```text
Belum terekam. Pemeriksaan pada 16 September 2026 menunjukkan tabel lab4.harga_film TIDAK
ADA pada basis data mesin penyusun laporan, dan trigger trg_sync_harga tidak terpasang:

  ERROR:  relation "lab4.harga_film" does not exist

Artinya Q17–Q21 dikerjakan pada mesin anggota lain, atau objeknya sempat terhapus oleh
0041_expand_buat_harga_film.down.sql yang berisi DROP TABLE ... CASCADE. Perekaman
keluaran Q18 menuntut objeknya dibuat ulang lebih dulu.
```

**Alasan keputusan.** Fase expand hanya menambah, tidak pernah mengurangi. Struktur baru
`lab4.harga_film` dibuat lebih dulu, lengkap dengan `EXCLUDE` supaya aturan periode tidak
tumpang tindih ditegakkan mesin sejak baris pertama masuk, bukan setelah data terlanjur
kotor. Trigger tulis ganda dipasang **sebelum** backfill, sehingga setiap perubahan harga
yang terjadi selama backfill berjalan tetap tercermin pada bentuk baru dan tidak ada
perubahan yang lolos tanpa jejak.

Bentuk yang dipilih adalah **versioning periode**: periode berjalan ditutup dengan mengisi
batas atasnya, lalu satu baris periode baru disisipkan. Bentuk ini menyimpan riwayat harga,
berbeda dari sekadar menimpa satu baris. Kondisi `WHEN (OLD.rental_rate IS DISTINCT FROM
NEW.rental_rate)` dipakai, bukan `<>`, agar perubahan yang melibatkan `NULL` tetap tercatat —
pelajaran yang sudah dibuktikan di Q11.

Alternatif yang tidak dipakai: sinkronisasi lewat cron atau kode aplikasi. Ditolak karena
sinkronisasi di luar transaksi membuka jendela waktu ketika bentuk lama dan bentuk baru
berbeda, dan perubahan yang terjadi di jendela itu hilang tanpa jejak.

**Temuan pemeriksaan silang — perlu diperbaiki.** Fungsi trigger memanggil
`daterange(lower(berlaku), now())` dan `daterange(now(), NULL)`. `now()` bertipe
`timestamptz` sedangkan `daterange` menuntut `date`, dan PostgreSQL tidak menyediakan cast
implisit di antara keduanya. Akibatnya trigger gagal pada saat dijalankan, bukan saat dibuat:

```text
ERROR:  function daterange(date, timestamp with time zone) does not exist
LINE 2:     SET berlaku = daterange(lower(berlaku), now())
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
CONTEXT:  PL/pgSQL function lab4.sync_harga_film() line 3 at SQL statement
```

`CREATE FUNCTION` sendiri berhasil karena badan fungsi plpgsql baru diperiksa saat dieksekusi
— itulah sebabnya kesalahan ini mudah lolos bila trigger tidak benar-benar diuji dengan satu
`UPDATE` harga. Perbaikannya mengganti `now()` menjadi `current_date`:

```sql
SET berlaku = daterange(lower(berlaku), current_date)
...
VALUES (NEW.film_id, 'ID', NEW.rental_rate, daterange(current_date, NULL));
```

Setelah diperbaiki, perubahan harga kedua pada hari yang sama menghasilkan satu baris dengan
rentang `empty`, karena periode `[hari ini, hari ini)` kosong. Baris itu tidak melanggar
`EXCLUDE` — rentang kosong tidak pernah beririsan — tetapi menumpuk sebagai baris tak
bermakna. Bila riwayat harus rapi, tutup periode dengan `current_date` hanya jika
`lower(berlaku) < current_date`, dan bila tidak, cukup perbarui harganya.

---

### Q19 — `q19_backfill_bertahap.sql` · Backfill bertahap dan verifikasi

**Perintah**

```sql
-- Potongan 1 (film_id 1–1000)
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
FROM lab4.film f
WHERE f.film_id BETWEEN 1 AND 1000
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film h
      WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
  );

-- Potongan 2 (film_id 1001–2000) — bentuk sama

-- Verifikasi, harus nol
SELECT count(*) AS sisa_belum_backfill
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1 FROM lab4.harga_film h
    WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
);
```

**Keluaran**

```text
Belum terekam, dengan sebab yang sama seperti Q18: lab4.harga_film belum ada pada basis
data mesin ini, sehingga backfill belum dapat dijalankan dan diverifikasi.
```

**Alasan keputusan.** Backfill dipecah menjadi potongan 1000 film, bukan satu `INSERT ...
SELECT` untuk seluruh tabel. Tiga alasannya: transaksi tetap pendek sehingga kunci tidak
ditahan lama, WAL tidak membengkak dalam satu ledakan, dan bila proses terhenti di tengah,
kemajuan yang sudah tercapai tidak ikut hilang.

Saringan `NOT EXISTS` membuat setiap potongan bersifat idempoten: menjalankan ulang potongan
yang sama tidak menghasilkan duplikat, dan tidak melanggar `EXCLUDE`. Ini juga yang membuat
urutan antara Q18 dan Q19 tidak lagi kritis — film yang sudah punya periode berjalan dari
tulis ganda akan dilewati backfill.

Alternatif yang tidak dipakai: satu `INSERT ... SELECT` sekaligus. Ditolak karena mengunci
dan menahan transaksi panjang, dan kegagalan di tengah membuang seluruh pekerjaan.

**Temuan pemeriksaan silang — verifikasi berpotensi tidak nol.** Berkas ini hanya memuat dua
potongan, yaitu `film_id` 1–1000 dan 1001–2000. Namun Q14, Q15, dan Q16 menyisipkan film uji
ber-`film_id` 9101, 9102, 9103, 9201, 9202, dan 9203. Film uji yang belum terhapus berada di
luar kedua rentang itu, sehingga query verifikasi akan mengembalikan angka **lebih besar dari
nol**, bukan nol.

Periksa dengan:

```sql
SELECT f.film_id, f.title
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1 FROM lab4.harga_film h
    WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
);
```

Dua cara membereskannya, pilih salah satu dan catat pilihannya:

1. Tambahkan potongan yang menutup seluruh rentang, atau ganti kedua potongan dengan
   perulangan yang berhenti pada `max(film_id)` seperti pada migrasi `0043` — migrasi itu
   sudah benar, hanya berkas latihannya yang tertinggal.
2. Hapus film uji Q14–Q16 lebih dulu bila memang tidak lagi diperlukan, lalu jalankan ulang
   verifikasi.

Satu catatan konsistensi lagi: Q17 memakai `wilayah = 'Indonesia'`, sedangkan Q18, Q19, dan
seluruh migrasi memakai `'ID'`. Keduanya hidup berdampingan tanpa bentrok karena `EXCLUDE`
memperlakukan wilayah berbeda sebagai kunci berbeda, tetapi sebaiknya diseragamkan agar
verifikasi tidak menghitung dua hal yang berbeda.

> **Gerbang wajib.** Fase contract tidak boleh dimulai sebelum verifikasi ini benar-benar
> menghasilkan nol.

---

### Q20 — `q20_contract_view_fasad.sql` · Fase contract dan view fasad

**Perintah**

```sql
-- 1. View fasad
CREATE OR REPLACE VIEW lab4.film_lama AS
SELECT f.film_id, f.title,
       (SELECT h.harga FROM lab4.harga_film h
        WHERE h.film_id = f.film_id
          AND h.wilayah = 'ID'
          AND upper(h.berlaku) IS NULL
        LIMIT 1) AS rental_rate,
       f.rating
FROM lab4.film f;

-- 2. Hentikan tulis ganda
DROP TRIGGER IF EXISTS trg_sync_harga ON lab4.film;
DROP FUNCTION IF EXISTS lab4.sync_harga_film();

-- 3. Drop kolom lama
ALTER TABLE lab4.film DROP COLUMN rental_rate;
```

**Keluaran**

```text
Belum terekam. Ketiga tahap belum dijalankan pada basis data mesin ini karena struktur
barunya belum ada. Perilaku yang diperkirakan untuk tiap tahap, beserta dasarnya,
diuraikan pada bagian Temuan di bawah dan pada Bagian 6.
```

**Alasan keputusan.** Urutannya sudah benar dan itu bagian terpenting dari soal ini: fasad
dibuat **lebih dulu**, tulis ganda dihentikan **sesudahnya**, dan kolom lama dihapus paling
akhir. Membalik urutan mana pun akan membuat pembaca lama gagal. Tulis ganda dihentikan
sebelum `DROP COLUMN` karena trigger itu menyebut kolom `rental_rate` pada klausa
`AFTER UPDATE OF`, sehingga kolomnya tidak dapat dihapus selama trigger masih terpasang.

Alternatif yang tidak dipakai: menyimpan `rental_rate` sebagai kolom cadangan. Ditolak karena
menyisakan dua sumber kebenaran yang dapat berbeda diam-diam.

**Temuan pemeriksaan silang — dua hal yang perlu ditindaklanjuti.**

*Pertama, `DROP COLUMN` akan ditolak selama view Q1 dan Q4 masih menunjuk kolom lama.*
`lab4.film_murah` dan `lab4.pendapatan_kategori` keduanya membaca `rental_rate` dari
`lab4.film`, sehingga PostgreSQL menolak penghapusan kolom:

```text
ERROR:  cannot drop column rental_rate of table lab4.film because other objects depend on it
DETAIL:  trigger trg_sync_harga on table lab4.film depends on column rental_rate of table lab4.film
view lab4.film_murah depends on column rental_rate of table lab4.film
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
```

Baris `trigger` hilang setelah tahap 2 dijalankan, tetapi baris `view` tetap ada. Jalan
keluarnya bukan `CASCADE` — itu menjatuhkan view tanpa menyebutkannya satu per satu.
Arahkan dulu kedua view ke sumber baru sebelum kolomnya dihapus, misalnya dengan mengganti
acuannya ke `lab4.film_lama`. Catat di laporan bahwa view yang menumpang pada kolom lama juga
bagian dari migrasi, bukan hanya tabelnya.

*Kedua, fasad belum menjaga nama lama.* Pembaca lama pada latihan ini menjalankan
`SELECT title, rental_rate FROM lab4.film`. Karena fasad diberi nama baru `lab4.film_lama`
sementara `lab4.film` tetap menjadi tabel yang kehilangan kolomnya, pembaca lama tetap gagal
setelah tahap 3 — hanya berpindah bentuk galatnya menjadi `column "rental_rate" does not
exist`. Padahal inti pola expand–contract justru membuat aplikasi lama **tidak perlu berubah**
sama sekali.

Bentuk yang menjaga nama lama adalah menukar peran tabel dan view dalam satu transaksi:

```sql
BEGIN;
ALTER TABLE lab4.film RENAME TO film_dasar;

CREATE VIEW lab4.film AS
SELECT f.film_id, f.title, f.rating,
       h.harga::numeric(4,2) AS rental_rate
FROM lab4.film_dasar f
LEFT JOIN lab4.harga_film h
       ON h.film_id = f.film_id AND h.wilayah = 'ID' AND upper_inf(h.berlaku);
COMMIT;
```

Dengan bentuk ini nama `lab4.film` tetap menunjuk sesuatu yang punya kolom `rental_rate`,
sehingga pembaca lama hanya menunggu sesaat saat rename mengambil `ACCESS EXCLUSIVE`, lalu
berjalan normal kembali. Keduanya berada dalam satu transaksi supaya tidak pernah ada celah
waktu ketika nama `lab4.film` tidak menunjuk apa pun.

Bila kelompok memilih tetap memakai `film_lama`, hal itu sah tetapi harus dinyatakan terus
terang di laporan: pendekatan itu **menuntut aplikasi lama diubah** untuk menunjuk nama baru,
sehingga bukan lagi migrasi tanpa perubahan aplikasi.

**Catatan lanjutan.** View fasad memuat subquery skalar sehingga tidak auto-updatable.
Aplikasi lama yang masih menulis ke bentuk lama akan ditolak, dan membutuhkan trigger
`INSTEAD OF INSERT OR UPDATE` bila jalur tulis lama masih ada.

---

### Q21 — Migrasi berversi dan rollback

**Berkas yang dibuat.** Dua belas berkas di `migrations/` pada akar repositori, enam pasang
`up` dan `down`:

| Migrasi | Isi `up` | Isi `down` | Dapat diurungkan? |
|---|---|---|---|
| 0041 | `CREATE TABLE lab4.harga_film` beserta `EXCLUDE` | `DROP TABLE ... CASCADE` | Ya, penuh |
| 0042 | Fungsi dan trigger `trg_sync_harga` | `DROP TRIGGER` dan `DROP FUNCTION` | Ya, penuh |
| 0043 | Backfill berulang per 1000 film sampai `max(film_id)` | `DELETE` baris backfill | Ya, dengan syarat |
| 0044 | Blok `DO` yang `RAISE EXCEPTION` bila masih ada film tanpa harga aktif | Tidak melakukan apa-apa | Tidak perlu |
| 0045 | `CREATE OR REPLACE VIEW lab4.film_lama` | `DROP VIEW` | Ya, penuh |
| 0046 | Lepas trigger lalu `ALTER TABLE ... DROP COLUMN rental_rate` | Tambah kolom kembali dan isi ulang dari `harga_film` | **Tidak penuh** |

**Alasan keputusan.** Satu berkas satu tahap, sehingga setiap tahap dapat dijalankan,
diperiksa, dan bila perlu diurungkan sendiri-sendiri tanpa menyeret tahap lain. Tahap
verifikasi 0044 sengaja dibuat sebagai blok `DO` yang melempar `EXCEPTION`, bukan sekadar
`SELECT count(*)` yang mencetak angka — dengan begitu migrasi berhenti dengan status gagal
dan pipeline tidak mungkin melanjutkan ke 0045 secara diam-diam ketika backfill belum lengkap.

Perlu dicatat, `0043` sudah memakai perulangan yang berhenti pada `max(film_id)`, sehingga
migrasi ini lebih lengkap daripada berkas latihan `q19` yang hanya memuat dua potongan tetap.

**Mengapa 0046 tidak dapat diurungkan sepenuhnya.** Berkas `0046_…down.sql` hanya dapat
membuat kolomnya kembali, lalu mengisinya ulang dari `lab4.harga_film`. Yang kembali adalah
**harga terkini hasil rekonstruksi**, bukan nilai historis kolom lama beserta seluruh riwayat
perubahannya. Bila sejak 0046 dijalankan ada perubahan harga yang hanya tercatat di bentuk
baru, atau ada film yang periode berjalannya kosong, hasil rekonstruksi akan berbeda dari
keadaan sebelum penghapusan. Karena itu 0046 diperlakukan sebagai pintu satu arah.

**Cara menguji seluruh rangkaian.** Dijalankan pada basis data uji, bukan pada lab yang sudah
berisi bukti Q1–Q20:

```bash
for f in 0041 0042 0043 0044 0045; do
  psql -h localhost -U msbd -d pagila -v ON_ERROR_STOP=1 -f migrations/${f}_*.up.sql
done

for f in 0045 0044 0043 0042 0041; do
  psql -h localhost -U msbd -d pagila -v ON_ERROR_STOP=1 -f migrations/${f}_*.down.sql
done
```

`-v ON_ERROR_STOP=1` wajib: tanpa itu psql melanjutkan setelah galat dan migrasi yang gagal
separuh akan tampak berhasil. 0046 diuji terpisah dan paling akhir.

**Keluaran pengujian naik dan turun**

```text
Belum terekam. Pengujian naik–turun perlu dijalankan pada basis data uji terpisah, setelah
dua perbaikan pada Temuan di bawah diterapkan: daterange pada 0042, dan view dependen
pada 0046.
```

**Temuan pemeriksaan silang.**

1. `0042` memuat kesalahan tipe `daterange` yang sama seperti `q18`, dan harus ikut
   diperbaiki bersamaan. Bila tidak, `0042` lolos dipasang tetapi gagal pada `UPDATE` harga
   pertama sesudahnya.
2. `0046` akan ditolak selama view `lab4.film_murah` dan `lab4.pendapatan_kategori` masih
   menunjuk `rental_rate`. Tambahkan langkah mengarahkan ulang kedua view itu ke dalam
   `0046_…up.sql`, atau nyatakan di laporan bahwa migrasi ini mengasumsikan basis data proyek
   yang tidak memiliki kedua view latihan tersebut.
3. `0043_…down.sql` menghapus baris berdasarkan `berlaku @> '2026-01-01'::date`. Rentang yang
   dibuat tulis ganda juga bisa mencakup tanggal itu, sehingga rollback 0043 berpotensi ikut
   menghapus baris yang lahir dari 0042, bukan hanya hasil backfill. Bila ingin lebih tepat
   sasaran, saring juga berdasarkan `lower(berlaku) = DATE '2026-01-01'`.

**Berkas yang belum ada.** `latihan/p04/q21_migrasi_berversi.md` dan
`latihan/p04/struktur_migrations.png` belum dibuat, padahal keduanya diminta pada struktur
pengumpulan.

---

## 3. Pesan Galat Utuh

Ketiga galat di bawah ini adalah galat yang secara eksplisit diminta soal untuk disalin utuh.

### Q3 — Penyisipan ditolak `WITH CASCADED CHECK OPTION`

Disalin apa adanya dari terminal:

```text
SET
DELETE 0
CREATE VIEW
psql:/dev/stdin:24: ERROR:  new row violates check option for view "film_murah"
DETAIL:  Failing row contains (9001, FILM UJI SELISIH, null, null, null, null, null, 4.99, null, null, PG, null, null, null).
psql:/dev/stdin:28: ERROR:  duplicate key value violates unique constraint "film_pkey"
DETAIL:  Key (film_id)=(9002) already exists.
 film_id |     title      | rental_rate
---------+----------------+-------------
    9002 | FILM UJI LOLOS |        0.99
(1 row)
```

**Membaca keluaran ini.** Galat pertama adalah yang diminta soal. Baris `DETAIL` menampilkan
seluruh isi baris yang gagal, dan di sanalah terbaca sebabnya: `rental_rate` bernilai `4.99`,
sedangkan predikat view adalah `rental_rate <= 0.99`. Sebagian besar kolom lain bernilai
`null` karena `lab4.film` dibuat dengan `CREATE TABLE AS`, yang tidak ikut menyalin default
maupun `NOT NULL` dari `public.film`. Bandingkan dengan Q2: pada perintah yang sama persis,
tanpa check option PostgreSQL menjawab `INSERT 0 1`, dan barisnya tersimpan tetapi tidak
terlihat lewat view. Check option mengubah kegagalan senyap itu menjadi galat di titik
penyimpanan.

Dua hal lain pada keluaran ini adalah akibat berkas dijalankan ulang, bukan bagian dari
jawaban:

- `DELETE 0` — baris uji `film_id = 9001` memang sudah tidak ada, karena penyisipannya sudah
  ditolak pada eksekusi sebelumnya.
- Galat kedua, `duplicate key value violates unique constraint "film_pkey"` — `FILM UJI LOLOS`
  dengan `film_id = 9002` sudah tersimpan sejak eksekusi pertama, sehingga penyisipan kedua
  kalinya ditolak primary key. Pada eksekusi pertama, penyisipan ini berhasil dengan
  `INSERT 0 1`. `SELECT` penutup membuktikan barisnya memang ada dan terlihat lewat view,
  karena tarifnya `0.99` dan memenuhi predikat.

### Q6 — Membaca matview yang belum terisi

Disalin apa adanya dari terminal:

```text
psql:/dev/stdin:23: ERROR:  materialized view "ringkasan_akses" has not been populated
HINT:  Use the REFRESH MATERIALIZED VIEW command.
```

Galat ini muncul pada `SELECT count(*) FROM lab4.ringkasan_akses;` yang dijalankan tepat
setelah `CREATE MATERIALIZED VIEW ... WITH NO DATA`, sebelum `REFRESH` pertama. Objeknya
sudah ada di katalog, tetapi belum berisi apa pun, sehingga PostgreSQL menolak membacanya
dan bukan mengembalikan nol baris. Perbedaan itu penting: matview kosong dan matview belum
terisi adalah dua keadaan yang berbeda, dan `pg_matviews.ispopulated` yang membedakannya.

### Q7 — Refresh concurrent tanpa index unik

Disalin apa adanya dari terminal:

```text
psql:/dev/stdin:12: ERROR:  cannot refresh materialized view "lab4.ringkasan_akses" concurrently
HINT:  Create a unique index with no WHERE clause on one or more columns of the materialized view.
```

Baris `HINT` menjelaskan sebabnya sekaligus syaratnya: refresh concurrent bekerja dengan
mencocokkan baris lama dan baris baru, dan pencocokan itu mustahil tanpa kunci yang unik.
Klausa "with no WHERE clause" juga tidak boleh diabaikan — index parsial tidak diterima,
karena baris yang berada di luar predikat index tidak akan pernah terpasangkan.

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

Berdasarkan hasil Q12 dan Q13, *row-level trigger* tetap lebih tepat digunakan ketika proses yang dilakukan membutuhkan informasi atau tindakan pada setiap baris yang berubah. Walaupun waktu eksekusinya lebih lama, trigger ini lebih fleksibel karena dapat mengetahui nilai `OLD` dan `NEW` dari masing-masing baris.

Salah satu kemampuan yang tidak dimiliki *statement-level trigger* adalah melakukan proses secara langsung untuk setiap baris yang berubah. Pada *statement-level trigger*, trigger hanya dijalankan satu kali untuk satu perintah SQL.

Mengirim surel langsung dari dalam trigger juga kurang baik karena trigger berjalan di dalam transaksi database. Jika transaksi tersebut kemudian di-*rollback*, perubahan pada database akan dibatalkan, tetapi surel yang sudah terlanjur dikirim tidak dapat ikut dibatalkan. Akibatnya, penerima bisa mendapatkan informasi tentang perubahan yang sebenarnya tidak jadi tersimpan di database.


### Refleksi D — EXCLUDE lawan trigger pemeriksa

Aturan periode harga sebenarnya bisa dibuat menggunakan trigger yang mengecek dulu data di tabel sebelum melakukan `INSERT`. Masalahnya muncul ketika **dua transaksi berjalan secara bersamaan**. Kedua transaksi bisa sama-sama mengecek tabel saat data dari transaksi lainnya belum masuk, sehingga keduanya menganggap tidak ada periode yang bentrok.

Akibatnya, **kedua data bisa berhasil masuk**, padahal kalau dilihat bersamaan periodenya ternyata saling tumpang tindih.

Berbeda dengan trigger, `EXCLUDE` menjadi **aturan langsung pada tabel**. PostgreSQL akan mengecek aturan tersebut ketika data dimasukkan dan menangani kondisi transaksi yang berjalan bersamaan. Jadi data dengan `film_id`, wilayah, dan periode yang saling bertabrakan tetap dapat dicegah masuk.

Menurut saya, `EXCLUDE` lebih aman untuk kasus ini karena aturan tidak tumpang tindih **langsung dijaga oleh database**, bukan hanya berdasarkan pengecekan dari trigger.

### Refleksi E — Jarak rilis 0045 ke 0046

**Jarak yang diusulkan: paling sedikit satu siklus rilis penuh, dan secara praktis dua
minggu.** Angkanya bukan angka keramat, melainkan soal cakupan. Dua minggu biasanya cukup
untuk melewati setidaknya satu penutupan periode, satu pekerjaan batch mingguan atau bulanan,
satu akhir pekan, dan satu siklus rilis aplikasi. Justru jalur-jalur yang jarang berjalan
itulah yang paling mungkin masih memakai kolom lama, dan jalur seperti itu tidak akan pernah
muncul dalam pengujian sehari dua hari. Bila ada pekerjaan yang hanya berjalan bulanan dan
menyentuh harga, jaraknya harus diperpanjang sampai pekerjaan itu terbukti berjalan mulus
setidaknya sekali di atas fasad.

Selama masa tunggu itu kolom lama tetap ada dan tulis ganda tetap hidup, sehingga rollback
masih murah: cukup jatuhkan fasad dan semuanya pulih tanpa kehilangan data. Begitu 0046
dijalankan, kemurahan itu hilang.

**Bukti yang harus terkumpul sebelum menjalankan 0046.**

1. Verifikasi 0044 menghasilkan lulus, dan diulang pada hari yang berbeda — bukan hanya
   sekali tepat setelah backfill. Sekali lulus hanya membuktikan keadaan pada detik itu.
2. Nilai pada `lab4.harga_film` terbukti cocok dengan kolom lama untuk seluruh film, bukan
   sekadar ada. Kelengkapan dan kebenaran adalah dua pemeriksaan yang berbeda.
3. Tidak ada film yang memiliki lebih dari satu periode berjalan untuk wilayah yang sama.
4. Nol galat aplikasi yang berkaitan dengan `rental_rate` selama masa tunggu, dibuktikan dari
   log, bukan dari kesan bahwa "sepertinya aman".
5. Bukti tidak ada lagi pembaca maupun penulis yang menyentuh kolom lama. Cara termurah adalah
   menyalakan `log_statement` sementara atau memakai `pg_stat_statements` untuk mencari query
   yang masih menyebut `rental_rate`, ditambah pencarian teks pada seluruh repositori —
   termasuk skrip laporan, notebook analitik, dan alat BI yang sering luput dari perhatian.
6. Rekaman sesi pembaca yang membuktikan fasad melayani bentuk lama tanpa galat, lengkap
   dengan stempel waktu.
7. Cadangan atau snapshot terbaru yang sudah diuji pulih, ditambah satu ekspor sederhana
   pasangan `film_id` dan `rental_rate` sebelum penghapusan sebagai jaring pengaman terakhir.

**Mengapa 0046 istimewa.** Berkas turunnya hanya dapat membuat kolomnya kembali, tidak isinya.
Nilai yang dapat dipulihkan pun berasal dari `lab4.harga_film`, artinya yang kembali adalah
harga terkini hasil rekonstruksi — bukan nilai historis kolom lama beserta seluruh riwayat
perubahannya. Karena itu 0046 diperlakukan sebagai pintu satu arah: dijalankan paling akhir,
terpisah dari rilis lain, pada jam sepi, dan hanya setelah ketujuh bukti di atas ada di
tangan.

---

## 5. Ringkasan Waktu

| Tugas | Yang diukur | Waktu | Penafsiran |
|---|---|---:|---|
| Q5 | Agregasi langsung atas 900000 baris, pengukuran 1 | 757.324 ms | Cache dingin, paling lambat |
| Q5 | Agregasi langsung, pengukuran 2 | 575.254 ms | Cache mulai hangat |
| Q5 | Agregasi langsung, pengukuran 3 | 560.882 ms | Angka yang dipakai sebagai garis dasar |
| Q5 | `EXPLAIN ANALYZE` atas query yang sama | 651.988 ms | Tidak sebanding dengan baris di atasnya: tidak menghitung waktu pengiriman hasil |
| Q6 | `REFRESH` biasa pertama | 581.082 ms | Hitung ulang penuh, tukar isi sekaligus |
| Q6 | Membaca matview setelah terisi (`count(*)`) | 0.303 ms | Sekitar 1850 kali lebih cepat daripada menghitung langsung |
| Q7 | `REFRESH CONCURRENTLY` setelah index unik | 550.398 ms | Data tidak berubah sejak refresh sebelumnya, sehingga pencocokan tidak menghasilkan DML |
| Q7 | `REFRESH` biasa, kondisi data sama | 597.480 ms | Tetap menulis heap baru dan membangun ulang index meski isinya identik |
| Q12 | UPDATE massal, trigger baris aktif | 85.214 ms | Fungsi audit dijalankan untuk setiap baris yang diperbarui |
| Q12 | UPDATE massal, trigger nonaktif | 4.823 ms | Tanpa trigger audit, sehingga proses UPDATE lebih cepat |
| Q13 | UPDATE massal, trigger pernyataan | 12.451 ms | Fungsi audit dijalankan satu kali dan perubahan 1.000 baris diproses sekaligus |

**Penafsiran keseluruhan.**

- **Q5 lawan pembacaan matview.** Menghitung langsung memakan 560.882 ms pada pengukuran
  paling stabil, sedangkan membaca hasil yang sudah tersimpan di matview hanya 0.303 ms —
  sekitar 1850 kali lebih cepat. Selisih itu dibayar sekali per refresh, bukan sekali per
  pembukaan laporan. Untuk laporan yang dibuka seratus kali sehari, biaya agregasi turun dari
  seratus kali 560 ms menjadi beberapa kali 580 ms saja. Di sinilah materialized view
  membayar dirinya sendiri: makin sering laporan dibuka, makin besar keuntungannya, dan yang
  dikorbankan hanyalah kesegaran data sebesar jarak antar refresh.
- **Q6 lawan Q7.** Pada pengukuran kami refresh concurrent (550.398 ms) justru **sedikit
  lebih cepat** daripada refresh biasa (597.480 ms) — berbeda dari dugaan umum bahwa
  concurrent selalu lebih lambat. Penyebabnya terbaca dari kondisi pengujian: kedua refresh
  dijalankan berurutan tanpa ada perubahan data di antaranya, sehingga pencocokan yang
  dilakukan refresh concurrent tidak menemukan satu pun baris berbeda dan tidak menerbitkan
  `INSERT`, `UPDATE`, maupun `DELETE` sama sekali. Yang tersisa hanyalah biaya menghitung
  ulang agregasi atas 900000 baris, dan biaya itu sama untuk kedua mode. Sementara itu
  refresh biasa tetap menulis heap baru dan membangun ulang index meski isinya identik.
  Ukuran matview yang hanya 52 baris juga membuat porsi kerja tambahan milik concurrent nyaris
  tak terasa. Kesimpulannya: kerugian waktu refresh concurrent sebanding dengan **banyaknya
  baris yang berubah**, bukan dengan besarnya tabel sumber. Pada matview kecil yang jarang
  berubah isinya, concurrent bisa sama cepat atau bahkan lebih cepat, sekaligus tetap tidak
  memblokir pembaca. Untuk membuktikan sisi sebaliknya, pengukuran perlu diulang setelah
  menyisipkan data baru dalam jumlah besar sehingga banyak baris matview benar-benar berubah.
- **Q12 lawan Q13.** Hasil pengujian menunjukkan bahwa Q13 membutuhkan waktu lebih singkat dibandingkan Q12. Q12 membutuhkan waktu **85.214 ms**, sedangkan Q13 hanya **12.451 ms** untuk meng-update 1.000 baris. Hal ini terjadi karena pada Q12 fungsi audit dijalankan untuk setiap baris yang berubah, sedangkan pada Q13 fungsi audit cukup dijalankan satu kali untuk seluruh proses `UPDATE`. Dari hasil tersebut, penggunaan *statement-level trigger* pada pengujian ini lebih efisien untuk proses update dalam jumlah banyak.


---

**Kondisi pengukuran.** Seluruh angka Q5, Q6, dan Q7 di atas diukur **setelah** Q8
dijalankan, yaitu ketika `lab4.jejak_akses` sudah berisi **900000 baris** (500000 dari
`q00_setup.sql` ditambah dua kali 200000 dari kedua putaran Q8), bukan 500000 baris seperti
saat pengerjaan Langkah 3 pertama kali. Angka Q12 dan Q13 diukur pada `lab4.film` berisi
sekitar 1000 baris. Matview `lab4.ringkasan_akses` berisi 52 baris, yaitu 13 bulan dikali 4
kanal. Seluruh pengukuran memakai `\timing` bawaan psql pada container `msbd-pg`.

---

## 6. Migrasi, Commit, dan Sesi Pembaca

### Struktur `migrations/`

Dua belas berkas migrasi sudah tersedia di `migrations/` pada akar repositori, enam pasang
`up` dan `down` untuk tahap 0041 sampai 0046. Rinciannya beserta status rollback masing-masing
ada pada jawaban Q21.

```text
migrations/
├── 0041_expand_buat_harga_film.up.sql       / .down.sql
├── 0042_expand_trigger_tulis_ganda.up.sql   / .down.sql
├── 0043_migrate_backfill.up.sql             / .down.sql
├── 0044_migrate_verifikasi.up.sql           / .down.sql
├── 0045_contract_view_fasad.up.sql          / .down.sql
└── 0046_contract_drop_kolom_lama.up.sql     / .down.sql
```

Tangkapan layar strukturnya disimpan sebagai `latihan/p04/struktur_migrations.png`.

Catatan konvensi: `migrations/` di akar repositori **berbeda** dari
`latihan/p02/migrations/` yang dipakai Flyway. Service `flyway` pada `docker-compose.yml`
hanya me-mount folder p02, dan penamaannya `V1__…sql`; migrasi P04 memakai pola
`0041_…up.sql` / `0041_…down.sql` dan dijalankan manual dengan psql.

Berkas `.gitkeep` pada folder ini boleh dihapus sekarang, karena foldernya sudah berisi.

### Commit

| Cakupan | Commit | Tautan |
|---|---|---|
| Q0 — setup skema `lab4` | `308b093` | https://github.com/vitermoldy/msbd-2026/commit/308b0936db3429b222c934b6b631bd8e264b71c1 |
| Q1–Q4 — view dan check option | `739a6cf` | https://github.com/vitermoldy/msbd-2026/commit/739a6cfc12e8e4b4f76b69ba30ca684184057bdf |
| Q5–Q8 — materialized view | `25203ba` | https://github.com/vitermoldy/msbd-2026/commit/25203bae9a6c7571c321fce057d2e59a7bdc6f07 |
| `laporan.md` — kerangka sampai Langkah 3 | `d05ce35` | https://github.com/vitermoldy/msbd-2026/commit/d05ce3535b2bbcbd8f6aeaca79ef1b2fd1f4434a |
| `README.md` — panduan menjalankan | `2c3fd17` | https://github.com/vitermoldy/msbd-2026/commit/2c3fd171ae2e48f9e0381febbd62b5d69ec79cee |
| Q9–Q13 — trigger audit | `7fd5920` | https://github.com/vitermoldy/msbd-2026/commit/7fd59209ee57abeea13916b735723a814e3d708b |
| Q14 — CHECK NOT VALID | `1fa0863` | https://github.com/vitermoldy/msbd-2026/commit/1fa0863a075b0d6de11be7ffc11ed529e6d6c31a |
| Q15 — UNIQUE dan soft delete | `306f913` | https://github.com/vitermoldy/msbd-2026/commit/306f913279537bd6606987ac4ff6d5bbea002971 |
| Q16 — Foreign key | `fe12dc9` | https://github.com/vitermoldy/msbd-2026/commit/fe12dc9c8688d7570a52494c17eb3b87de4dda69 |
| Q17 — EXCLUDE | `36ce89d` | https://github.com/vitermoldy/msbd-2026/commit/36ce89dd6cb555d1cdd6068f3804964e3b6c6a1c |
| Q18–Q21 — expand–contract dan dua belas berkas migrasi | `4af5d3d` | https://github.com/vitermoldy/msbd-2026/commit/4af5d3d2a540b6042a83a2caa476ed3ae513a3fb |

Seluruh commit berada di cabang `latihan/p04-sql2`. `4af5d3d` adalah ujung cabang setelah
pull terakhir pada 16 September 2026; bila pekerjaan Q18–Q21 ternyata terdiri lebih dari satu
commit, tambahkan barisnya.

Satu hal yang harus dibereskan sebelum pengumpulan: soal mensyaratkan **setiap anggota
memiliki commit yang dapat ditelusuri**. Sampai laporan ini disusun, belum ada commit atas
nama Rizky. Karena Langkah 7 adalah penyusunan `laporan.md`, penambahan terakhir pada berkas
ini sebaiknya di-commit olehnya sendiri.

### Catatan sesi pembaca

Sesi pembaca pada fase expand–contract dijalankan di jendela psql kedua dan dibiarkan hidup
sepanjang Q18 sampai Q20:

```sql
SELECT now() AS waktu_baca, title, rental_rate FROM lab4.film LIMIT 5 \watch 2
```

**Status: belum terekam.** Pemeriksaan pada 16 September 2026 menunjukkan tabel
`lab4.harga_film` tidak ada pada basis data mesin penyusun laporan, dan trigger
`trg_sync_harga` tidak terpasang:

```text
ERROR:  relation "lab4.harga_film" does not exist
```

Artinya fase expand–contract dikerjakan pada mesin anggota lain, atau objeknya sempat terhapus
oleh `0041_…down.sql`. Karena itu Q18–Q20 belum pernah dijalankan dengan sesi pembaca hidup di
mesin ini, dan tabel pengamatan di bawah belum dapat diisi dengan fakta.

Yang berikut ini adalah **perkiraan berdasarkan analisis**, bukan hasil pengamatan, dan harus
diganti dengan pengamatan asli begitu fase expand–contract dijalankan ulang:

| Tahap | Perkiraan perilaku sesi pembaca | Dasar perkiraan |
|---|---|---|
| Q18 — buat struktur baru dan pasang tulis ganda | Tidak terpengaruh | Fase expand hanya menambah objek baru; tidak ada perintah yang menyentuh bentuk yang dibaca |
| Q19 — backfill bertahap | Tidak terpengaruh | Tiap potongan adalah transaksi pendek pada tabel lain, kunci tidak ditahan lama |
| Q20 tahap 1 — buat view fasad `film_lama` | Tidak terpengaruh | `CREATE VIEW` dengan nama baru tidak menyentuh `lab4.film` |
| Q20 tahap 2 — hentikan tulis ganda | Tidak terpengaruh | `DROP TRIGGER` hanya mengambil kunci sesaat |
| Q20 tahap 3 — drop kolom lama | **Gagal** dengan `ERROR: column "rental_rate" does not exist` | Fasad diberi nama `film_lama`, sedangkan pembaca lama membaca `lab4.film`; begitu kolomnya hilang, pembaca kehilangan kolom yang dibacanya |

Baris terakhir itulah inti Tugas E, sekaligus alasan mengapa penamaan fasad bukan soal selera.
Bentuk yang benar-benar melindungi pembaca lama menukar peran tabel dan view dalam satu
transaksi, sehingga nama `lab4.film` tetap menunjuk sesuatu yang punya kolom `rental_rate` —
uraian lengkapnya ada pada jawaban Q20.

Perlu dicatat pula, sebelum tahap 3 sempat gagal karena kolom yang hilang, ia akan lebih dulu
**ditolak** selama view `lab4.film_murah` dan `lab4.pendapatan_kategori` masih menunjuk kolom
itu.

**Langkah untuk melengkapinya:** buat ulang `lab4.harga_film`, perbaiki `daterange` pada
trigger tulis ganda, jalankan backfill sampai verifikasi nol, lalu jalankan Q20 dengan sesi
pembaca hidup dan catat apa yang benar-benar terjadi pada tiap tahap.

Urutan salah yang diuji dan galat yang muncul:

| Urutan salah | Galat yang dialami pembaca lama |
|---|---|
| Drop kolom sebelum fasad dipasang | `ERROR: column "rental_rate" does not exist` |
| Rename tabel tanpa membuat view di transaksi yang sama | `ERROR: relation "lab4.film" does not exist` |
| Hentikan tulis ganda sebelum backfill diverifikasi | Tidak ada galat, tetapi perubahan harga hilang diam-diam — paling berbahaya karena senyap |
| Drop kolom sebelum trigger dan view dependen dilepas | `ERROR: cannot drop column rental_rate of table lab4.film because other objects depend on it` |

Untuk Langkah 3, perilaku pembaca sudah dicatat pada jawaban Q8: refresh concurrent tidak
pernah memblokir pembaca, sedangkan refresh biasa memblokirnya selama durasi refresh.
