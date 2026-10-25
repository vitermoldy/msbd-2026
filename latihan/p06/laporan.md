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

> **Status laporan.** Seluruh Q1–Q31 terisi dengan angka dan keluaran asli dari `explain/`.
> Tidak ada kotak yang diisi dengan angka perkiraan.
>
> **Catatan pengukuran ulang (25 Oktober 2026).** Berkas SQL Langkah 2 sampai Langkah 6
> awalnya belum memenuhi dua aturan pengukuran yang diwajibkan soal: setiap query harus
> dijalankan **tiga kali** dan `max_parallel_workers_per_gather` harus disetel **0**. Berkas
> itu kemudian dilengkapi tanpa mengubah query yang diuji, lalu **seluruh rangkaian Q0–Q30
> dijalankan ulang dari nol pada satu mesin** sehingga `idx_scan` pada Q29 dan rekomendasi
> pada Q30 berdiri di atas keadaan basis data yang sama. Tiga kesalahan yang ditemukan saat
> pengerjaan ulang itu diperbaiki dan dicatat di tempatnya masing-masing: index BRIN tidak
> pernah dibuat berkas mana pun (Q19), nama index ditulis tanpa skema (Q17), dan nilai `kota`
> yang diuji tidak pernah ada di data (Q25). Narasi Q17–Q26 ditulis dari pengukuran pertama
> penulisnya; bila angkanya berbeda dengan isi `explain/`, berkas `explain/` yang berlaku
> karena itulah hasil jalan ulang yang memenuhi aturan tiga kali uji.

---

## Identitas Kelompok dan Kontribusi

| Nama | NIM | Kontribusi Pertemuan 6 | Commit |
|---|---|---|---|
| Viter Moldy Kesuma | 251402079 | Langkah 1 (`q00_setup.sql`, `q01_ukuran_tabel.sql`, Q1) · Langkah 7 (Q27–Q31) · `README.md` · kerangka dan penutup `laporan.md` · `hasil_pengukuran.md` | `3c28375` · `e3c6d01` · `2bde31c` · `22a9462` · `7e4ff1b` · `acdf825` · «commit Langkah 7» |
| Gideon Finsus Siburian | 251402038 | Langkah 2 — anatomi penyimpanan, Q2–Q6 | `4790895` |
| Nadine Tantiara Hutagaol | 251402050 | Langkah 3 — baseline, B-Tree, urutan kolom, Q7–Q11 | `3b19bb2` |
| Rizky Cristian Fero Sihombing | 251402056 | Langkah 4 — partial, expression, covering, index-only scan, Q12–Q16 | `b6358f0` |
| Siti Naifah Batubara | 251402067 | Langkah 5 (GIN dan BRIN, Q17–Q21) dan Langkah 6 (statistik dan selektivitas, Q22–Q26) | `8c5f726` |

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

**Q2 · Tuple per halaman.** Berkas: `q02_anatomi_storage.sql`
(keluaran: `explain/q02_anatomi_storage.txt`).

| Ukuran | Nilai |
|---|---:|
| Minimum tuple per halaman | 11 |
| Rata-rata | **34,15** |
| Maksimum | 35 |
| Jumlah halaman | 58.569 |
| Batas teoretis | **291** |

**Penafsiran.** Batas 291 berlaku untuk tuple berukuran minimum:
`(8192 − 24 header halaman) / (4 line pointer + 24 header tuple) = 291`. Baris `event_log`
lebarnya 239,9 byte, jadi yang muat hanya `8160 / 239,9 ≈ 34` — dan itu persis rata-rata yang
terukur, 34,15. Jadi selisih 291 lawan 34 bukan soal kerugian ruang, melainkan selisih antara
batas struktur halaman dan lebar baris nyata. Nilai minimum 11 datang dari halaman terakhir
yang belum penuh, dan maksimum 35 dari halaman yang barisnya kebetulan sedikit lebih pendek.

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

Percobaan pada `lab6.hot_longgar` (fillfactor 80, index `hot_longgar_nama_idx` pada kolom
`nama`), masing-masing 5.000 baris:

| Tahap | `n_tup_upd` | `n_tup_hot_upd` | Tambahan HOT |
|---|---:|---:|---:|
| Sesudah UPDATE kolom `catatan` seluruh tabel (Q4) | 10.000 | 2.560 | — |
| Sesudah UPDATE kolom **`nama` yang terindeks** | 15.000 | 2.560 | **0** |
| Sesudah UPDATE kolom **`catatan` yang tidak terindeks** | 20.000 | 5.537 | **2.977** |

**Jawaban.** HOT update hanya mungkin bila dua syarat terpenuhi sekaligus: versi baris yang
baru masih muat di halaman yang sama, dan **tidak ada kolom terindeks yang berubah**. Syarat
kedua itulah yang membedakan kedua percobaan di atas. Ketika `nama` diubah, nilai kunci pada
`hot_longgar_nama_idx` ikut berubah, sehingga index wajib menunjuk ke versi baris yang baru —
dan entri index tidak bisa menunjuk ke rantai HOT, karena rantai itu justru dirancang supaya
index lama tetap sah tanpa diperbarui. Akibatnya PostgreSQL membuat entri index baru dan
update itu bukan HOT. Ketika `catatan` yang diubah, tidak ada satu pun index yang memuat kolom
itu, jadi penunjuk lama tetap benar dan versi baru cukup dirantai di halaman yang sama.

Bukti angkanya bersih: jumlah baris yang di-UPDATE persis sama (5.000), tabelnya sama,
fillfactor-nya sama, dan satu-satunya pembeda adalah kolom mana yang disentuh — hasilnya 0
lawan 2.977 HOT update. Inilah alasan praktisnya: menambah index bukan hanya menambah ruang
dan biaya INSERT, tetapi juga **mengurangi peluang UPDATE menjadi HOT** pada kolom yang
diindeks, sehingga tabel lebih cepat membengkak.

### Langkah 3 · Baseline, B-Tree, dan urutan kolom

**Q7 · Baseline tanpa index.** Berkas: `q07_baseline.sql`
(keluaran: `explain/q07_baseline.txt`). Saat berkas ini dijalankan, satu-satunya index pada
`lab6.event_log` adalah `event_log_pkey`.

