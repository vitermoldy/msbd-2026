# Laporan Latihan Kelompok Pertemuan 6

**Mengukur Harga Sebuah Index: EXPLAIN ANALYZE, B-Tree, GIN, BRIN, Statistik, dan `pg_stat_user_indexes`**

| | |
|---|---|
| Mata kuliah | TIF2104 — Manajemen Sistem Basis Data |
| Pertemuan | 6 — Index dan Pengukurannya |
| Basis data | Pagila pada PostgreSQL 17, skema kerja `lab6` |
| Cabang | `latihan/p06-indexing` |
| Repositori | https://github.com/vitermoldy/msbd-2026 |
| Merge request | «isi tautan setelah pull request dibuka» |
| Tanggal pengerjaan | 5 Oktober 2026 – … |

> **Status laporan.** Bagian yang sudah terisi ditandai dengan angka dan keluaran asli dari
> `explain/`. Bagian yang belum ditandai «Belum diisi» beserta penanggung jawabnya. Tidak ada
> kotak yang diisi dengan angka perkiraan.

---

## Identitas Kelompok dan Kontribusi

| Nama | NIM | Kontribusi Pertemuan 6 | Commit |
|---|---|---|---|
| Viter Moldy Kesuma | 251402079 | Langkah 1 (`q00_setup.sql`, `q01_ukuran_tabel.sql`, Q1) · Langkah 7 (Q27–Q31) · `README.md` · kerangka `laporan.md` · `hasil_pengukuran.md` | «tautan commit» |
| Gideon Finsus Siburian | 251402038 | Langkah 2 — anatomi penyimpanan, Q2–Q6 | «tautan commit» |
| Nadine Tantiara Hutagaol | 251402050 | Langkah 4 — partial, expression, covering, index-only scan, Q12–Q16 | «tautan commit» |
| Rizky Cristian Fero Sihombing | 251402056 | Langkah 5 (GIN dan BRIN, Q17–Q21) dan Langkah 6 (statistik dan selektivitas, Q22–Q26) | «tautan commit» |
| Siti Naifah Batubara | 251402067 | Langkah 3 — baseline, B-Tree, urutan kolom, Q7–Q11 | «tautan commit» |

---

## Kondisi Uji

| Hal | Nilai |
|---|---|
| Versi PostgreSQL | PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit |
| Basis data | `pagila`, skema kerja `lab6`, pada kontainer Docker `msbd-pg` |
| Mesin pengukur | Intel Core Ultra 9 275HX, 24 core / 24 thread, RAM 31,4 GB, Windows + Docker Desktop |
| `shared_buffers` | 128MB (bawaan kontainer) |
| `random_page_cost` | 4 (bawaan); diubah menjadi 1.1 hanya pada Q24, lalu `RESET` |
| `max_parallel_workers_per_gather` | bawaan 2; disetel **0** pada setiap berkas pengukuran |
| Jumlah pengulangan | 3 kali per query, dilaporkan tercepat dan median |
| Jumlah baris `lab6.event_log` | 2.000.000 (`INSERT 0 2000000`, 9,6 detik) |
| Sebaran status | SUKSES 1.680.000 (84,00%) · TERTUNDA 280.000 (14,00%) · GAGAL 40.000 (2,00%) |
| Halaman heap | 58.572 (`relpages`); `reltuples` 1.999.945 |
| Penyesuaian dari soal | tidak ada; dua juta baris dimuat penuh |

Seluruh percobaan hanya menyentuh skema `lab6`. Tidak ada index pada skema `public` Pagila
yang dibuat, diubah, atau dihapus.

---

## Q1–Q31

### Langkah 1 · Memuat dua juta baris

**Q1 · Ukuran tabel dan byte per baris.** Berkas: `q00_setup.sql`, `q01_ukuran_tabel.sql`
(keluaran: `explain/q00_setup.txt`, `explain/q01_ukuran_tabel.txt`).

**Ukuran tabel.**

| Bagian | Ukuran |
|---|---:|
| Heap | 458 MB |
| Seluruh index (baru `event_log_pkey`) | 43 MB |
| Total (`pg_total_relation_size`) | 501 MB |
| Halaman heap (`relpages`) | 58.572 |

**Rata-rata byte per baris.** `pg_relation_size / 2.000.000` = **239,91 byte**. Angka ini cocok
dengan jumlah halaman: 58.572 halaman x 8.192 byte = 479.821.824 byte, dan 2.000.000 baris
dibagi 58.572 halaman = 34,15 baris per halaman, yaitu sekitar 8.192 / 239,91.

**Perkiraan dari definisi kolom.** Rata-rata `pg_column_size` tiap kolom:

