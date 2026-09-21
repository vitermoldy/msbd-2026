# Laporan Latihan Kelompok Pertemuan 5

**Dari Procedure sampai Endpoint: PL/pgSQL, psycopg 3, Connection Pool, SQLAlchemy, N+1, FastAPI**

| | |
|---|---|
| Mata kuliah | TIF2104 — Manajemen Sistem Basis Data |
| Pertemuan | 5 — Pemrograman Basis Data |
| Basis data | Pagila pada PostgreSQL 17, skema kerja `lab5` |
| Cabang | `latihan/p05-programming` |
| Repositori | https://github.com/vitermoldy/msbd-2026 |
| Merge request | «belum dibuka — isi tautan setelah pull request dibuat» |
| Versi PostgreSQL | PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, 64-bit |
| Lingkungan Python | Python 3.14 · psycopg 3.2.13 · SQLAlchemy 2.0.54 · FastAPI 0.115.14 |
| Tanggal pengerjaan | 22 September 2026 – … |

> **Status laporan.** Bagian yang sudah terisi dengan keluaran asli: Q0 (setup), Q16–Q20,
> Refleksi D, dan Ringkasan N+1. Bagian lain ditandai «Belum diisi» beserta penanggung jawab
> dan bukti yang wajib dicantumkan. Tidak ada kotak yang diisi dengan angka perkiraan.
>
> Yang masih harus dilengkapi sebelum pengumpulan: Q1–Q15, Q21–Q24, Refleksi A, B, C, dan E,
> tabel Di Mana Aturan Itu Tinggal (R1), commit keempat anggota lain, dan tautan merge request.

---

## Anggota dan Kontribusi