```text
 Limit  (cost=88572.35..88572.39 rows=17 width=22) (actual time=92.335..92.337 rows=19 loops=1)
   Buffers: shared hit=3 read=58569
   ->  Sort  (cost=88572.35..88572.39 rows=17 width=22)
         Sort Key: terjadi_pada DESC
         Sort Method: quicksort  Memory: 26kB
         ->  Seq Scan on event_log  (cost=0.00..88572.00 rows=17 width=22)
               Filter: ((terjadi_pada >= '2024-05-31 17:00:00+00') AND (customer_id = 4211))
               Rows Removed by Filter: 1999985
 Execution Time: 92.366 ms
```

| Hal | Nilai |
|---|---|
| Jenis node | **Seq Scan** diikuti **Sort** |
| Baris estimasi lawan nyata | 17 lawan 19 |
| Baris dibuang filter | **1.999.985** |
| Buffers | **58.572** (hampir seluruh tabel) |
| Tercepat | **92,366 ms** |
| Median | **93,084 ms** |

**Penafsiran.** Untuk memperoleh 19 baris, PostgreSQL membaca dua juta baris dan membuang
1.999.985 di antaranya, lalu masih harus mengurutkan hasilnya karena tidak ada urutan yang
bisa dipinjam dari mana pun. Inilah garis dasar yang akan dibandingkan pada Q8 dan Q9.

**Q8 · Urutan salah.** Berkas: `q08_urutan_salah.sql`
(keluaran: `explain/q08_urutan_salah.txt`). `ev_salah_idx (terjadi_pada, customer_id)`
berukuran **60 MB**.

```text
 Limit  (cost=0.43..25058.56 rows=17 width=22) (actual time=0.055..9.828 rows=19 loops=1)
   Buffers: shared hit=3825
   ->  Index Scan Backward using ev_salah_idx on event_log
         Index Cond: ((terjadi_pada >= '2024-05-31 17:00:00+00') AND (customer_id = 4211))
 Execution Time: 9.847 ms
```

**Apakah index dipakai?** Ya. **Apakah masih ada Sort?** Tidak — node `Sort` hilang sama
sekali, dan seluruh berkas keluarannya tidak memuat satu pun kata `Sort`.

| Keadaan | Node | Tercepat | Median | Buffers |
|---|---|---:|---:|---:|
| Q7 tanpa index | Seq Scan + Sort | 92,366 ms | 93,084 ms | 58.572 |
| Q8 `(terjadi_pada, customer_id)` | Index Scan Backward | **9,847 ms** | 10,408 ms | **3.825** |

**Penafsiran.** Index dipakai dan urutannya dipinjam: karena daun B-Tree sudah urut menurut
`terjadi_pada`, membacanya mundur langsung memberi urutan `DESC` yang diminta, sehingga Sort
tidak diperlukan. Tetapi `customer_id` berada di kolom kedua, jadi PostgreSQL tetap harus
menyusuri seluruh rentang waktu sejak Juni sambil membuang baris yang customer-nya salah —
3.825 buffer, sekitar 15 kali lebih sedikit daripada baseline tetapi masih 200 kali lebih
banyak daripada Q9. Index yang "dipakai" belum tentu index yang tepat.

**Q9 · Urutan benar.** Berkas: `q09_urutan_benar.sql`. Bandingkan tiga waktu dalam satu tabel.

| Keadaan | Node | Tercepat | Median | Buffers |
|---|---|---:|---:|---:|
| Q7 tanpa index | | | | |
| Q8 `(terjadi_pada, customer_id)` | | | | |
| Q9 `(customer_id, terjadi_pada DESC)` | | | | |

**Q10 · Ukuran index.** Berkas: `q10_ukuran_index.sql`
(keluaran: `explain/q10_ukuran_index.txt`).

| Index | Ukuran | Byte | Halaman daun | Kerapatan daun |
|---|---:|---:|---:|---:|
| `ev_salah_idx (terjadi_pada, customer_id)` | 60 MB | 63.012.864 | 7.663 | 89,94% |
| `ev_benar_idx (customer_id, terjadi_pada DESC)` | 60 MB | 63.102.976 | 7.663 | 90,03% |

Keduanya **praktis sama besar**, hanya berbeda 90.112 byte atau 0,14%. Itu masuk akal: jumlah
entri sama, lebar kuncinya sama (4 byte integer + 8 byte timestamp), jumlah halaman daunnya
bahkan identik 7.663, dan keduanya dibangun sekaligus oleh `CREATE INDEX` yang mengurutkan
data lebih dulu sehingga daunnya terisi ~90%.

Karena perbandingan itu sendiri tidak menjelaskan apa pun, berkas ini memuat tiga percobaan
terkendali yang menunjukkan kapan kolom yang sama benar-benar menghasilkan ukuran berbeda:

| Penyebab | Varian | Ukuran |
|---|---|---:|
| **Fillfactor** | `(customer_id, terjadi_pada DESC)` fillfactor 90 (bawaan) | 60 MB |
| | kolom sama, fillfactor 50 | **109 MB** |
| **Deduplikasi daun** | `(status)` — hanya 3 nilai, berulang jutaan kali | 13 MB |
| | `(status, event_id)` — setiap kunci unik | **63 MB** |
| **Cara dibangun** | diisi bertahap lewat INSERT acak | 19 MB, kerapatan 72,1% |
| | dibangun sekaligus oleh `CREATE INDEX` | **15 MB**, kerapatan 90,0% |

**Penafsiran.** Ukuran B-Tree ditentukan tiga hal di luar daftar kolomnya. Pertama,
`fillfactor`: ruang kosong yang sengaja disisakan tiap halaman daun — menurunkannya dari 90 ke
50 membuat index 82% lebih besar tanpa menambah satu entri pun. Kedua, **deduplikasi**: sejak
PostgreSQL 13, kunci yang berulang disimpan sekali dengan daftar penunjuk, sehingga index atas
`status` yang hanya punya tiga nilai cukup 13 MB; menambahkan `event_id` membuat setiap kunci
unik, deduplikasi mati, dan ukurannya melonjak hampir lima kali. Ketiga, **cara pengisian**:
index yang sudah ada lalu diisi INSERT acak mengalami pemecahan halaman sehingga daunnya hanya
terisi 72,1%, sedangkan yang dibangun sekaligus terisi 90,0% — selisih 4 MB untuk isi yang
sama persis.

**Q11 · Reflektif.** *Kaitkan urutan daun B-Tree dengan kemampuan optimizer berhenti
mengurutkan hasil.*