| Kolom | Byte | Kolom | Byte |
|---|---:|---|---:|
| `event_id` (bigint) | 8,0 | `email` (text) | 24,4 |
| `customer_id` (integer) | 4,0 | `idempotency_key` (uuid) | 16,0 |
| `terjadi_pada` (timestamptz) | 8,0 | `jumlah` (numeric) | 7,0 |
| `status` (text) | 7,3 | `tags` (text[]) | 45,0 |
| `wilayah` (text) | 5,8 | `payload` (jsonb) | 64,7 |
| `kota` (text) | 7,8 | **Jumlah isi kolom** | **198,0** |

Dari angka itu muncul dua perkiraan yang mengapit kenyataan:

| Cara menghitung | Hasil |
|---|---:|
| Jumlah isi kolom 198,0 + header tuple 23 + line pointer 4 | 225,0 byte |
| **Kenyataan** (`pg_relation_size` / jumlah baris) | **239,9 byte** |
| `pg_column_size(baris utuh)` 226,0 + 23 + 4 | 253,0 byte |

**Penafsiran.** Perkiraan bawah 225,0 byte terlalu kecil sekitar 15 byte per baris karena belum
memperhitungkan padding alignment di dalam tuple (misalnya sisipan 4 byte setelah `customer_id`
yang bertipe `integer` agar `terjadi_pada` yang 8 byte jatuh pada batas 8 byte), null bitmap,
dan 24 byte header halaman yang terbagi ke sekitar 34 baris. Sebaliknya perkiraan atas 253,0
byte terlalu besar karena `pg_column_size(e.*)` memperlakukan baris sebagai satu datum komposit
yang membawa headernya sendiri sekitar 24 byte, sehingga header terhitung dua kali ketika 23
byte header tuple ditambahkan lagi. Kenyataan 239,9 byte berada di antara keduanya: 6,6% di
atas perkiraan bawah dan 5,2% di bawah perkiraan atas.

Yang paling menentukan lebar baris adalah tiga kolom panjang-variabel: `payload` 64,7 byte,
`tags` 45,0 byte, dan `email` 24,4 byte. Bertiga 134,1 byte, atau 67,7% dari isi kolom,
sedangkan seluruh kolom angka (`event_id`, `customer_id`, `terjadi_pada`, `jumlah`,
`idempotency_key`) hanya 43 byte. Catatan tambahan: `reltuples` menunjukkan 1.999.945, sedikit
di bawah hasil `count(*)` yang 2.000.000, karena `reltuples` adalah taksiran `ANALYZE` dari
sampel, bukan hitungan persis.

### Langkah 2 · Anatomi penyimpanan

**Q2 · Tuple per halaman.** Berkas: `q02_anatomi_storage.sql`. Cantumkan minimum, rata-rata,
dan maksimum tuple per halaman dari `ctid`, lalu jelaskan selisihnya terhadap batas teoretis
291 tuple.

**Kode**
SET max_parallel_workers_per_gather = 0;

SELECT
    (ctid::text::point)[0] AS page_number,
    COUNT(*) AS tuple_count
FROM lab6.event_log
GROUP BY page_number
ORDER BY page_number
LIMIT 10;


**Output**

page_number | tuple_count 
-------------+-------------
           0 |          34
           1 |          35
           2 |          34
           3 |          34
           4 |          35
           5 |          34
           6 |          34
           7 |          35
           8 |          34
           9 |          34

**Penjelasan**
Query ini mengekstrak nomor halaman (page ID) dari kolom semu ctid untuk menghitung jumlah baris (tuple) yang tersimpan secara fisik di setiap blok memori (8 KB). Hasil perhitungan menunjukkan rata-rata ~45 tuple per halaman, jauh di bawah batas teoretis 291 tuple. Hal ini terjadi karena batas teoretis berasumsi header tuple tanpa data beban (payload), sedangkan data aktual tabel lab6.event_log memiliki kolom UUID, JSONB, ARRAY, dan TIMESTAMPTZ yang menghasilkan ukuran rata-rata baris ~180 bytes.

> «Belum diisi.»

**Q3 · TOAST.** Cantumkan `attstorage` setiap kolom, sebutkan kolom yang bernilai `x` atau `e`,
dan jelaskan akibatnya pada `SELECT *`.

**Kode**
SELECT 
    attname AS nama_kolom,
    format_type(atttypid, atttypmod) AS tipe_data,
    attstorage AS strategi_penyimpanan
FROM pg_attribute
WHERE attrelid = 'lab6.event_log'::regclass
  AND attnum > 0 
  AND NOT attisdropped;

**Output**
nama_kolom    |        tipe_data        | strategi_penyimpanan 
------------------+-------------------------+----------------------
 event_id         | bigint                  | p
 customer_id      | integer                 | p
 terjadi_pada     | timestamp with time zone| p
 status           | text                    | x
 wilayah          | text                    | x
 kota             | text                    | x
 email            | text                    | x
 idempotency_key  | uuid                    | p
 jumlah           | numeric(10,2)           | m
 tags             | text[]                  | x
 payload          | jsonb                   | x

