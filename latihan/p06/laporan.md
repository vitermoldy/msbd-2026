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
| Tanggal pengerjaan | «…» |

> **Status laporan.** Bagian yang sudah terisi ditandai dengan angka dan keluaran asli dari
> `explain/`. Bagian yang belum ditandai «Belum diisi» beserta penanggung jawabnya. Tidak ada
> kotak yang diisi dengan angka perkiraan.

---

## Identitas Kelompok dan Kontribusi

| Nama | NIM | Kontribusi Pertemuan 6 | Commit |
|---|---|---|---|
| Viter Moldy Kesuma | 251402079 | «langkah …» | «…» |
| Gideon Finsus Siburian | 251402038 | «langkah …» | «…» |
| Nadine Tantiara Hutagaol | 251402050 | «langkah …» | «…» |
| Rizky Cristian Fero Sihombing | 251402056 | «langkah …» | «…» |
| Siti Naifah Batubara | 251402067 | «langkah …» | «…» |

---

## Kondisi Uji

| Hal | Nilai |
|---|---|
| Versi PostgreSQL | «SELECT version();» |
| Mesin pengukur | «CPU, RAM, jenis disk» |
| `shared_buffers` | «SHOW shared_buffers;» |
| `max_parallel_workers_per_gather` | 0 pada seluruh sesi ukur |
| `random_page_cost` | 4 (bawaan); 1.1 hanya di Q24, lalu di-RESET |
| Jumlah pengulangan | 3 kali per query, dilaporkan tercepat dan median |
| Jumlah baris `lab6.event_log` | «count(*)» |
| Penyesuaian dari soal | «tulis di sini bila jumlah baris diturunkan dari dua juta» |

Seluruh percobaan hanya menyentuh skema `lab6`. Tidak ada index pada skema `public` Pagila
yang dibuat, diubah, atau dihapus.

---

## Q1–Q31

### Langkah 1 · Memuat dua juta baris

**Q1 · Ukuran tabel dan byte per baris.** Berkas: `q00_setup.sql`, `q01_ukuran_tabel.sql`.
Cantumkan ukuran heap, index, dan total; byte per baris hasil pembagian; serta perbandingannya
dengan perkiraan dari `avg(pg_column_size(...))` tiap kolom ditambah 23 byte header tuple dan
4 byte line pointer.

> «Belum diisi.»

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