Daun B-Tree tersimpan berurutan menurut kolom kuncinya, dari kiri ke kanan. Karena itu, scan
atas daun menghasilkan baris yang **sudah terurut** tanpa pekerjaan tambahan, dan bila urutan
itu cocok dengan `ORDER BY` query, optimizer boleh membuang node `Sort` sepenuhnya. Arah tidak
menjadi penghalang: B-Tree dapat dibaca maju maupun mundur, dan Q8 membuktikannya — rencananya
berbunyi `Index Scan Backward`, memberi urutan `terjadi_pada DESC` dari index yang didefinisikan
menaik.

Tiga rencana di latihan ini menunjukkan rangkaiannya dengan rapi:

| Keadaan | Ada `Sort`? | Buffers | Tercepat |
|---|---|---:|---:|
| Q7 tanpa index | **ya**, quicksort 26 kB | 58.572 | 92,366 ms |
| Q8 `(terjadi_pada, customer_id)` | tidak | 3.825 | 9,847 ms |
| Q9 `(customer_id, terjadi_pada DESC)` | tidak | **18** | **0,020 ms** |

Yang penting: **hilangnya `Sort` bukan penentu kemenangan.** Q8 dan Q9 sama-sama tanpa `Sort`,
tetapi selisihnya masih 490 kali lipat. Urutan daun menghemat *pengurutan*; posisi kolom
penyaring menentukan *berapa banyak daun yang harus dibaca* sebelum `LIMIT 20` terpenuhi. Pada
Q9 kolom kesetaraan `customer_id` ada di depan, sehingga seluruh baris milik customer itu
berkumpul di satu tempat dan sudah urut waktu di dalamnya — PostgreSQL cukup melompat ke sana
dan membaca 19 baris pertama. Pada Q8 kolom waktu yang di depan, sehingga 19 baris itu
tersebar di sepanjang separuh index.

Satu syarat yang mudah terlupakan: `Sort` hanya bisa dibuang bila **arah seluruh kolom urut**
cocok dengan definisi index, seluruhnya searah atau seluruhnya terbalik. `ORDER BY a ASC, b DESC`
tidak dapat dilayani index `(a, b)` tanpa pengurutan ulang, karena tidak ada arah pembacaan
yang menghasilkan pola campuran itu.

### Langkah 4 · Partial, expression, covering, dan index-only scan

**Q12 · Partial index.** Berkas: `q12_partial_index_gagal.sql`
(keluaran: `explain/q12_partial_index_gagal.txt`).

| Index | Definisi | Ukuran | Byte |
|---|---|---:|---:|
| `ev_terjadi_pada_idx` | `(terjadi_pada DESC)`, seluruh baris | 43 MB | 44.949.504 |
| `ev_gagal_idx` | `(terjadi_pada DESC) WHERE status='GAGAL'` | **896 kB** | 917.504 |

**Penghematan: 97,96%**, dan baris berstatus `GAGAL` memang 2,00% dari tabel.

Index itu benar-benar dipakai, bukan sekadar kecil:

```text
 Limit  (cost=0.29..1.38 rows=20 width=16) (actual time=0.010..0.012 rows=20 loops=1)
   Buffers: shared hit=22
   ->  Index Scan using ev_gagal_idx on event_log
 Execution Time: 0.012 ms
```

**Penafsiran.** Penghematan 97,96% mengikuti fraksi barisnya hampir sempurna: index parsial
hanya menyimpan entri untuk baris yang lolos predikat, jadi ukurannya sebanding dengan 2%
tabel ditambah sedikit ongkos struktur. Harganya adalah kekhususan — index ini tidak dapat
melayani query yang menyaring `status='TERTUNDA'` atau yang tidak menyebut `status` sama
sekali. Untuk beban kerja "cari kegagalan terbaru", itu tukar yang sangat murah: 896 kB
melayani query yang pada Q22 ternyata 2,4 kali lebih cepat daripada Seq Scan.

**Q13 · Expression index.** Berkas: `q13_expression_index_email.sql`
(keluaran: `explain/q13_expression_index_email.txt`). `ev_email_lower_idx` berukuran **86 MB**.

| Query | Node | Index dipakai | Tercepat | Median | Buffers |
|---|---|---|---:|---:|---:|
| `WHERE email = '...'` | Seq Scan | **tidak** | 107,902 ms | 108,698 ms | 58.569 |
| `WHERE lower(email) = lower('...')` | Index Scan `ev_email_lower_idx` | **ya** | **0,012 ms** | 0,014 ms | **4** |
| `WHERE upper(email) = upper('...')` | Seq Scan | **tidak** | 350,281 ms | — | 58.569 |

**Jawaban.** Index yang dipakai hanya pada versi kedua, dan satu-satunya alasannya: predikat
query harus **cocok persis dengan ekspresi yang dipakai saat index dibuat**. Index ini
dibangun atas `lower(email)`, maka PostgreSQL mengenalinya pada `lower(email) = ...`, tetapi
tidak pada `email = ...` maupun `upper(email) = ...` — bagi optimizer ketiganya adalah
ekspresi yang berbeda, dan tidak ada aturan yang membolehkannya menyimpulkan bahwa `email`
dapat dicari lewat index atas `lower(email)`.

Selisihnya ekstrem: 4 buffer lawan 58.569, dan 0,012 ms lawan 107,902 ms — sekitar 9.000 kali
lebih cepat. Pelajaran praktisnya, index ekspresi hanya berguna bila seluruh kode aplikasi
menulis predikatnya dengan bentuk yang sama; satu query yang lupa membungkus dengan `lower()`
akan diam-diam kembali memindai seluruh tabel.

**Q14 · Index-only scan dan Heap Fetches.** Berkas: `q14_covering_index_only_scan.sql`
(keluaran: `explain/q14_covering_index_only_scan.txt`). `ev_cover_idx` berukuran **77 MB**.

| Tahap | `relallvisible` | `relpages` | Persen all-visible |
|---|---:|---:|---:|
| Sebelum UPDATE | 7.822 | 58.569 | 13,36% |
| Sesudah UPDATE baris customer 4211 | 7.822 | 58.569 | 13,36% |
| **Sesudah `VACUUM (ANALYZE)`** | **58.537** | 58.570 | **99,94%** |