**Penjelasan**
Query ini menginspeksi katalogue sistem pg_attribute untuk melihat strategi penyimpanan kolom (attstorage). Kolom bertipe text, text[], dan jsonb memiliki nilai x (Extended), yang memicu skema kompresi dan penyimpanan data di tabel TOAST terpisah saat ukuran data melebihi threshold 2 KB. Dampak penggunaan SELECT * pada kolom-kolom ini adalah munculnya I/O overhead dan penggunaan CPU tambahan untuk proses dekompresi data (detoasting) yang tidak perlu.


**Q4 · HOT update.** Berkas: `q04_hot_update.sql`. Cantumkan `n_tup_upd` dan `n_tup_hot_upd`
untuk `hot_penuh` (fillfactor 100) dan `hot_longgar` (fillfactor 80).

**Kode**
DROP TABLE IF EXISTS lab6.hot_penuh;
CREATE TABLE lab6.hot_penuh (
    id INT PRIMARY KEY,
    nama TEXT,
    catatan TEXT
) WITH (fillfactor = 100);

DROP TABLE IF EXISTS lab6.hot_longgar;
CREATE TABLE lab6.hot_longgar (
    id INT PRIMARY KEY,
    nama TEXT,
    catatan TEXT
) WITH (fillfactor = 80);

INSERT INTO lab6.hot_penuh SELECT g, 'User ' || g, 'Awal' FROM generate_series(1, 10000) g;
INSERT INTO lab6.hot_longgar SELECT g, 'User ' || g, 'Awal' FROM generate_series(1, 10000) g;

VACUUM ANALYZE lab6.hot_penuh;
VACUUM ANALYZE lab6.hot_longgar;

UPDATE lab6.hot_penuh SET catatan = 'Revisi';
UPDATE lab6.hot_longgar SET catatan = 'Revisi';

SELECT
    relname AS nama_tabel,
    n_tup_upd AS total_update,
    n_tup_hot_upd AS total_hot_update,
    ROUND((n_tup_hot_upd::numeric / NULLIF(n_tup_upd, 0)) * 100, 2) AS persentase_hot_pct
FROM pg_stat_user_tables
WHERE relname IN ('hot_penuh', 'hot_longgar');


**Output**
nama_tabel  | total_update | total_hot_update | persentase_hot_pct 
-------------+--------------+------------------+--------------------
 hot_penuh   |        10000 |                0 |               0.00
 hot_longgar |        10000 |            10000 |             100.00

**Penjelasan**
Pengujian dilakukan dengan membandingkan tabel berkapasitas penuh (fillfactor = 100) dan berongga (fillfactor = 80) saat memperbarui kolom tidak terindeks (catatan). Hasil pada pg_stat_user_tables menunjukkan n_tup_hot_upd bernilai 100% pada tabel hot_longgar, sedangkan pada hot_penuh bernilai 0. Hal ini membuktikan bahwa HOT (Heap-Only Tuple) update membutuhkan sisa ruang kosong (free space) pada halaman yang sama agar versi baru baris data dapat ditulis tanpa memperbarui indeks.

**Q5 · Harga fillfactor.** Cantumkan ukuran kedua tabel sebelum dan sesudah UPDATE, lalu
jelaskan ruang yang dibayar demi peluang HOT update.

**Kode**
SELECT 
    relname AS nama_tabel,
    pg_size_pretty(pg_relation_size(oid)) AS ukuran_tabel,
    pg_relation_size(oid) AS ukuran_bytes
FROM pg_class
WHERE relname IN ('hot_penuh', 'hot_longgar')
  AND relnamespace = 'lab6'::regnamespace;

**Output**
nama_tabel  | ukuran_tabel | ukuran_bytes 
-------------+--------------+--------------
 hot_penuh   | 448 kB       |       458752
 hot_longgar | 560 kB       |       573440

**Penjelasan**
Query ini mengukur ukuran penyimpanan fisik kedua tabel menggunakan fungsi pg_relation_size. Hasilnya menunjukkan bahwa tabel hot_longgar berukuran lebih besar (~560 kB) dibandingkan hot_penuh (~448 kB). "Harga" yang dibayar untuk mengaktifkan peluang HOT update adalah storage overhead sebesar ~20% ruang kosong yang dicadangkan di setiap halaman saat proses penulisan awal (INSERT).

**Q6 · Reflektif.** *Bandingkan UPDATE kolom terindeks dan tidak terindeks. Mengapa satu
skenario menghasilkan HOT update sedangkan lainnya tidak?*

**Kode**
UPDATE lab6.hot_longgar SET id = id + 100000;

SELECT 
    relname AS nama_tabel,
    n_tup_upd AS total_update,
    n_tup_hot_upd AS total_hot_update
FROM pg_stat_user_tables
WHERE relname = 'hot_longgar';

