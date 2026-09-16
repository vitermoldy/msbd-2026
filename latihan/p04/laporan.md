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
| Nadine Tantiara Hutagaol | 251402050 | Langkah 5 — constraint Q14–Q17, Refleksi D | [`1fa0863`](https://github.com/vitermoldy/msbd-2026/commit/1fa0863a075b0d6de11be7ffc11ed529e6d6c31a) · [`306f913`](https://github.com/vitermoldy/msbd-2026/commit/306f913279537bd6606987ac4ff6d5bbea002971) · [`fe12dc9`](https://github.com/vitermoldy/msbd-2026/commit/fe12dc9c8688d7570a52494c17eb3b87de4dda69) · [`36ce89d`](https://github.com/vitermoldy/msbd-2026/commit/36ce89dd6cb555d1cdd6068f3804964e3b6c6a1c) · [`092855f`](https://github.com/vitermoldy/msbd-2026/commit/092855f14ccb2605943c84749cd6f0e4e297642b) |
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
**Alasan keputusan.** Klausa `AFTER UPDATE OF rental_rate` digunakan untuk menghindari
*overhead* eksekusi yang tidak perlu ketika terjadi perubahan pada kolom selain harga sewa.
Selain itu, penggunaan operator `IS DISTINCT FROM` diterapkan untuk menjamin perbandingan nilai
lama dan nilai baru tetap konsisten serta aman dari potensi masalah nilai `NULL` (*NULL-safe*).

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
**Alasan keputusan.** Pengujian ini dilakukan untuk memverifikasi efektivitas filter kondisi
pada *trigger* secara langsung:
* **Uji 1:** Memastikan *log* audit berhasil dicatat ketika terjadi perubahan harga sewa yang valid.
* **Uji 2:** Membuktikan bahwa filter `WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)` mampu
  menahan pencatatan *log* redundant saat nilai harga baru sama dengan nilai lama.
* **Uji 3:** Membuktikan klausa `AFTER UPDATE OF rental_rate` tidak memicu *trigger* jika pembaruan data hanya terjadi pada kolom lain (seperti `title`).


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

Aturan periode harga sebenarnya bisa dibuat menggunakan trigger yang mengecek dulu data di tabel sebelum melakukan `INSERT`. Masalahnya muncul ketika **dua transaksi berjalan secara bersamaan**. Kedua transaksi bisa sama-sama mengecek tabel saat data dari transaksi lainnya belum masuk, sehingga keduanya menganggap tidak ada periode yang bentrok.

Akibatnya, **kedua data bisa berhasil masuk**, padahal kalau dilihat bersamaan periodenya ternyata saling tumpang tindih.

Berbeda dengan trigger, `EXCLUDE` menjadi **aturan langsung pada tabel**. PostgreSQL akan mengecek aturan tersebut ketika data dimasukkan dan menangani kondisi transaksi yang berjalan bersamaan. Jadi data dengan `film_id`, wilayah, dan periode yang saling bertabrakan tetap dapat dicegah masuk.

Menurut saya, `EXCLUDE` lebih aman untuk kasus ini karena aturan tidak tumpang tindih **langsung dijaga oleh database**, bukan hanya berdasarkan pengecekan dari trigger.

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
| Q14 — CHECK NOT VALID | `1fa0863` | https://github.com/vitermoldy/msbd-2026/commit/1fa0863a075b0d6de11be7ffc11ed529e6d6c31a |
| Q15 — UNIQUE & soft delete | `306f913` | https://github.com/vitermoldy/msbd-2026/commit/306f913279537bd6606987ac4ff6d5bbea002971 |
| Q16 — Foreign Key | `fe12dc9` | https://github.com/vitermoldy/msbd-2026/commit/fe12dc9c8688d7570a52494c17eb3b87de4dda69 |
| Q17 — EXCLUDE | `36ce89d` | https://github.com/vitermoldy/msbd-2026/commit/36ce89dd6cb555d1cdd6068f3804964e3b6c6a1c |
| Q18–Q21 — expand–contract dan migrasi (Finsus) | «menyusul» | |

Seluruh commit berada di cabang `latihan/p04-sql2`.

### Catatan sesi pembaca

Sesi pembaca pada Langkah 6 (Q18–Q20) belum dijalankan. Bagian ini diisi setelah fase
expand–contract dikerjakan, memuat tahap mana yang sempat membuat pembaca menunggu, tahap
mana yang membuatnya gagal, dan urutan salah yang diuji beserta galatnya.

Untuk Langkah 3, perilaku pembaca sudah dicatat pada jawaban Q8: refresh concurrent tidak
pernah memblokir pembaca, sedangkan refresh biasa memblokirnya selama durasi refresh.