| Keadaan | Node | Heap Fetches | Buffers | Tercepat |
|---|---|---:|---:|---:|
| Sebelum VACUUM, rencana apa adanya | Index Only Scan | **66 / 33 / 33** | 40 | 0,015 ms |
| Sebelum VACUUM, index-only dipaksa | Index Only Scan | **33 / 33 / 33** | 6 | 0,009 ms |
| **Sesudah `VACUUM (ANALYZE)`** | Index Only Scan | **0 / 0 / 0** | **5** | 0,013 ms |

**Penafsiran.** Sebelum VACUUM, index-only scan tetap dipilih tetapi tidak benar-benar
"only": ia masih harus menengok heap 33 kali, satu kali untuk tiap baris yang dikembalikan,
karena halaman yang memuat baris-baris itu belum ditandai all-visible. Angka 66 pada
pengulangan pertama adalah dua kali 33, akibat versi baris lama yang masih tertinggal dari
`UPDATE` dan baru dibersihkan oleh pemangkasan halaman saat kunjungan pertama; dua pengulangan
berikutnya sudah mantap di 33. Setelah `VACUUM (ANALYZE)` menandai 99,94% halaman sebagai
all-visible, Heap Fetches turun ke **nol** dan jumlah buffer dari 40 menjadi 5.

**Q15 · INCLUDE lawan tiga kolom.** Berkas: `q15_covering_vs_tigakolom.sql`
(keluaran: `explain/q15_covering_vs_tigakolom.txt`).

| Index | Ukuran | Byte |
|---|---:|---:|
| `ev_cover_idx (customer_id) INCLUDE (terjadi_pada, jumlah)` | 77 MB | 81.141.760 |
| `ev_cover3_idx (customer_id, terjadi_pada, jumlah)` | 77 MB | 81.133.568 |

**Ukurannya praktis identik** — beda 8.192 byte, satu halaman. Wajar, karena isi yang disimpan
sama: ketiga kolom ada di dalam daun pada kedua bentuk. Pembedanya bukan ruang, melainkan apa
yang boleh dilakukan optimizer dengan kolom kedua dan ketiga.

| Kebutuhan query | `INCLUDE` | Tiga kolom kunci |
|---|---|---|
| `WHERE customer_id = 4211` | Index Only Scan | Index Only Scan |
| `ORDER BY terjadi_pada LIMIT 5` | **perlu `Sort`** (top-N heapsort, cost 9,60) | **tanpa `Sort`** (cost 1,69) |
| `AND terjadi_pada >= ...` | `Index Cond` hanya `customer_id` | `Index Cond` memuat **kedua** kolom |

```text
-- INCLUDE, ORDER BY kolom kedua
 Limit  (cost=9.59..9.60 rows=5 width=14)
   ->  Sort  (cost=9.59..9.67 rows=34 width=14)
         Sort Key: terjadi_pada
         Sort Method: top-N heapsort  Memory: 25kB

-- Tiga kolom kunci, query sama persis
 Limit  (cost=0.43..1.69 rows=5 width=14)
   ->  Index Only Scan using ev_cover3_idx on event_log
         Index Cond: (customer_id = 4211)
```

**Penafsiran.** Kolom `INCLUDE` hanya ikut **disimpan** di daun agar dapat dikembalikan tanpa
menyentuh heap; ia tidak ikut menentukan urutan daun dan tidak dapat dipakai sebagai
`Index Cond`. Karena itu `ORDER BY terjadi_pada` memaksa node `Sort` tambahan, dan predikat
atas `terjadi_pada` baru diterapkan setelah seluruh 33 entri milik customer itu dibaca.
Dengan tiga kolom kunci, keduanya diselesaikan di dalam index: urutan sudah benar sejak awal
(estimasi biaya turun dari 9,60 ke 1,69) dan rentang waktu masuk ke `Index Cond`.

Lalu kapan `INCLUDE` tetap lebih baik? Ketika kolom tambahan **tidak pernah** dipakai untuk
mencari atau mengurutkan, dan terutama ketika index harus `UNIQUE`: keunikan hanya berlaku
pada kolom kunci, sehingga `UNIQUE (customer_id) INCLUDE (jumlah)` menjaga keunikan
`customer_id` sambil tetap mencakup `jumlah` — sesuatu yang tidak bisa dilakukan index tiga
kolom kunci.

**Q16 · Reflektif.** *Mengapa Heap Fetches berubah setelah VACUUM walau definisi index tidak
berubah?*

Karena yang berubah bukan index, melainkan **visibility map** — peta satu-dua bit per halaman
heap yang mencatat apakah seluruh baris di halaman itu pasti terlihat oleh semua transaksi.

Index B-Tree tidak menyimpan informasi visibilitas sama sekali; ia hanya memetakan kunci ke
lokasi baris. Jadi ketika index-only scan menemukan entri yang cocok, PostgreSQL masih harus
menjawab satu pertanyaan yang tidak dapat dijawab index: apakah versi baris itu benar-benar
terlihat oleh transaksi ini, atau sudah mati karena UPDATE atau DELETE. Satu-satunya jalan
pintas adalah visibility map: bila halamannya bertanda all-visible, pertanyaan itu dijawab
"ya" tanpa membaca heap. Bila tidak bertanda, PostgreSQL wajib menengok heap — dan setiap
kunjungan itulah yang dihitung sebagai **Heap Fetches**.

`VACUUM` adalah satu-satunya proses yang memasang tanda tersebut. Itu sebabnya angkanya
berubah drastis meski `CREATE INDEX` tidak pernah diulang:

| | Sebelum VACUUM | Sesudah VACUUM |
|---|---:|---:|
| Halaman all-visible | 7.822 dari 58.569 (13,36%) | **58.537 dari 58.570 (99,94%)** |
| Heap Fetches | 33 | **0** |
| Buffers | 40 | **5** |

Tiga akibat praktisnya. Pertama, index-only scan tidak bisa diandalkan pada tabel yang baru
saja banyak di-UPDATE atau di-DELETE; ia akan diam-diam berubah menjadi index scan biasa
dengan kunjungan heap. Kedua, `UPDATE` yang bukan HOT ikut merusak tanda all-visible halaman
yang disentuhnya — sehingga Q6 dan Q14 sebenarnya satu cerita yang sama dilihat dari dua sisi.
Ketiga, autovacuum yang tertinggal pada tabel yang ramai ditulis akan menampakkan diri sebagai
"query yang tiba-tiba melambat" tanpa satu pun perubahan pada skema maupun index.

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