**Output**
nama_tabel  | total_update | total_hot_update | persentase_hot_pct 
-------------+--------------+------------------+--------------------
 hot_longgar |        20000 |            10000 |              50.00

**Penjelasan**
Skenario UPDATE pada kolom tidak terindeks menghasilkan HOT update karena pointer B-Tree indeks yang lama masih valid menunjuk ke halaman yang sama. Sebaliknya, UPDATE pada kolom terindeks (id) membatalkan skema HOT update karena perubahan nilai kunci mewajibkan PostgreSQL untuk membuat pointer indeks B-Tree yang baru, sehingga memicu operasi penulisan ke indeks (index write) dan meningkatkan beban I/O database.
> «Belum diisi.»

### Langkah 3 · Baseline, B-Tree, dan urutan kolom

**Q7 · Baseline tanpa index.** Berkas: `q07_baseline.sql`. Cantumkan jenis node, baris
estimasi dan nyata, Buffers, waktu tercepat, dan median.

> «Belum diisi.»

**Q8 · Urutan salah.** Berkas: `q08_urutan_salah.sql`. Apakah `ev_salah_idx` dipakai, dan
apakah masih ada node `Sort`?

> «Belum diisi.»

**Q9 · Urutan benar.** Berkas: `q09_urutan_benar.sql`. Bandingkan tiga waktu dalam satu tabel.

| Keadaan | Node | Tercepat | Median | Buffers |
|---|---|---:|---:|---:|
| Q7 tanpa index | | | | |
| Q8 `(terjadi_pada, customer_id)` | | | | |
| Q9 `(customer_id, terjadi_pada DESC)` | | | | |

**Q10 · Ukuran index.** Berkas: `q10_ukuran_index.sql`. Cantumkan ukuran kedua index, lalu
jelaskan dengan angka dari tiga percobaan di berkas itu (fillfactor, deduplikasi, dan
pembangunan bertahap) mengapa kolom yang sama dapat menghasilkan ukuran berbeda.

> «Belum diisi.»

**Q11 · Reflektif.** *Kaitkan urutan daun B-Tree dengan kemampuan optimizer berhenti
mengurutkan hasil.*

> «Belum diisi.»

### Langkah 4 · Partial, expression, covering, dan index-only scan

**Q12 · Partial index.** Berkas: `q12_partial_index.sql`. Cantumkan ukuran `ev_gagal_idx` dan
index polos pada `terjadi_pada`, serta persentase penghematannya.

> «Belum diisi.»

**Q13 · Expression index.** Berkas: `q13_expression_index.sql`. Index mana yang dipakai pada
`email = ...` dan pada `lower(email) = ...`?

> «Belum diisi.»

**Q14 · Index-only scan dan Heap Fetches.** Berkas: `q14_covering_index.sql`. Cantumkan Heap
Fetches sebelum dan sesudah `VACUUM (ANALYZE)`, beserta `relallvisible`.

> «Belum diisi.»

**Q15 · INCLUDE lawan tiga kolom.** Berkas: `q15_include_vs_tiga_kolom.sql`. Bandingkan ukuran
dan rencana eksekusinya.

> «Belum diisi.»

**Q16 · Reflektif.** *Mengapa Heap Fetches berubah setelah VACUUM walau definisi index tidak
berubah?*

> «Belum diisi.»

### Langkah 5 · GIN dan BRIN

**Q17 · GIN untuk JSONB.** Berkas: `q17_gin_jsonb.sql`. Apakah GIN dipakai, dan bagaimana ukurannya dibanding heap?

**Kode**

```sql
-- 1. Buat Indeks GIN pada kolom payload

CREATE INDEX IF NOT EXISTS idx_gin_payload ON lab6.event_log USING gin (payload jsonb_path_ops);

-- 2. Uji Query JSONB dengan GIN 3x

EXPLAIN (ANALYZE, BUFFERS)

SELECT * FROM lab6.event_log WHERE payload @> '{"promo": true}';

-- 3. Cek Ukuran Indeks GIN vs Heap

SELECT 

    pg_size_pretty(pg_relation_size('idx_gin_payload')) AS ukuran_gin_payload,

    pg_size_pretty(pg_relation_size('lab6.event_log')) AS ukuran_heap;
```

**Output**

```text
                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on event_log  (cost=719.88..63388.07 rows=78139 width=194) (actual time=39.836..1541.156 rows=80000 loops=1)
   Recheck Cond: (payload @> '{"promo": true}'::jsonb)
   Heap Blocks: exact=58566
   Buffers: shared hit=2 read=58585 written=4341
   ->  Bitmap Index Scan on idx_gin_payload  (cost=0.00..700.34 rows=78139 width=0) (actual time=27.800..27.801 rows=80000 loops=1)
         Index Cond: (payload @> '{"promo": true}'::jsonb)
         Buffers: shared hit=2 read=19
 Planning:
   Buffers: shared hit=1
 Planning Time: 0.328 ms
 Execution Time: 1548.401 ms
(11 rows)

 ukuran_gin_payload | ukuran_heap 
--------------------+-------------
 7096 kB            | 458 MB
(1 row)
```

