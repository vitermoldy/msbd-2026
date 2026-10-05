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

> «Belum diisi.»

**Q3 · TOAST.** Cantumkan `attstorage` setiap kolom, sebutkan kolom yang bernilai `x` atau `e`,
dan jelaskan akibatnya pada `SELECT *`.

> «Belum diisi.»

**Q4 · HOT update.** Berkas: `q04_hot_update.sql`. Cantumkan `n_tup_upd` dan `n_tup_hot_upd`
untuk `hot_penuh` (fillfactor 100) dan `hot_longgar` (fillfactor 80).

> «Belum diisi.»

**Q5 · Harga fillfactor.** Cantumkan ukuran kedua tabel sebelum dan sesudah UPDATE, lalu
jelaskan ruang yang dibayar demi peluang HOT update.

> «Belum diisi.»

**Q6 · Reflektif.** *Bandingkan UPDATE kolom terindeks dan tidak terindeks. Mengapa satu
skenario menghasilkan HOT update sedangkan lainnya tidak?*

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

**Q17 · GIN untuk JSONB.** Berkas: `q17_gin_jsonb.sql`. Apakah GIN dipakai, dan bagaimana
ukurannya dibanding heap?

> «Belum diisi.»

**Q18 · GIN untuk array.** Berkas: `q18_gin_array.sql`. Bandingkan rencana dengan dan tanpa GIN.

> «Belum diisi.»

**Q19 · Correlation dan ukuran.** Berkas: `q19_brin_vs_btree.sql`. Cantumkan `correlation`
`terjadi_pada` dari `pg_stats` dan ukuran BRIN dibanding B-Tree pada kolom yang sama.

> «Belum diisi.»

**Q20 · Rentang tujuh hari.** Berkas: `q20_brin_rentang.sql`. Catat pemenang dan selisih Buffers.

| Index | Node | Tercepat | Median | Buffers | Ukuran index |
|---|---|---:|---:|---:|---:|
| BRIN | | | | | |
| B-Tree | | | | | |

**Q21 · Reflektif.** *Kapan penghematan ukuran BRIN sepadan dengan selisih waktunya?*

> «Belum diisi.»

### Langkah 6 · Statistik, selektivitas, dan Seq Scan

**Q22 · Rencana per status.** Berkas: `q22_index_status.sql`. Salin rencana untuk `SUKSES` dan
`GAGAL`.

> «Belum diisi.»

**Q23 · Titik peralihan.** Berkas: `q23_selektivitas.sql`. Cantumkan fraksi tiap status dan
fraksi tempat optimizer berpindah dari Index Scan ke Seq Scan.

> «Belum diisi.»

**Q24 · `random_page_cost = 1.1`.** Berkas: `q24_random_page_cost.sql`. Jelaskan pergeseran
titik peralihan, dan buktikan `RESET` sudah dijalankan.

> «Belum diisi.»

**Q25 · Extended statistics.** Berkas: `q25_extended_statistics.sql`. Bandingkan estimasi baris
dengan kenyataan, sebelum dan sesudah `ANALYZE`.

> «Belum diisi.»

**Q26 · Reflektif.** *Pilih satu status untuk index dan satu untuk Seq Scan; jelaskan mengapa
titik peralihannya bukan angka tetap.*

> «Belum diisi.»

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