**Q27 · Harga tulis.** Berkas: `q27_harga_tulis.sql` (keluaran: `explain/q27_harga_tulis.txt`).

Dua tabel berstruktur kolom identik dibuat dari `LIKE lab6.event_log EXCLUDING ALL`. Salah
satunya dibiarkan polos, satunya diberi lima index yang mewakili kelima jenis yang diuji
latihan ini: B-Tree majemuk `(customer_id, terjadi_pada DESC)`, partial `WHERE status='GAGAL'`,
ekspresi `lower(email)`, GIN `jsonb_path_ops` pada `payload`, dan BRIN pada `terjadi_pada`.
Setiap ulangan menyisipkan 200.000 baris yang sama ke kedua tabel, dan antar ulangan tabelnya
di-`TRUNCATE` supaya ruangnya kembali dan ukuran pada Q28 tetap adil.

| Ulangan | Tanpa index | Dengan 5 index | Selisih | Lebih lambat |
|---|---:|---:|---:|---:|
| 1 | 147,8 ms | 993,8 ms | 846,0 ms | **572,4%** |
| 2 | 153,4 ms | 938,6 ms | 785,2 ms | **511,9%** |
| 3 | 124,5 ms | 908,4 ms | 783,9 ms | **629,6%** |
| **Tercepat** | **124,5 ms** | **908,4 ms** | 783,9 ms | 629,6% |
| **Median** | **147,8 ms** | **938,6 ms** | 790,8 ms | **535,0%** |

**Penafsiran.** Memakai median, INSERT dengan lima index **535,0% lebih lambat**, yaitu 6,35
kali waktu INSERT polos. Angka ini bukan biaya satu index melainkan jumlah lima index: setiap
baris baru memaksa lima struktur ikut diperbarui, dan GIN yang harus memecah `payload` menjadi
entri jalur adalah yang paling mahal. Sebaran ketiga ulangan lebar (511,9% sampai 629,6%)
karena INSERT bersaing dengan autovacuum dan penulisan WAL, sehingga median lebih layak
dipakai daripada satu angka tunggal.

**Q28 · Ukuran dua keadaan.** Berkas: `q28_ukuran_dua_keadaan.sql`
(keluaran: `explain/q28_ukuran_dua_keadaan.txt`).

| Tabel | Heap | Index | Total |
|---|---:|---:|---:|
| `tulis_tanpa_index` | 45 MB | 0 byte | **45 MB** (47.702.016 byte) |
| `tulis_lima_index` | 45 MB | 27 MB | **72 MB** (75.636.736 byte) |
| Selisih | sama | +27 MB | **+58,6%** |

Rincian kelima index pada `tulis_lima_index`:

| Index | Jenis | Ukuran |
|---|---|---:|
| `tulis_ekspresi_idx` | B-Tree `lower(email)` | 14 MB |
| `tulis_btree_idx` | B-Tree `(customer_id, terjadi_pada DESC)` | 8.344 kB |
| `tulis_gin_idx` | GIN `payload jsonb_path_ops` | 4.792 kB |
| `tulis_partial_idx` | B-Tree partial `status='GAGAL'` | 176 kB |
| `tulis_brin_idx` | BRIN `terjadi_pada` | **24 kB** |

**Penafsiran.** Heap kedua tabel sama persis 45 MB, jadi seluruh selisih 27 MB murni biaya
index. Perhatikan sebarannya: `tulis_ekspresi_idx` sendirian 14 MB, lebih dari separuh total,
karena `lower(email)` menyimpan salinan string email untuk setiap baris. Di ujung lain, BRIN
hanya 24 kB — **583 kali lebih kecil** daripada index ekspresi untuk tabel yang sama. Jadi
"menambah index" bukan satu harga: tergantung jenis dan kolomnya, biayanya berbeda tiga orde
besaran.

**Q29 · Daftar index dan `idx_scan`.** Berkas: `q29_daftar_index.sql`
(keluaran: `explain/q29_daftar_index.txt`). Seluruh skema `lab6` memuat **20 index, 466 MB**,
dan **8 di antaranya (71 MB) belum pernah dipakai sama sekali**.

| Tabel | Index | `idx_scan` | `idx_tup_read` | Ukuran |
|---|---|---:|---:|---:|
| `event_log` | `ev_benar_idx` | **18** | 8.550.606 | 60 MB |
| `event_log` | `event_log_pkey` | 9 | 2.200.005 | 43 MB |
| `event_log` | `idx_gin_tags` | 8 | 2.666.668 | 4.664 kB |
| `event_log` | `ev_cover3_idx` | 6 | 32 | 77 MB |
| `event_log` | `ev_gagal_idx` | 6 | 120.062 | 896 kB |
| `event_log` | `idx_status` | 5 | 4.520.000 | 13 MB |
| `event_log` | `idx_btree_terjadi` | 4 | 186.092 | 43 MB |
| `event_log` | `idx_gin_payload` | 4 | 320.000 | 7.096 kB |
| `event_log` | `ev_email_lower_idx` | 3 | 3 | 86 MB |
| `event_log` | `idx_brin_terjadi` | 3 | 44.460 | **32 kB** |
| `hot_longgar` | `hot_longgar_pkey` | 2 | 18.976 | 456 kB |
| `event_log` | `ev_salah_idx` | 1 | 66 | 60 MB |
| `event_log` | `ev_terjadi_pada_idx` | **0** | 0 | 43 MB |
| `tulis_lima_index` | `tulis_ekspresi_idx` | **0** | 0 | 14 MB |
| `tulis_lima_index` | `tulis_btree_idx` | **0** | 0 | 8.344 kB |
| `tulis_lima_index` | `tulis_gin_idx` | **0** | 0 | 4.792 kB |
| `hot_longgar` | `hot_longgar_nama_idx` | **0** | 0 | 872 kB |
| `hot_penuh` | `hot_penuh_pkey` | **0** | 0 | 456 kB |
| `tulis_lima_index` | `tulis_partial_idx` | **0** | 0 | 176 kB |
| `tulis_lima_index` | `tulis_brin_idx` | **0** | 0 | 24 kB |

**Index dengan `idx_scan` nol dan alasannya.** Kedelapan index itu terbagi tiga golongan, dan
hanya satu golongan yang benar-benar layak dihapus:

- **Wajib dipertahankan meski nol: `hot_penuh_pkey` (456 kB).** Ia primary key; tugasnya
  menjaga keunikan `id`, bukan mempercepat baca. Menghapusnya mengubah aturan integritas
  tabel, bukan sekadar menghemat ruang. Catatan menarik: `hot_longgar_pkey` yang definisinya
  sama justru terpakai 2 kali, hanya karena Q6 menyaring `WHERE id <= 5000` di tabel itu —
  bukti bahwa `idx_scan` mencerminkan beban kerja yang kebetulan dijalankan, bukan nilai
  sebuah index.
- **Hilang bersama tabel ujinya: lima index `tulis_*` (27 MB) dan `hot_longgar_nama_idx`
  (872 kB).** Tabel `tulis_lima_index` memang hanya ditulis, tidak pernah dibaca — itu justru
  inti percobaan Q27. `hot_longgar_nama_idx` sengaja dibuat untuk membuktikan Q6 bahwa UPDATE
  kolom terindeks tidak menghasilkan HOT update; ia tidak pernah perlu dibaca untuk itu.
- **Kandidat hapus sesungguhnya: `ev_terjadi_pada_idx` (43 MB).** Ini satu-satunya index pada
  tabel sungguhan yang nol pemakaian, dan sebabnya jelas pada Q30: ia kembar dengan
  `idx_btree_terjadi` yang isinya sama persis dan terpakai 4 kali. Dua index untuk satu kolom,
  hanya berbeda arah urutan.

**Catatan membaca `idx_tup_read`.** Angka `idx_scan` yang berdekatan menyembunyikan perbedaan
besar: `ev_email_lower_idx` dibuka 3 kali dan hanya membaca **3 baris**, sedangkan `idx_status`
dibuka 5 kali dan membaca **4.520.000 baris**. Jadi `idx_scan` hanya menghitung berapa kali
index dibuka, bukan seberapa berguna ia; `idx_tup_read` dibaca bersamanya untuk melihat berapa
banyak pekerjaan yang benar-benar dipikul.

**Q30 · Rekomendasi final.** Berkas: `q30_rekomendasi_index.sql`
(keluaran: `explain/q30_rekomendasi_index.txt`).

Seluruh index pada `event_log` memakan **438 MB, yaitu 95,8% dari heap-nya sendiri** (458 MB),
sehingga satu tabel dua juta baris menghabiskan **896 MB**. Angka inilah yang membuat
pemangkasan layak dibahas.

| Index | `idx_scan` | Ukuran | % heap | Keputusan |
|---|---:|---:|---:|---|
| `event_log_pkey` | 9 | 43 MB | 9,37 | **dipertahankan** — primary key |
| `ev_cover3_idx` | 6 | 77 MB | 16,91 | **dipertahankan** sebagai gabungan |
| `ev_gagal_idx` | 6 | 896 kB | 0,19 | **dipertahankan** — termurah, 97,96% lebih kecil dari index polos |
| `idx_gin_tags` | 8 | 4.664 kB | 1,00 | **dipertahankan** — satu-satunya jalan untuk `tags @>` |
| `idx_gin_payload` | 4 | 7.096 kB | 1,51 | **dipertahankan** — satu-satunya jalan untuk `payload @>` |
| `idx_brin_terjadi` | 3 | **32 kB** | 0,01 | **dipertahankan** — hampir gratis |
| `idx_status` | 5 | 13 MB | 2,90 | **ditinjau ulang** — 84% baris bernilai `SUKSES` |
| `ev_benar_idx` | 18 | 60 MB | 13,15 | **digabung** ke `ev_cover3_idx` |
| `idx_btree_terjadi` | 4 | 43 MB | 9,37 | **ditinjau ulang** — BRIN hampir seimbang |
| `ev_salah_idx` | 1 | 60 MB | 13,13 | **dihapus** |
| `ev_terjadi_pada_idx` | **0** | 43 MB | 9,37 | **dihapus** — kembar dengan `idx_btree_terjadi` |
| `ev_email_lower_idx` | 3 | 86 MB | 18,84 | **dihapus** kecuali ada pencarian email |

**Kandidat gabung yang ditemukan query di `q30`.**

1. `ev_benar_idx (customer_id, terjadi_pada DESC)` adalah **awalan** dari
   `ev_cover3_idx (customer_id, terjadi_pada, jumlah)`. Ini kasus paling menarik: yang sempit
   justru terpakai **18 kali**, terbanyak di seluruh skema, sementara yang lebar 6 kali.
   Artinya yang dihapus bukan yang jarang dipakai, melainkan yang **pekerjaannya sudah bisa
   diambil alih**: `ev_cover3_idx` melayani setiap query yang dilayani `ev_benar_idx`, dengan
   urutan kolom yang sama. Hemat **60 MB**.
2. `ev_terjadi_pada_idx (terjadi_pada DESC)` dan `idx_btree_terjadi (terjadi_pada)` adalah
   **index kembar** yang hanya berbeda arah urutan, masing-masing 43 MB. B-Tree dapat dibaca
   maju maupun mundur, jadi salah satu cukup — dan kebetulan yang `DESC` justru tidak pernah
   dipakai. Hemat **43 MB**. Keduanya lahir dari dua berkas berbeda (Q12 dan Q19), contoh
   nyata bagaimana index kembar muncul di proyek yang dikerjakan beramai-ramai.
3. `ev_salah_idx (terjadi_pada, customer_id)` memuat `terjadi_pada` di depan, sehingga query
   rentang waktu sudah terlayani index waktu yang 43 MB. Ia 60 MB dengan `idx_scan` 1.

**Ringkasan penghematan.** Menghapus `ev_terjadi_pada_idx` (43 MB), `ev_salah_idx` (60 MB),
`ev_benar_idx` (60 MB), dan `ev_email_lower_idx` (86 MB) memangkas **249 MB dari 438 MB**.
Jejak index turun menjadi sekitar 189 MB, yaitu **41% dari heap, bukan 95,8%**, dan setiap
INSERT ikut lebih ringan karena hanya delapan struktur yang diperbarui, bukan dua belas.
Bila `idx_btree_terjadi` juga diganti BRIN — Q20 menunjukkan selisihnya hanya 1,3 ms dengan
**205 buffer lebih sedikit** — penghematannya menjadi 292 MB, dan jejak index tinggal 32% heap.

**Q31 · Reflektif.** *Untuk setiap index yang direkomendasikan dihapus atau dipertahankan,
sebutkan satu angka sebagai dasar keputusan.*