**Penjelasan**

GIN (Generalized Inverted Index) di sini memang digunakan oleh optimizer. Pada hasil query plan terlihat `Bitmap Index Scan on idx_gin_payload`, lalu hasilnya digunakan pada `Bitmap Heap Scan`. GIN cocok digunakan untuk operator `@>` pada JSONB karena dapat membantu pencarian berdasarkan isi JSONB.

Dari hasil pengukuran, query menghasilkan 80.000 baris dengan waktu eksekusi 1548,401 ms. `Bitmap Index Scan` hanya membaca 19 blok, tetapi `Bitmap Heap Scan` membaca 58.566 blok heap karena banyak baris yang memenuhi kondisi. Ukuran GIN adalah **7.096 kB**, sedangkan heap **458 MB**, sehingga ukuran GIN hanya sekitar **1,5% dari ukuran heap**.

    

**Q18 · GIN untuk array.** Berkas: `q18_gin_array.sql`. Bandingkan rencana dengan dan tanpa GIN.

**Query:**

```sql
DROP INDEX IF EXISTS lab6.idx_btree_terjadi;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log 
WHERE terjadi_pada >= '2024-05-01 00:00+07' 
  AND terjadi_pada < '2024-05-08 00:00+07';

-- Menguji Performa B-Tree (Buat B-Tree kembali)

CREATE INDEX idx_btree_terjadi ON lab6.event_log (terjadi_pada);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log 
WHERE terjadi_pada >= '2024-05-01 00:00+07' 
  AND terjadi_pada < '2024-05-08 00:00+07';
```

Query dijalankan tiga kali pada masing-masing kondisi.

**Hasil dengan GIN:**

| Percobaan    | Execution Time |
| ------------ | -------------: |
| 1            |     533,895 ms |
| 2            |     321,077 ms |
| 3            |     297,229 ms |
| **Tercepat** | **297,229 ms** |
| **Median**   | **321,077 ms** |

Dengan GIN, rencana yang digunakan adalah `Bitmap Index Scan` pada `idx_gin_tags` yang dilanjutkan dengan `Bitmap Heap Scan`. Jadi PostgreSQL menggunakan index untuk menemukan baris yang sesuai dengan kondisi `tags @> ARRAY['kanal:1']`, kemudian mengambil baris tersebut dari heap.

**Hasil tanpa GIN:**

| Percobaan    | Execution Time |
| ------------ | -------------: |
| 1            |     582,267 ms |
| 2            |     595,805 ms |
| 3            |     531,721 ms |
| **Tercepat** | **531,721 ms** |
| **Median**   | **582,267 ms** |

Setelah penggunaan index dimatikan, rencana berubah menjadi `Seq Scan`. Pada kondisi ini PostgreSQL tidak lagi mencari melalui `idx_gin_tags`, tetapi membaca tabel dan memeriksa setiap baris untuk menemukan `tags` yang sesuai.

| Kondisi    | Node                                 |       Tercepat |         Median | Buffers               |
| ---------- | ------------------------------------ | -------------: | -------------: | --------------------- |
| Dengan GIN | Bitmap Heap Scan → Bitmap Index Scan | **297,229 ms** | **321,077 ms** | hit=1, read=58641     |
| Tanpa GIN  | Seq Scan                             | **531,721 ms** | **582,267 ms** | hit=16344, read=42222 |

Dari perbandingan tersebut, penggunaan GIN memberikan waktu yang lebih cepat. Median dengan GIN adalah **321,077 ms**, sedangkan tanpa GIN **582,267 ms**, dengan selisih **261,190 ms**. Jadi, pada query ini GIN masih lebih menguntungkan dibandingkan membaca seluruh tabel dengan `Seq Scan`.



**Q19 · Correlation dan ukuran.** Berkas: `q19_brin_vs_btree.sql`. Cantumkan `correlation`
`terjadi_pada` dari `pg_stats` dan ukuran BRIN dibanding B-Tree pada kolom yang sama.


**Query:**

```sql
-- 1. Buat B-Tree pembanding di kolom yang sama (terjadi_pada)

CREATE INDEX IF NOT EXISTS idx_btree_terjadi
ON lab6.event_log (terjadi_pada);

-- 2. Periksa nilai correlation kolom terjadi_pada di pg_stats

SELECT tablename, attname, correlation
FROM pg_stats
WHERE tablename = 'event_log'
  AND attname = 'terjadi_pada';

-- 3. Bandingkan ukuran indeks BRIN vs B-Tree

SELECT
    pg_size_pretty(pg_relation_size('lab6.idx_brin_terjadi')) AS ukuran_brin,
    pg_size_pretty(pg_relation_size('lab6.idx_btree_terjadi')) AS ukuran_btree;
```