| Nama | NIM | Kontribusi | Commit |
|---|---|---|---|
| Viter Moldy Kesuma | 251402079 | Langkah 1 — `q00_setup.sql` dan verifikasi lingkungan · Langkah 5 — `lab5_orm.py`, Q16–Q20, Refleksi D · `README.md` · kerangka `laporan.md` | [`0d57034`](https://github.com/vitermoldy/msbd-2026/commit/0d57034e5018fd2f3b3e5b8ffa6d327033260839) · [`ba18fc9`](https://github.com/vitermoldy/msbd-2026/commit/ba18fc926d6576f68628a449f2b6e64fd1628502) · [`994a5c9`](https://github.com/vitermoldy/msbd-2026/commit/994a5c9ecfcdc123d7f4d38a0c010c501a1c8b5d) |
| Nadine Tantiara Hutagaol | 251402050 | Langkah 2 — PL/pgSQL dan batas transaksi, `q01`–`q05`, Refleksi A | «belum ada commit» |
| Siti Naifah Batubara | 251402067 | Langkah 3 — tipe data, `q06`–`q09`, Refleksi B | «belum ada commit» |
| Gideon Finsus Siburian | 251402038 | Langkah 4 — psycopg 3, `lab5_driver.py`, `q11_uji_injeksi.py`, Q10–Q15, Refleksi C | «belum ada commit» |
| Rizky Cristian Fero Sihombing | 251402056 | Langkah 6 — FastAPI, `lab5_api.py`, Q21–Q24, Refleksi E | «belum ada commit» |

Soal mensyaratkan **setiap anggota memiliki commit yang dapat ditelusuri**. Setiap anggota
menambahkan tautan commit-nya sendiri pada kolom terakhir setelah push.

Langkah 7 (R1 — Di Mana Aturan Itu Tinggal) belum dibagi ke anggota tertentu.

---

## Q1–Q24

Seluruh berkas jawaban berada di `latihan/p05/`. Berkas SQL dijalankan dari akar repositori
melalui Git Bash dengan pola:

```bash
psqlf() { docker compose exec -T postgres psql -U msbd -d pagila -e < "$1"; }
psqlf latihan/p05/<berkas>.sql 2>&1 | tee latihan/p05/bukti/<berkas>.txt
```

Opsi `-e` menggemakan setiap pernyataan sebelum hasilnya, sehingga galat tercatat
berdampingan dengan pernyataan penyebabnya. `ON_ERROR_STOP` sengaja tidak dipakai karena
Q3–Q7 memang dirancang memicu galat di tengah berkas dan sisa pernyataannya masih harus
dijalankan.

Program Python dijalankan dari `latihan/p05` dengan venv aktif dan variabel `DSN` terisi
(lihat `README.md`).

### Q0 — `q00_setup.sql` · Menyiapkan lingkungan lab

*Penanggung jawab: Viter*

**Perintah**

```bash
docker compose up -d
docker compose ps
python -m venv .venv
source .venv/Scripts/activate
pip install "psycopg[binary,pool]==3.2.*" "sqlalchemy==2.0.*" \
  "fastapi==0.115.*" "uvicorn==0.32.*" "pydantic==2.*"
python -c "import psycopg, sqlalchemy, fastapi; print(psycopg.__version__, sqlalchemy.__version__, fastapi.__version__)"
docker compose exec -T postgres psql -U msbd -d pagila -e < latihan/p05/q00_setup.sql
```

**Keluaran** (`bukti/q00.txt`, pernyataan yang digemakan `-e` dipangkas)

```text
NOTICE:  schema "lab5" does not exist, skipping
DROP SCHEMA
CREATE SCHEMA
CREATE TYPE
CREATE DOMAIN
CREATE TABLE
CREATE TABLE
                                                       version
----------------------------------------------------------------------------------------------------------------------
 PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(1 row)

 jumlah_customer
-----------------
             599
(1 row)

          List of relations
 Schema |    Name    | Type  | Owner
--------+------------+-------+-------
 lab5   | payment_tx | table | msbd
 lab5   | rental_tx  | table | msbd
(2 rows)
```

`bukti/versi_python.txt`:

```text
3.2.13 2.0.54 0.115.14
```

| Komponen | Versi / nilai |
|---|---|
| PostgreSQL | 17.11 |
| Python | 3.14 |
| psycopg | 3.2.13 |
| SQLAlchemy | 2.0.54 |
| FastAPI | 0.115.14 |
| Jumlah customer (`pagila`) | 599 |

**Alasan keputusan.** Seluruh percobaan ditempatkan pada skema terpisah `lab5`, dan setup
diawali `DROP SCHEMA IF EXISTS lab5 CASCADE` supaya dapat diulang dari keadaan bersih tanpa
menyentuh skema `public`. Skema dibuat di basis data **`pagila`**, bukan di basis data
bawaan kontainer (`latihan`). Tabel `lab5.rental_tx` memasang foreign key ke
`public.customer`, `public.inventory`, dan `public.staff`, dan PostgreSQL tidak mendukung
foreign key lintas basis data. Pemeriksaan awal menunjukkan basis data `latihan` kosong:

```text
ERROR:  relation "public.customer" does not exist
```

Alternatif yang tidak dipakai: membuat tabel langsung di `public` (ditolak karena mencampur
objek latihan dengan data Pagila asli), dan memakai basis data `latihan` (tidak mungkin karena
foreign key lintas basis data tidak didukung).

**Catatan lingkungan.** Tiga kendala muncul saat setup, dan ketiganya diselesaikan sebelum
soal berikutnya dikerjakan:

1. **Venv tidak terbentuk.** `python -m venv .venv` terputus (`KeyboardInterrupt`) saat
   menjalankan `ensurepip`, sehingga `.venv/Scripts/activate` tidak pernah dibuat, dan
   `pip install` berikutnya masuk ke Python global. Folder `.venv` dihapus lalu dibuat ulang.
   `which python` kemudian menunjuk ke `/c/msbd-2026/.venv/Scripts/python`, dan paket
   dipasang ulang di dalam venv. `.venv/` dan `__pycache__/` ditambahkan ke `.gitignore`.
2. **Basis data salah.** Basis data bawaan kontainer (`POSTGRES_DB=latihan`) kosong. Data
   Pagila berada di basis data `pagila`, sehingga seluruh percobaan memakai `pagila`.
3. **Autentikasi Python ditolak.** psql yang dijalankan di dalam kontainer terhubung tanpa
   password, sedangkan Python terhubung dari Windows lewat `localhost:5432` dan ditolak
   dengan `password authentication failed for user "msbd"`. DSN kemudian dibentuk dari
   `POSTGRES_PASSWORD` milik kontainer, dengan password yang di-URL-encode, sehingga tidak
   ada salah ketik maupun karakter khusus yang merusak URL.

---

### Q1 — `q01_total_dibayar.sql` · Function total pembayaran

> «Belum diisi — Nadine.» Cantumkan isi function `lab5.total_dibayar`, hasil pemanggilan
> `SELECT lab5.total_dibayar(...)`, dan alasan memilih `LANGUAGE sql STABLE` + `coalesce`.

### Q2 — `q02_process_rental.sql` · Procedure `process_rental`

> «Belum diisi — Nadine.» Cantumkan isi procedure, jumlah baris `rental_tx` dan `payment_tx`
> sebelum dan sesudah satu `CALL`, serta hasil join keduanya.

### Q3 — `q03_buktikan_rollback.sql` · Rollback karena pembayaran negatif

> «Belum diisi — Nadine.» Cantumkan galat utuh beserta SQLSTATE, jumlah `rental_tx` sebelum
> dan sesudah, serta penjelasan mengapa jumlahnya tidak bertambah.

### Q4 — `q04_commit_dalam_procedure.sql` · COMMIT di dalam procedure

> «Belum diisi — Nadine.» Cantumkan salinan procedure dengan `COMMIT`, kode Python pemanggil
> di dalam `with psycopg.connect(...)`, galat yang muncul, dan penjelasan sebabnya.

### Q5 — `q05_exception_fk.sql` · Menangkap `foreign_key_violation`

> «Belum diisi — Nadine.» Cantumkan galat sebelum dan sesudah ditangkap, informasi yang
> hilang setelah galat ditangkap, dan kapan penangkapan seperti itu layak dilakukan.

### Q6 — `q06_domain_positive_amount.sql` · Domain menolak nol dan negatif

> «Belum diisi — Naifah.» Cantumkan dua pesan galat beserta SQLSTATE-nya.

### Q7 — `q07_enum_status.sql` · Menambah nilai enum

> «Belum diisi — Naifah.» Cantumkan galat saat mengisi `EXPIRED`, perintah
> `ALTER TYPE ... ADD VALUE`, dan hasil percobaan ulang.

### Q8 — `q08_tags_array.sql` · Array `tags`

> «Belum diisi — Naifah.» Cantumkan `UPDATE` tiga nilai dan hasil pencarian dengan operator
> array.

### Q9 — `q09_metadata_jsonb.sql` · JSONB `metadata`

> «Belum diisi — Naifah.» Cantumkan `UPDATE` JSONB dan hasil pengambilan `channel` dengan
> operator JSONB.

### Q10 — `lab5_driver.py` · SELECT berparameter

> «Belum diisi — Finsus.» Cantumkan potongan kode dengan placeholder `%s` dan hasilnya.

### Q11 — `q11_uji_injeksi.py` · Uji injeksi

> «Belum diisi — Finsus.» Cantumkan SQL hasil f-string yang hanya dicetak (tidak
> dijalankan), serta hasil versi berparameter dengan payload `SMITH' OR '1'='1` yang harus
> kosong.

### Q12 — Identifier dan allow-list

> «Belum diisi — Finsus.» Cantumkan galat saat nama kolom `ORDER BY` dikirim sebagai
> parameter nilai, lalu kode perbaikan dengan `sql.Identifier` dan allow-list.

### Q13 — Rollback dari aplikasi

> «Belum diisi — Finsus.» Cantumkan jumlah baris sebelum dan sesudah, serta penjelasan
> rollback.

### Q14 — `ConnectionPool`

> «Belum diisi — Finsus.» Cantumkan keluaran `pool.get_stats()` setelah lima permintaan
> berurutan pada pool berukuran 2.

### Q15 — Idle in transaction

> «Belum diisi — Finsus.» Cantumkan baris `pg_stat_activity` yang menunjukkan
> `idle in transaction`.

---

### Q16 — `lab5_orm.py` · Model deklaratif

*Penanggung jawab: Viter*

```python
class Base(DeclarativeBase):
    pass


class Customer(Base):
    __tablename__ = "customer"
    __table_args__ = {"schema": "public"}

    customer_id: Mapped[int] = mapped_column(primary_key=True)
    first_name: Mapped[str]
    last_name: Mapped[str]
    email: Mapped[str | None]

    rentals: Mapped[list["Rental"]] = relationship(back_populates="customer")


class Rental(Base):
    __tablename__ = "rental"
    __table_args__ = {"schema": "public"}

    rental_id: Mapped[int] = mapped_column(primary_key=True)
    rental_date: Mapped[datetime]
    return_date: Mapped[datetime | None]
    customer_id: Mapped[int] = mapped_column(ForeignKey("public.customer.customer_id"))
    inventory_id: Mapped[int] = mapped_column(ForeignKey("public.inventory.inventory_id"))

    customer: Mapped[Customer] = relationship(back_populates="rentals")
    inventory: Mapped[Inventory] = relationship()
```

Engine dibuat dengan `create_engine(URL, echo=True)` dan driver `postgresql+psycopg`. Sebuah
listener `before_cursor_execute` menghitung setiap statement `SELECT` yang benar-benar
dikirim ke basis data, lalu mencetak jumlahnya di akhir setiap soal.

**Alasan keputusan.** Gaya `Mapped[...]` + `mapped_column` pada SQLAlchemy 2.0 membuat tipe
setiap atribut terbaca oleh editor dan pemeriksa tipe, dan kolom yang boleh kosong diturunkan
langsung dari `str | None`. Relasi dibuat dua arah dengan `back_populates`. Hanya kolom yang
dipakai soal yang dipetakan. `Inventory` dan `Film` ditambahkan untuk kebutuhan Q20.

Alternatif yang tidak dipakai: gaya klasik `Column(...)` tanpa anotasi (tipe tidak terbaca
editor), dan refleksi otomatis `automap` (relasi dan nama atribut tidak terlihat di kode
sehingga sulit ditinjau).

### Q17 — Bukti N+1 → **11 statement**

**Perintah**

```bash
python lab5_orm.py q17 2>&1 | tee bukti/q17.txt
```

**Keluaran** (`bukti/q17.txt`, dipangkas)

```text
SELECT public.customer.customer_id, public.customer.first_name, public.customer.last_name, public.customer.email
FROM public.customer ORDER BY public.customer.customer_id
 LIMIT %(param_1)s::INTEGER
[generated in 0.00011s] {'param_1': 10}
SELECT public.rental.rental_id AS public_rental_rental_id, ... FROM public.rental
WHERE %(param_1)s::INTEGER = public.rental.customer_id
[generated in 0.00012s] {'param_1': 1}
SELECT public.rental.rental_id AS public_rental_rental_id, ... FROM public.rental
WHERE %(param_1)s::INTEGER = public.rental.customer_id
[cached since 0.01348s ago] {'param_1': 2}
... (pola yang sama berulang untuk param_1 = 3 sampai 10)
[(1, 32), (2, 27), (3, 26), (4, 22), (5, 38), (6, 28), (7, 33), (8, 24), (9, 23), (10, 25)]

>>> Q17: 11 statement SELECT
```

**Penafsiran.** 1 SELECT customer ditambah 10 SELECT rental (satu untuk setiap `c.rentals`
yang diakses) = 11. Label `[cached since …]` menunjukkan statement yang sama persis dikirim
ulang dengan parameter berbeda. Jumlah perjalanan ke basis data tumbuh linear terhadap jumlah
customer (1 + N). Tiga baris pertama log (`select pg_catalog.version()`,
`select current_schema()`, `show standard_conforming_strings`) adalah inisialisasi dialek
SQLAlchemy dan tidak ikut dihitung.

### Q18 — `selectinload` → **2 statement**

**Perintah**

```python
rows = session.scalars(
    select(Customer).options(selectinload(Customer.rentals))
    .order_by(Customer.customer_id).limit(10)
).all()
print([(c.customer_id, len(c.rentals)) for c in rows])
```

**Keluaran** (`bukti/q18.txt`)

```text
SELECT public.customer.customer_id, public.customer.first_name, public.customer.last_name, public.customer.email
FROM public.customer ORDER BY public.customer.customer_id
 LIMIT %(param_1)s::INTEGER
[generated in 0.00010s] {'param_1': 10}
SELECT public.rental.customer_id AS public_rental_customer_id, public.rental.rental_id AS public_rental_rental_id, public.rental.rental_date AS public_rental_rental_date, public.rental.return_date AS public_rental_return_date, public.rental.inventory_id AS public_rental_inventory_id
FROM public.rental
WHERE public.rental.customer_id IN (%(primary_keys_1)s::INTEGER, %(primary_keys_2)s::INTEGER, ..., %(primary_keys_10)s::INTEGER)
[generated in 0.00013s] {'primary_keys_1': 1, 'primary_keys_2': 2, ..., 'primary_keys_10': 10}
[(1, 32), (2, 27), (3, 26), (4, 22), (5, 38), (6, 28), (7, 33), (8, 24), (9, 23), (10, 25)]

>>> Q18: 2 statement SELECT
```

**Penafsiran.** Seluruh rental dari sepuluh customer dimuat sekaligus dengan satu
`WHERE customer_id IN (...)`. Hasilnya identik dengan Q17, tetapi jumlah statement turun dari
11 menjadi 2. Jumlah ini tetap 2 sampai 500 customer, karena SQLAlchemy memecah daftar `IN`
per 500 kunci; di atas itu jumlahnya menjadi 1 + ⌈N/500⌉, tetap jauh di bawah 1 + N.

### Q19 — `joinedload` → **1 statement**

**Perintah**

```python
rows = session.scalars(
    select(Customer).options(joinedload(Customer.rentals))
    .order_by(Customer.customer_id).limit(10)
).unique().all()
```

**Keluaran** (`bukti/q19.txt`)

```text
SELECT anon_1.customer_id, anon_1.first_name, anon_1.last_name, anon_1.email, rental_1.rental_id, rental_1.rental_date, rental_1.return_date, rental_1.customer_id AS customer_id_1, rental_1.inventory_id
FROM (SELECT public.customer.customer_id AS customer_id, public.customer.first_name AS first_name, public.customer.last_name AS last_name, public.customer.email AS email
FROM public.customer ORDER BY public.customer.customer_id
 LIMIT %(param_1)s::INTEGER) AS anon_1 LEFT OUTER JOIN public.rental AS rental_1 ON anon_1.customer_id = rental_1.customer_id ORDER BY anon_1.customer_id
[generated in 0.00013s] {'param_1': 10}
[(1, 32), (2, 27), (3, 26), (4, 22), (5, 38), (6, 28), (7, 33), (8, 24), (9, 23), (10, 25)]

>>> Q19: 1 statement SELECT
```

**Perbandingan dengan Q18.** Log menunjukkan `selectinload` (Q18) mengirim dua SELECT terpisah, yaitu customer `LIMIT 10` lalu rental `WHERE customer_id IN (10 id)`, sedangkan `joinedload` (Q19) mengirim satu SELECT yang membungkus customer `LIMIT 10` sebagai subquery `anon_1` lalu `LEFT OUTER JOIN` ke `rental`, sehingga data customer terulang di 278 baris dan hasilnya wajib dirapikan dengan `.unique()`.

### Q20 — ORM dibanding SQL mentah · Lima film tersewa terbanyak

**Versi ORM**

```python
jumlah = func.count(Rental.rental_id).label("jumlah_sewa")
stmt = (
    select(Film.title, jumlah)
    .join(Inventory, Inventory.film_id == Film.film_id)
    .join(Rental, Rental.inventory_id == Inventory.inventory_id)
    .group_by(Film.film_id, Film.title)
    .order_by(desc(jumlah), Film.title)
    .limit(5)
)
```

SQL yang dihasilkan ORM (`bukti/q20.txt`):

```text
SELECT public.film.title, count(public.rental.rental_id) AS jumlah_sewa
FROM public.film JOIN public.inventory ON public.inventory.film_id = public.film.film_id JOIN public.rental ON public.rental.inventory_id = public.inventory.inventory_id GROUP BY public.film.film_id, public.film.title ORDER BY jumlah_sewa DESC, public.film.title
 LIMIT %(param_1)s::INTEGER
```

**Versi SQL mentah** (dijalankan lewat `session.execute(text(...))`)

```sql
SELECT f.title, count(r.rental_id) AS jumlah_sewa
FROM public.rental r
JOIN public.inventory i ON i.inventory_id = r.inventory_id
JOIN public.film f      ON f.film_id = i.film_id
GROUP BY f.film_id, f.title
ORDER BY jumlah_sewa DESC, f.title
LIMIT 5;
```

**Keluaran** (`bukti/q20.txt`)

```text
ORM   : [('BUCKET BROTHERHOOD', 34), ('ROCKETEER MOTHER', 33), ('FORWARD TEMPLE', 32), ('GRIT CLOCKWORK', 32), ('JUGGLER HARDLY', 32)]
Mentah: [('BUCKET BROTHERHOOD', 34), ('ROCKETEER MOTHER', 33), ('FORWARD TEMPLE', 32), ('GRIT CLOCKWORK', 32), ('JUGGLER HARDLY', 32)]
Hasil sama: True
ORM       : median 3.79 ms (min 3.32, maks 4.32) dari 30 kali
SQL mentah: median 3.45 ms (min 3.04, maks 4.14) dari 30 kali
```

| Versi | Median | Min | Maks |
|---|---:|---:|---:|
| ORM | 3,79 ms | 3,32 ms | 4,32 ms |
| SQL mentah | 3,45 ms | 3,04 ms | 4,14 ms |

**Cara mengukur.** Setiap versi dijalankan 30 kali setelah satu kali pemanasan, dalam satu
session, dengan `echo` dimatikan selama pengukuran supaya penulisan log tidak ikut terhitung.
Yang dilaporkan adalah median, karena median tidak terpengaruh satu dua pengukuran yang
melonjak.

**Penafsiran.** Kedua versi menghasilkan SQL yang setara dan hasil yang identik. Selisih
median 0,34 ms (sekitar 10%) adalah biaya ORM menyusun statement di sisi Python, bukan
perbedaan kerja di PostgreSQL.

---

### Q21 — `lab5_api.py` · Dependency koneksi `get_conn`

> «Belum diisi — Rizky.» Cantumkan potongan kode dependency bergaya `with` + `yield` yang
> meminjam koneksi dari pool.

### Q22 — `POST /rentals` → 201

> «Belum diisi — Rizky.» Cantumkan perintah curl dan respons berisi `rental_id`.

### Q23 — Nilai negatif → 422

> «Belum diisi — Rizky.» Cantumkan respons utuh (`curl -i`) dan tunjukkan bahwa respons tidak
> memuat SQL.

### Q24 — Inventory tidak ada → 409

> «Belum diisi — Rizky.» Cantumkan respons utuh (`curl -i`).

---

## Refleksi A–E

### Refleksi A — Siapa memulai dan mengakhiri transaksi

*Setelah Q3 dan Q4, siapa yang memulai transaksi, siapa yang mengakhirinya, dan bagaimana
kelompok membuktikannya dari data?*

> «Belum diisi — Nadine.»

### Refleksi B — `tags` atau `metadata`: tetap atau menjadi tabel

*Pilih `tags` atau `metadata`. Apakah sebaiknya tetap di sana atau dipindahkan menjadi
tabel? Berikan satu pertanyaan bisnis yang dapat mengubah keputusan tersebut.*

> «Belum diisi — Naifah.»

### Refleksi C — Rollback dari basis data lawan rollback dari Python

*Bandingkan rollback Q3 yang dipicu basis data dan Q13 yang dipicu Python. Apa persamaannya,
dan apa satu hal yang hanya dapat dilakukan sisi aplikasi?*

> «Belum diisi — Finsus.»

### Refleksi D — ORM lawan SQL mentah, `joinedload` lawan `selectinload`

*Untuk Q20, versi mana yang dipilih jika kode dibaca ulang tim enam bulan lagi? Dukung
jawaban dengan angka. Sebutkan pula keadaan ketika `joinedload` lebih tepat dari
`selectinload`.*

**Versi yang dipilih: SQL mentah.** Dari sisi kecepatan, kedua versi praktis setara. Median
ORM 3,79 ms dan SQL mentah 3,45 ms, selisih 0,34 ms per panggilan, sehingga dibutuhkan
sekitar 3.000 panggilan hanya untuk menambah satu detik. Rentang min–maks keduanya pun saling
bertumpuk (3,32–4,32 ms dan 3,04–4,14 ms). Karena kecepatan bukan pembeda, yang menentukan
adalah keterbacaan:

1. **Bentuknya sama dengan yang dijalankan.** Query analitik dengan tiga tabel, `GROUP BY`,
   dan urutan berdasarkan alias terbaca apa adanya dalam SQL. Versi ORM menuntut pembaca
   memahami trik `func.count(...).label("jumlah_sewa")` lalu `desc(jumlah)` untuk
   mengurutkan berdasarkan alias tersebut.
2. **Bisa langsung diperiksa.** Versi SQL dapat disalin ke psql untuk `EXPLAIN ANALYZE`
   tanpa diterjemahkan dulu, sedangkan versi ORM harus dijalankan dengan `echo=True` untuk
   melihat SQL yang sebenarnya dikirim.

Risikonya, SQL mentah tidak ikut diperiksa ketika model berubah. Kalau atribut model diganti
nama, editor dan pemeriksa tipe langsung menandai versi ORM, dan pemanggilannya gagal dengan
`AttributeError` yang jelas. Sebaliknya, string SQL tidak diperiksa siapa pun dan baru gagal
di basis data saat query dijalankan. Karena itu query analitik diletakkan di satu tempat (konstanta `SQL_MENTAH`) dan
sebaiknya dilindungi satu tes yang memeriksa hasilnya. Untuk operasi CRUD sehari-hari tim
tetap memakai ORM.

**Kapan `joinedload` lebih tepat dari `selectinload`:**

1. **Relasi many-to-one atau one-to-one**, misalnya `Rental.customer`. Setiap rental hanya
   punya satu customer, sehingga JOIN tidak menggandakan baris dan satu query sudah cukup.
   Dengan `selectinload`, query kedua hanya menambah satu perjalanan tanpa manfaat.
2. **Koleksi kecil dan terbatas pada jaringan berlatensi tinggi**, ketika menghemat satu
   perjalanan pulang-pergi ke basis data lebih berharga daripada sedikit baris ganda.

Untuk koleksi one-to-many yang besar seperti `Customer.rentals`, `selectinload` lebih tepat.
Q19 menunjukkan `joinedload` mengirim 278 baris berisi data customer yang berulang hanya
untuk 10 customer, dan jumlah itu akan membengkak sebanding dengan banyaknya rental per
customer.

### Refleksi E — Validasi di Pydantic dan di domain basis data

*Untuk nilai negatif, validasi dipasang di Pydantic dan domain basis data. Jelaskan apa yang
hilang jika salah satunya dihapus, untuk kedua arah.*

> «Belum diisi — Rizky.»

---

## Di Mana Aturan Itu Tinggal

> «Belum diisi — Langkah 7 belum dibagi.» Soal meminta tiga aturan; tiap baris wajib memuat
> satu bukti dari percobaan kelompok. Contoh aturan dari soal beserta soal yang menjadi
> sumber buktinya:
>
> - pembayaran positif: Q6 dan Q23;
> - rental dan pembayaran atomik: Q3, Q4, dan Q13;
> - klien tidak melihat SQL: Q23 dan Q24.

| Aturan | Lapisan | Risiko bila dipindahkan | Bukti |
|---|---|---|---|
| | | | |
| | | | |
| | | | |

---

## Ringkasan N+1

| Q17 | Q18 | Q19 | Penafsiran |
|---:|---:|---:|---|
| 11 | 2 | 1 | Lazy loading = 1 + N: satu SELECT customer ditambah satu SELECT rental untuk setiap customer (N = 10), dan jumlahnya tumbuh linear terhadap N. `selectinload` = 1 + 1: relasi dimuat sekaligus dengan `WHERE customer_id IN (...)`, tetap 2 selama N ≤ 500. `joinedload` = 1 query `LEFT OUTER JOIN` terhadap subquery `LIMIT 10`, tetapi menghasilkan 278 baris untuk 10 customer sehingga perlu `.unique()`. |

Sumber: baris `>>> Q17/Q18/Q19` pada `bukti/q17.txt`, `bukti/q18.txt`, dan `bukti/q19.txt`,
dicocokkan dengan jumlah baris `SELECT` pada log `echo=True` di berkas yang sama.

---

## Penggunaan AI dan Verifikasi

**Viter (Langkah 1, Langkah 5, `README.md`, kerangka laporan).** Draf `q00_setup.sql`,
`lab5_orm.py`, `README.md`, dan kerangka laporan ini disusun dengan bantuan Claude
(Anthropic). Verifikasi yang dilakukan:

- seluruh berkas dijalankan ulang di laptop sendiri (PostgreSQL 17.11 di Docker, Python 3.14),
  dan keluarannya disimpan apa adanya di `bukti/`;
- hitungan statement 11 / 2 / 1 dicocokkan dengan jumlah baris `SELECT` pada log
  `echo=True`, bukan hanya dengan angka yang dicetak penghitung;
- kesamaan hasil ORM dan SQL mentah diperiksa oleh program (`Hasil sama: True`);
- angka pada laporan disalin dari berkas `bukti/`, bukan dari contoh keluaran bantuan AI;
- tiga kendala lingkungan (venv terputus, basis data `latihan` kosong, dan autentikasi DSN)
  ditelusuri dari pesan galat masing-masing lalu diperbaiki sebelum soal dikerjakan.

**Nadine (Langkah 2).** «Belum diisi.»

**Naifah (Langkah 3).** «Belum diisi.»

**Finsus (Langkah 4).** «Belum diisi.»

**Rizky (Langkah 6).** «Belum diisi.»