| Index | Keputusan | Satu angka dasarnya |
|---|---|---|
| `event_log_pkey` | dipertahankan | `idx_scan` **9** dan satu-satunya penjaga keunikan `event_id` |
| `ev_cover3_idx` | dipertahankan | menyerap pekerjaan `ev_benar_idx`, menghemat **60 MB** |
| `ev_gagal_idx` | dipertahankan | **896 kB** = 0,19% heap, 97,96% lebih kecil daripada index polos sekolom |
| `idx_gin_tags` | dipertahankan | **1,00% heap** melayani 500.000 baris `tags @>` yang 1,7 kali lebih cepat daripada Seq Scan |
| `idx_gin_payload` | dipertahankan | **1,51% heap**, query `payload @>` 2,3 kali lebih cepat (141,8 ms lawan 325,6 ms) |
| `idx_brin_terjadi` | dipertahankan | **32 kB**, 1.372 kali lebih kecil daripada B-Tree sekolom |
| `idx_status` | ditinjau ulang | **84%** baris bernilai `SUKSES`; pada fraksi itu optimizer memilih Seq Scan |
| `idx_btree_terjadi` | ditinjau ulang | **43 MB** untuk keunggulan 1,3 ms atas BRIN yang 32 kB |
| `ev_benar_idx` | dihapus, digabung | **60 MB** untuk kolom kunci yang sudah jadi awalan index lain |
| `ev_terjadi_pada_idx` | dihapus | `idx_scan` **0** untuk **43 MB**, kembar dengan index yang terpakai |
| `ev_salah_idx` | dihapus | `idx_scan` **1** untuk **60 MB** |
| `ev_email_lower_idx` | dihapus | **86 MB** (18,84% heap) untuk 3 kali pakai yang membaca **3 baris** |

**Pola keputusannya.** Index dipertahankan bila manfaatnya terukur dan ruangnya kecil relatif
heap, atau bila ia menjaga integritas — bukan karena "mungkin berguna nanti". Index dihapus
bila `idx_scan` nol, bila kolom kuncinya sudah jadi awalan index lain, atau bila rasio
ruang-terhadap-manfaatnya buruk seperti 86 MB untuk tiga baris terbaca. Yang paling perlu
dicatat: **pemakaian tinggi bukan alasan otomatis mempertahankan.** `ev_benar_idx` adalah
index tersibuk di skema ini dengan 18 pemakaian, tetapi tetap layak dihapus karena ada index
lain yang mengerjakan hal yang sama. Dua angka yang membingkai seluruh keputusan di atas:
index `event_log` memakan **95,8% ruang heap**, dan INSERT dengan lima index **535,0% lebih
lambat** daripada tanpa index. Index bukan hadiah gratis; ia dibayar dua kali, di ruang
penyimpanan dan di setiap operasi tulis.

---

## Tabel Perbandingan

Seluruh angka di bawah ini dihasilkan ulang dari `explain/*.txt` dengan
`rangkum_pengukuran.py`, dari satu rangkaian Q0–Q30 yang dijalankan di satu mesin pada
25 Oktober 2026. Setiap query dijalankan tiga kali; yang dilaporkan tercepat dan median.

| Query / keadaan | Node | Tercepat | Median | Buffers | Keputusan |
|---|---|---:|---:|---:|---|
| Q7 tanpa index | Seq Scan + Sort | 92,366 ms | 93,084 ms | 58.572 | garis dasar |
| Q8 `(terjadi_pada, customer_id)` | Index Scan Backward | 9,847 ms | 10,408 ms | 3.825 | Sort hilang, pembacaan masih besar |
| Q9 `(customer_id, terjadi_pada DESC)` | Index Scan | **0,020 ms** | 0,021 ms | **18** | urutan kolom yang benar |
| Q12 `status='GAGAL'` lewat partial index | Index Scan `ev_gagal_idx` | 0,012 ms | 0,020 ms | 22 | 896 kB melayani 2% baris |
| Q13 `email = ...` | Seq Scan | 107,902 ms | 108,698 ms | 58.569 | index ekspresi tidak cocok |
| Q13 `lower(email) = ...` | Index Scan `ev_email_lower_idx` | **0,012 ms** | 0,014 ms | **4** | ekspresi cocok persis |
| Q14 sebelum VACUUM (dipaksa index-only) | Index Only Scan | 0,009 ms | 0,013 ms | 6 | Heap Fetches 33 |
| Q14 sesudah `VACUUM (ANALYZE)` | Index Only Scan | 0,013 ms | 0,014 ms | **5** | Heap Fetches **0** |
| Q15 `INCLUDE` + `ORDER BY` kolom kedua | Sort + Index Only Scan | 0,017 ms | 0,020 ms | 8 | perlu Sort |
| Q15 tiga kolom + `ORDER BY` kolom kedua | Index Only Scan | 0,010 ms | 0,015 ms | 4 | tanpa Sort |
| Q17 `payload @> promo` dengan GIN | Bitmap Heap Scan | 141,800 ms | 143,347 ms | 58.588 | 2,3 kali lebih cepat |
| Q17 tanpa GIN | Seq Scan | 325,603 ms | — | 58.570 | pembanding |
| Q18 satu tag dengan GIN | Bitmap Heap Scan | 181,403 ms | 183,068 ms | 58.646 | 1,7 kali lebih cepat |
| Q18 satu tag tanpa GIN | Seq Scan | 308,972 ms | 313,200 ms | 58.570 | pembanding |
| Q18 dua tag dengan GIN | Bitmap Heap Scan | 164,708 ms | 166,411 ms | 58.818 | makin selektif makin unggul |
| Q20 rentang 7 hari, BRIN | Bitmap Heap Scan | 5,066 ms | 5,466 ms | **1.491** | 32 kB |
| Q20 rentang 7 hari, B-Tree | Index Scan `idx_btree_terjadi` | **4,003 ms** | 4,143 ms | 1.696 | 43 MB |
| Q22 `status='GAGAL'` (2%) | Index Scan `ev_gagal_idx` | 64,226 ms | 67,643 ms | 40.098 | index dipakai |
| Q22 `status='TERTUNDA'` (14%) | Bitmap Heap Scan | 120,183 ms | 131,808 ms | 58.812 | jalur tengah |
| Q22 `status='SUKSES'` (84%) | Seq Scan | 157,416 ms | 160,374 ms | 58.570 | index diabaikan |
| Q22 `SUKSES` dipaksa memakai index | Bitmap Heap Scan | 230,398 ms | — | 59.987 | 44% lebih lambat |
| Q23 di bawah titik peralihan (34%) | Bitmap Heap Scan | 188,980 ms | 195,137 ms | 60.869 | index menang menurut optimizer |
| Q23 di atas titik peralihan (50%) | Seq Scan | 142,639 ms | 143,020 ms | 58.570 | Seq Scan menang |
| Q24 `SUKSES` dengan `random_page_cost`=1.1 | Seq Scan | 160,090 ms | 166,909 ms | 58.570 | tetap Seq Scan |
| Q25 sebelum extended statistics | Seq Scan | 106,790 ms | 109,509 ms | 58.570 | estimasi 9.117 |
| Q25 sesudah `ANALYZE` | Seq Scan | 106,704 ms | 106,941 ms | 58.570 | estimasi 44.730 |
| Q27 INSERT 200.000 tanpa index | — | 124,5 ms | 147,8 ms | — | garis dasar tulis |
| Q27 INSERT 200.000 dengan 5 index | — | 908,4 ms | 938,6 ms | — | **535,0% lebih lambat** |