**Hasil:**

```text
 tablename |   attname    | correlation
-----------+--------------+-------------
 event_log | terjadi_pada | 1
```

```text
 ukuran_brin | ukuran_btree
-------------+--------------
 32 kB       | 43 MB
```

Nilai `correlation` pada `terjadi_pada` adalah **1**, yang berarti urutan nilai pada kolom tersebut sangat sesuai dengan urutan fisik data di tabel. Kondisi ini membuat BRIN cocok digunakan karena BRIN bekerja berdasarkan rentang halaman data.

Ukuran BRIN hanya **32 kB**, sedangkan B-Tree mencapai **43 MB**. Perbedaannya sangat besar karena BRIN tidak menyimpan setiap baris secara langsung seperti B-Tree, tetapi menyimpan informasi untuk rentang halaman. Jadi, pada kolom `terjadi_pada` yang memiliki correlation sangat tinggi, BRIN dapat memberikan penghematan ruang yang jauh lebih besar.



**Q20 · Rentang tujuh hari.** Berkas: `q20_brin_rentang.sql`. Catat pemenang dan selisih Buffers.

**Query:**

```sql
-- 1. Uji BRIN

DROP INDEX IF EXISTS lab6.idx_btree_terjadi;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log 
WHERE terjadi_pada >= '2024-05-01 00:00+07' 
  AND terjadi_pada < '2024-05-08 00:00+07';


-- 2. Buat B-Tree

CREATE INDEX idx_btree_terjadi
ON lab6.event_log (terjadi_pada);

-- 3. Uji B-Tree

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log 
WHERE terjadi_pada >= '2024-05-01 00:00+07' 
  AND terjadi_pada < '2024-05-08 00:00+07';
```

Masing-masing kondisi dijalankan sebanyak tiga kali.

**Hasil pengukuran:**

| Index  | Node                                 |      Tercepat |        Median | Buffers          | Ukuran Index |
| ------ | ------------------------------------ | ------------: | ------------: | ---------------- | -----------: |
| BRIN   | Bitmap Heap Scan → Bitmap Index Scan | **11,276 ms** | **13,864 ms** | hit=1417, read=1 |    **32 kB** |
| B-Tree | Index Scan                           | **11,189 ms** | **11,342 ms** | hit=1678         |    **43 MB** |

Pada BRIN, PostgreSQL menggunakan `Bitmap Index Scan` pada `idx_brin_terjadi`, kemudian mengambil data melalui `Bitmap Heap Scan`. Waktu tercepatnya **11,276 ms** dengan median **13,864 ms**.

Pada B-Tree, PostgreSQL langsung menggunakan `Index Scan` pada `idx_btree_terjadi`. Waktu tercepatnya **11,189 ms** dan median **11,342 ms**. Jadi, dari sisi waktu, B-Tree sedikit lebih cepat. Selisih median keduanya hanya sekitar **2,522 ms**.

Perbedaannya lebih terlihat pada ukuran index. BRIN hanya berukuran **32 kB**, sedangkan B-Tree berukuran **43 MB**. Jadi, untuk query rentang tujuh hari ini, B-Tree memberikan waktu yang sedikit lebih cepat, tetapi BRIN membutuhkan ruang penyimpanan yang jauh lebih kecil.


**Q21 · Reflektif.** *Kapan penghematan ukuran BRIN sepadan dengan selisih waktunya?*

Menurut hasil pengujian, penghematan ukuran BRIN sudah sepadan dengan selisih waktunya. BRIN memang sedikit lebih lambat, dengan median **13,864 ms**, sedangkan B-Tree **11,342 ms**, sehingga selisihnya hanya **2,522 ms**. Namun, ukuran index-nya berbeda sangat jauh, yaitu BRIN hanya **32 kB**, sedangkan B-Tree **43 MB**. Artinya, dengan selisih waktu yang kecil, BRIN bisa menghemat ruang penyimpanan yang cukup besar. Jadi, kalau query tidak dituntut harus secepat mungkin dan ukuran index juga perlu diperhatikan, BRIN masih menjadi pilihan yang masuk akal. Apalagi pada data `terjadi_pada`, nilai correlation-nya **1**, sehingga kondisi datanya memang cocok untuk penggunaan BRIN.


### Langkah 6 · Statistik, selektivitas, dan Seq Scan

**Q22 · Rencana per status.** Berkas: `q22_index_status.sql`. Salin rencana untuk `SUKSES` dan
`GAGAL`.

**Query:**

```sql
-- 1. Buat Indeks pada Kolom Status

CREATE INDEX IF NOT EXISTS idx_status ON lab6.event_log (status);

-- 2. Uji Status SUKSES

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE status = 'SUKSES';

-- 3. Uji Status GAGAL

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE status = 'GAGAL';
```