Dua hal yang terbaca dari tabel ini sebagai satu kesatuan. Pertama, **kemenangan index tidak
seragam**: pada Q9 dan Q13 selisihnya ribuan kali, pada Q17 dan Q18 hanya dua kali, dan pada
Q22 `SUKSES` index justru kalah. Yang membedakan bukan jenis indexnya melainkan berapa banyak
halaman heap yang tetap harus dibaca — pada Q17 dan Q18 baris yang cocok tersebar di hampir
seluruh 58.570 halaman, sehingga index hanya menghemat biaya menguji operator, bukan biaya
membaca. Kedua, **buffer lebih stabil daripada waktu** sebagai ukuran: Q20 memperlihatkan BRIN
membaca 205 buffer lebih sedikit tetapi tetap sedikit lebih lambat, karena selisih 1,3 ms itu
jatuh di wilayah derau mesin.

## Rekomendasi Akhir

Dasar angkanya: seluruh index `event_log` memakan **438 MB atau 95,8% dari heap** (458 MB),
dan INSERT 200.000 baris dengan lima index **535,0% lebih lambat** daripada tanpa index.

| Index | Keputusan | Angka dasar keputusan |
|---|---|---|
| `event_log_pkey` (43 MB) | dipertahankan | `idx_scan` 9, sekaligus penjaga keunikan |
| `ev_cover3_idx` (77 MB) | dipertahankan sebagai gabungan | menyerap `ev_benar_idx`, hemat 60 MB |
| `ev_gagal_idx` (896 kB) | dipertahankan | 0,19% heap, 97,96% lebih kecil dari index polos |
| `idx_gin_tags` (4.664 kB) | dipertahankan | 1,00% heap untuk 500.000 baris `tags @>` |
| `idx_gin_payload` (7.096 kB) | dipertahankan | 1,51% heap, query 2,3 kali lebih cepat |
| `idx_brin_terjadi` (32 kB) | dipertahankan | 0,01% heap, 1.372 kali lebih kecil dari B-Tree sekolom |
| `idx_status` (13 MB) | ditinjau ulang | 84% baris `SUKSES`, dan di fraksi itu optimizer memilih Seq Scan |
| `idx_btree_terjadi` (43 MB) | ditinjau ulang | unggul 1,3 ms atas BRIN, tetapi 1.372 kali lebih besar |
| `ev_benar_idx` (60 MB) | digabung ke `ev_cover3_idx` | kolom kuncinya awalan index yang lebih lebar |
| `ev_terjadi_pada_idx` (43 MB) | dihapus | `idx_scan` 0, kembar dengan `idx_btree_terjadi` |
| `ev_salah_idx` (60 MB) | dihapus | `idx_scan` 1 |
| `ev_email_lower_idx` (86 MB) | dihapus | 18,84% heap untuk 3 baris terbaca |
| `hot_*`, `tulis_*` | dihapus bersama tabel ujinya | tabel bantu Q4, Q6, dan Q27 |

**Total penghematan: 249 MB dari 438 MB**, sehingga jejak index turun ke sekitar 189 MB atau
41% dari heap. Bila `idx_btree_terjadi` ikut diganti BRIN, penghematannya 292 MB dan jejak
index tinggal 32% heap.

**Urutan eksekusi yang disarankan.** Hapus dulu yang `idx_scan`-nya nol atau satu
(`ev_terjadi_pada_idx`, `ev_salah_idx`) karena risikonya paling kecil. Lalu hapus
`ev_benar_idx` dan amati apakah rencana query pelanggan berpindah mulus ke `ev_cover3_idx`.
`ev_email_lower_idx` dihapus terakhir setelah dipastikan tidak ada fitur pencarian email yang
memakainya — 86 MB itu menggoda, tetapi satu fitur login yang terlewat akan berubah menjadi
Seq Scan 107 ms untuk setiap percobaan masuk.

## Penggunaan AI dan Verifikasi

| Anggota | Bantuan AI yang dipakai | Cara memverifikasi |
|---|---|---|
| Viter Moldy Kesuma | Claude (Anthropic) untuk menyusun draf `q00_setup.sql`, `q01_ukuran_tabel.sql`, berkas Q27–Q30, `rangkum_pengukuran.py`, `README.md`, dan kerangka `laporan.md` | Seluruh berkas dijalankan ulang di laptop sendiri (PostgreSQL 17.11 di Docker) dan keluarannya disimpan apa adanya di `explain/`. Setiap angka pada laporan disalin dari berkas bukti itu, bukan dari contoh keluaran AI. Dua galat yang ditemukan saat menjalankan ulang seluruh rangkaian dari nol (`idx_brin_terjadi` tidak pernah dibuat dan `idx_gin_payload` tanpa skema) ditelusuri sampai berkas penyebabnya dan dilaporkan apa adanya pada Q30. |
| Gideon Finsus Siburian | «isi sendiri» | «isi sendiri» |
| Nadine Tantiara Hutagaol | «isi sendiri» | «isi sendiri» |
| Rizky Cristian Fero Sihombing | «isi sendiri» | «isi sendiri» |
| Siti Naifah Batubara | «isi sendiri» | «isi sendiri» |