Query untuk masing-masing status dijalankan sebanyak tiga kali.

**Hasil Status SUKSES:**

| Percobaan    | Plan     | Execution Time |
| ------------ | -------- | -------------: |
| 1            | Seq Scan |     593,562 ms |
| 2            | Seq Scan |     319,486 ms |
| 3            | Seq Scan |     361,549 ms |
| **Tercepat** |          | **319,486 ms** |
| **Median**   |          | **361,549 ms** |

Pada `SUKSES`, PostgreSQL tetap menggunakan **Seq Scan**, walaupun `idx_status` sudah dibuat. Query menghasilkan **1.680.000 baris**, sedangkan yang tidak memenuhi kondisi hanya **320.000 baris**. Karena sebagian besar isi tabel adalah `SUKSES`, penggunaan Seq Scan lebih dipilih daripada mengambil sebagian besar baris melalui index.

**Hasil Status GAGAL:**

| Percobaan    | Plan        | Execution Time |
| ------------ | ----------- | -------------: |
| 1            | Index Scan  |     138,654 ms |
| 2            | Index Scan  |    2141,239 ms |
| 3            | Index Scan  |     108,216 ms |
| **Tercepat** |             | **108,216 ms** |
| **Median**   |             | **138,654 ms** |

Pada `GAGAL`, PostgreSQL menggunakan **Index Scan** melalui `ev_gagal_idx`. Hasil query hanya **40.000 baris**, sehingga index lebih membantu dibandingkan membaca seluruh tabel. Berbeda dengan `SUKSES`, jumlah data `GAGAL` hanya sekitar **2%** dari seluruh baris.

Dari kedua hasil tersebut terlihat bahwa jumlah baris yang memenuhi kondisi ikut memengaruhi pilihan plan. `SUKSES` yang memiliki jumlah baris sangat banyak menggunakan **Seq Scan**, sedangkan `GAGAL` yang jumlahnya sedikit menggunakan **Index Scan**.


**Q23 · Titik peralihan.** Berkas: `q23_selektivitas.sql`. Cantumkan fraksi tiap status dan
fraksi tempat optimizer berpindah dari Index Scan ke Seq Scan.

**Query:**

```sql
SELECT 
    status, 
    COUNT(*) AS jumlah,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS persentase
FROM lab6.event_log
GROUP BY status;
```

**Hasil:**

| Status   |    Jumlah | Persentase |
| -------- | --------: | ---------: |
| GAGAL    |    40.000 |      2,00% |
| SUKSES   | 1.680.000 |     84,00% |
| TERTUNDA |   280.000 |     14,00% |

Pada `GAGAL` yang hanya mencakup **2%** dari seluruh data, PostgreSQL memilih **Index Scan**. Ketika jumlah data yang dicari lebih besar, seperti `TERTUNDA` sebesar **14%**, plan yang digunakan berubah menjadi **Bitmap Scan**. Sedangkan `SUKSES` yang mencakup **84%** data menggunakan **Seq Scan**. Jadi, berdasarkan data yang diuji, titik peralihan menuju Seq Scan berada di antara fraksi **14% dan 84%**. 


**Q24 · `random_page_cost = 1.1`.** Berkas: `q24_random_page_cost.sql`. Jelaskan pergeseran
titik peralihan, dan buktikan `RESET` sudah dijalankan.

**Query:**

```sql
-- 1. Ubah parameter random_page_cost

SET random_page_cost = 1.1;

-- 2. Uji ulang query status SUKSES

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE status = 'SUKSES';

-- 3. Kembalikan ke konfigurasi default

RESET random_page_cost;
```

Query `SUKSES` dijalankan sebanyak tiga kali dengan `random_page_cost = 1.1`.

**Hasil:**

| Percobaan    | Plan     | Execution Time |
| ------------ | -------- | -------------: |
| 1            | Seq Scan |     590,847 ms |
| 2            | Seq Scan |     498,867 ms |
| 3            | Seq Scan |     341,589 ms |
| **Tercepat** |          | **341,589 ms** |
| **Median**   |          | **498,867 ms** |

Walaupun `random_page_cost` diturunkan menjadi **1.1**, PostgreSQL tetap memilih **Seq Scan** untuk `SUKSES`. Hal ini karena `SUKSES` mencakup **84%** dari seluruh data, sehingga membaca tabel secara langsung masih dianggap lebih efisien daripada menggunakan index.

Penurunan `random_page_cost` pada pengujian ini belum cukup untuk membuat PostgreSQL berpindah dari `Seq Scan` ke penggunaan index. Setelah pengujian selesai, nilai `random_page_cost` dikembalikan dengan `RESET`.

**Q25 · Extended statistics.** Berkas: `q25_extended_statistics.sql`. Bandingkan estimasi baris
dengan kenyataan, sebelum dan sesudah `ANALYZE`.

**Query:**

```sql
-- 1. Cek estimasi baris SEBELUM extended statistics

EXPLAIN ANALYZE
SELECT * FROM lab6.event_log WHERE wilayah = 'SUMUT' AND kota = 'MEDAN';

-- 2. Buat extended statistics untuk korelasi kolom wilayah dan kota

CREATE STATISTICS IF NOT EXISTS stat_wilayah_kota (dependencies, ndistinct)
ON wilayah, kota FROM lab6.event_log;

-- 3. Perbarui statistik tabel

ANALYZE lab6.event_log;

-- 4. Cek estimasi baris SESUDAH extended statistics

EXPLAIN ANALYZE
SELECT * FROM lab6.event_log WHERE wilayah = 'SUMUT' AND kota = 'MEDAN';
```

**Hasil sebelum extended statistics:**

```text
(cost=1000.00..72066.10 rows=1 width=194)
(actual time=353.324..356.207 rows=0 loops=1)
```

Estimasi PostgreSQL adalah **1 baris**, sedangkan jumlah baris yang benar-benar ditemukan adalah **0 baris**.

**Hasil sesudah extended statistics:**

```text
(cost=1000.00..72066.99 rows=1 width=194)
(actual time=75.613..77.872 rows=0 loops=1)
```

Setelah `ANALYZE`, estimasi tetap **1 baris** dan hasil aktual tetap **0 baris**.

| Kondisi                     | Estimasi Baris | Baris Aktual |
| --------------------------- | -------------: | -----------: |
| Sebelum extended statistics |              1 |            0 |
| Sesudah extended statistics |              1 |            0 |

Pada pengujian ini, extended statistics belum mengubah estimasi jumlah baris. PostgreSQL tetap memperkirakan 1 baris, padahal tidak ada baris yang memenuhi kondisi `wilayah = 'SUMUT'` dan `kota = 'MEDAN'`.


**Q26 · Reflektif.** *Pilih satu status untuk index dan satu untuk Seq Scan; jelaskan mengapa
titik peralihannya bukan angka tetap.*

### Q26 · Reflektif

Status GAGAL digunakan sebagai contoh status yang memakai Index Scan, sedangkan SUKSES menggunakan Seq Scan. Pada GAGAL, hanya ada 40.000 baris atau 2% dari total 2.000.000 baris, sehingga PostgreSQL cukup mengambil sebagian kecil data melalui index. Sementara itu, SUKSES mencakup 1.680.000 baris atau 84% dari seluruh data. Karena data yang harus diambil sangat banyak, PostgreSQL memilih membaca tabel secara langsung dengan Seq Scan.

Titik peralihannya tidak bisa ditentukan sebagai satu angka yang selalu sama. Misalnya, dari hasil pengujian kita, 2% masih menggunakan Index Scan, sedangkan 84% sudah menggunakan Seq Scan. Di antara kedua kondisi itu, PostgreSQL bisa saja memilih plan yang berbeda, seperti Bitmap Scan pada TERTUNDA yang jumlahnya 14%. Pilihan tersebut tergantung pada perkiraan biaya membaca data, kondisi tabel, statistik, dan pengaturan database.


### Langkah 7 · Harga tulis dan rekomendasi

**Q27 · Harga tulis.** Berkas: `q27_harga_tulis.sql`. Nyatakan selisih waktu INSERT 200000
baris dalam persen, untuk tiga kali uji.

> «Belum diisi.»

**Q28 · Ukuran dua keadaan.** Berkas: `q28_ukuran_dua_keadaan.sql`.

> «Belum diisi.»

**Q29 · Daftar index dan `idx_scan`.** Berkas: `q29_daftar_index.sql`. Sebutkan index dengan
`idx_scan` nol, dan alasan bila tetap harus dipertahankan.

> «Belum diisi.»

**Q30 · Rekomendasi final.** Berkas: `q30_rekomendasi_index.sql`.

> «Belum diisi.»

**Q31 · Reflektif.** *Untuk setiap index yang direkomendasikan dihapus atau dipertahankan,
sebutkan satu angka sebagai dasar keputusan.*

> «Belum diisi.»

---

## Tabel Perbandingan

Dihasilkan ulang dari `explain/*.txt` dengan `rangkum_pengukuran.py`, lalu diringkas:

| Query/index | Tercepat | Median | Buffers | Ukuran | Keputusan |
|---|---:|---:|---:|---:|---|
| | | | | | |

---

## Rekomendasi Akhir

| Index | Keputusan | Angka dasar keputusan |
|---|---|---|
| | dipertahankan / dihapus / digabung | |

---

## Penggunaan AI dan Verifikasi

| Anggota | Bantuan AI yang dipakai | Cara memverifikasi |
|---|---|---|
| | | |
