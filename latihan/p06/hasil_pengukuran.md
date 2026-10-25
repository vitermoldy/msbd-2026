# Hasil Pengukuran P06

Seluruh angka pada berkas ini berasal dari satu rangkaian Q0–Q30 yang dijalankan dari nol di
satu mesin pada 25 Oktober 2026, dan dapat dihasilkan ulang dengan:

```bat
python latihan\p06\rangkum_pengukuran.py latihan\p06\explain
```

## Kondisi uji

| Hal | Nilai |
|---|---|
| Versi PostgreSQL | PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, 64-bit |
| Basis data | `pagila`, skema kerja `lab6`, pada kontainer Docker `msbd-pg` |
| Mesin | Intel Core Ultra 9 275HX, 24 core / 24 thread, RAM 31,4 GB, Windows + Docker Desktop |
| `shared_buffers` | 128MB (bawaan kontainer) |
| `max_parallel_workers_per_gather` | **0** pada setiap berkas pengukuran |
| `random_page_cost` | 4 (bawaan); 1.1 hanya pada Q24, lalu `RESET` |
| Jumlah pengulangan | **3 kali per query**; dilaporkan tercepat dan median |
| Jumlah baris `lab6.event_log` | 2.000.000 |
| Halaman heap | 58.569–58.572 (`relpages`), 34,15 baris per halaman |

## Waktu dan Buffers

| Query / keadaan | Node | n | Tercepat | Median | Buffers |
|---|---|---:|---:|---:|---:|
| Q7 baseline tanpa index | Seq Scan + Sort | 3 | 92,366 ms | 93,084 ms | 58.572 |
| Q8 `(terjadi_pada, customer_id)` | Index Scan Backward | 3 | 9,847 ms | 10,408 ms | 3.825 |
| Q9 `(customer_id, terjadi_pada DESC)` | Index Scan | 3 | **0,020 ms** | 0,021 ms | **18** |
| Q12 partial index `status='GAGAL'` | Index Scan | 3 | 0,012 ms | 0,020 ms | 22 |
| Q13a `email = ...` | Seq Scan | 3 | 107,902 ms | 108,698 ms | 58.569 |
| Q13b `lower(email) = ...` | Index Scan | 3 | **0,012 ms** | 0,014 ms | **4** |
| Q13c `upper(email) = ...` | Seq Scan | 1 | 350,281 ms | — | 58.569 |
| Q14a sebelum VACUUM, apa adanya | Index Only Scan | 3 | 0,015 ms | 0,019 ms | 40 |
| Q14b sebelum VACUUM, dipaksa | Index Only Scan | 3 | 0,009 ms | 0,013 ms | 6 |
| Q14c sesudah `VACUUM (ANALYZE)` | Index Only Scan | 3 | 0,013 ms | 0,014 ms | 5 |
| Q15a `INCLUDE` + `ORDER BY` | Sort + Index Only Scan | 3 | 0,017 ms | 0,020 ms | 8 |
| Q15c tiga kolom + `ORDER BY` | Index Only Scan | 3 | 0,010 ms | 0,015 ms | 4 |
| Q17 `payload @>` dengan GIN | Bitmap Heap Scan | 3 | 141,800 ms | 143,347 ms | 58.588 |
| Q17 tanpa GIN | Seq Scan | 1 | 325,603 ms | — | 58.570 |
| Q18a satu tag dengan GIN | Bitmap Heap Scan | 3 | 181,403 ms | 183,068 ms | 58.646 |
| Q18b dua tag dengan GIN | Bitmap Heap Scan | 3 | 164,708 ms | 166,411 ms | 58.818 |
| Q18c satu tag tanpa GIN | Seq Scan | 3 | 308,972 ms | 313,200 ms | 58.570 |
| Q20a rentang 7 hari, BRIN | Bitmap Heap Scan | 3 | 5,066 ms | 5,466 ms | **1.491** |
| Q20b rentang 7 hari, B-Tree | Index Scan | 3 | **4,003 ms** | 4,143 ms | 1.696 |
| Q22a `SUKSES` (84%) | Seq Scan | 3 | 157,416 ms | 160,374 ms | 58.570 |
| Q22b `GAGAL` (2%) | Index Scan | 3 | 64,226 ms | 67,643 ms | 40.098 |
| Q22c `TERTUNDA` (14%) | Bitmap Heap Scan | 3 | 120,183 ms | 131,808 ms | 58.812 |
| Q22d `SUKSES` dipaksa index | Bitmap Heap Scan | 1 | 230,398 ms | — | 59.987 |
| Q23 di bawah titik peralihan | Bitmap Heap Scan | 2 | 188,980 ms | 195,137 ms | 60.869 |
| Q23 di atas titik peralihan | Seq Scan | 2 | 142,639 ms | 143,020 ms | 58.570 |
| Q24c `SUKSES`, `random_page_cost`=1.1 | Seq Scan | 3 | 160,090 ms | 166,909 ms | 58.570 |
| Q25a sebelum extended statistics | Seq Scan | 2 | 106,790 ms | 109,509 ms | 58.570 |
| Q25b sesudah `ANALYZE` | Seq Scan | 2 | 106,704 ms | 106,941 ms | 58.570 |

## Anatomi penyimpanan (Q1–Q6)

| Ukuran | Nilai |
|---|---:|
| Heap `event_log` | 458 MB |
| Byte per baris | 239,9 |
| Tuple per halaman (rata-rata) | 34,15 (batas teoretis 291) |
| HOT update fillfactor 100 | **0** dari 10.000 |
| HOT update fillfactor 80 | **2.560** dari 10.000 (25,60%) |
| Ukuran sebelum → sesudah UPDATE, fillfactor 100 | 512 kB → 1.024 kB (+100%) |
| Ukuran sebelum → sesudah UPDATE, fillfactor 80 | 640 kB → 1.120 kB (+75%) |
| UPDATE 5.000 baris kolom terindeks | +0 HOT |
| UPDATE 5.000 baris kolom tidak terindeks | +2.977 HOT |

## Ukuran index pada `lab6.event_log`

Heap 458 MB, seluruh index 438 MB (**95,8% dari heap**), total relasi 896 MB.

| Index | Jenis | `idx_scan` | `idx_tup_read` | Ukuran | % heap |
|---|---|---:|---:|---:|---:|
| `ev_email_lower_idx` | B-Tree ekspresi `lower(email)` | 3 | 3 | 86 MB | 18,84 |
| `ev_cover3_idx` | B-Tree `(customer_id, terjadi_pada, jumlah)` | 6 | 32 | 77 MB | 16,91 |
| `ev_benar_idx` | B-Tree `(customer_id, terjadi_pada DESC)` | **18** | 8.550.606 | 60 MB | 13,15 |
| `ev_salah_idx` | B-Tree `(terjadi_pada, customer_id)` | 1 | 66 | 60 MB | 13,13 |
| `ev_terjadi_pada_idx` | B-Tree `(terjadi_pada DESC)` | **0** | 0 | 43 MB | 9,37 |
| `idx_btree_terjadi` | B-Tree `(terjadi_pada)` | 4 | 186.092 | 43 MB | 9,37 |
| `event_log_pkey` | B-Tree unik `(event_id)` | 9 | 2.200.005 | 43 MB | 9,37 |
| `idx_status` | B-Tree `(status)` | 5 | 4.520.000 | 13 MB | 2,90 |
| `idx_gin_payload` | GIN `payload jsonb_path_ops` | 4 | 320.000 | 7.096 kB | 1,51 |
| `idx_gin_tags` | GIN `tags` | 8 | 2.666.668 | 4.664 kB | 1,00 |
| `ev_gagal_idx` | B-Tree partial `status='GAGAL'` | 6 | 120.062 | 896 kB | 0,19 |
| `idx_brin_terjadi` | BRIN `terjadi_pada`, `pages_per_range=128` | 3 | 44.460 | **32 kB** | 0,01 |

Seluruh skema `lab6`: **20 index, 466 MB**, dengan **8 index (71 MB) belum pernah dipakai**.

### Mengapa kolom yang sama bisa berbeda ukuran (Q10)

| Penyebab | Varian | Ukuran |
|---|---|---:|
| Fillfactor | `(customer_id, terjadi_pada DESC)` bawaan 90 | 60 MB |
| | kolom sama, fillfactor 50 | **109 MB** |
| Deduplikasi | `(status)`, 3 nilai berulang | 13 MB |
| | `(status, event_id)`, setiap kunci unik | **63 MB** |
| Cara dibangun | diisi bertahap lewat INSERT acak | 19 MB (kerapatan 72,1%) |
| | dibangun sekaligus `CREATE INDEX` | **15 MB** (kerapatan 90,0%) |

## Selektivitas dan titik peralihan (Q22–Q24)

Fraksi status: GAGAL 2,00% · TERTUNDA 14,00% · SUKSES 84,00%.

Sapuan memakai `customer_id` sebagai keran selektivitas, agregat atas kolom `kota` yang tidak
ada di index mana pun:

| Fraksi baris | `random_page_cost` = 4 | `random_page_cost` = 1.1 |
|---|---|---|
| 20% | Bitmap Heap Scan | Index Scan |
| 30% | Bitmap Heap Scan | Index Scan |
| 34% | Bitmap Heap Scan | Index Scan |
| **36%** | **Seq Scan** | Index Scan |
| 40% | Seq Scan | Index Scan |
| 50% | Seq Scan | Index Scan |
| **60%** | Seq Scan | **Seq Scan** |

Titik peralihan bergeser dari **antara 34% dan 36%** menjadi **antara 50% dan 60%**, dan
bentuk rencananya ikut berubah dari Bitmap Heap Scan menjadi Index Scan biasa.

## Estimasi baris (Q25)

| Keadaan | Estimasi | Kenyataan | Kesalahan |
|---|---:|---:|---|
| Sebelum extended statistics | 9.117 | 44.445 | 4,9 kali terlalu kecil |
| Statistik dibuat, `ANALYZE` belum | 9.117 | 44.445 | tidak berubah |
| Sesudah `ANALYZE` | 44.730 | 44.445 | 0,6% terlalu besar |

## Harga tulis (Q27–Q28)

INSERT 200.000 baris, tabel berstruktur sama, satu polos dan satu dengan lima index:

| Keadaan | Ulangan 1 | Ulangan 2 | Ulangan 3 | Tercepat | Median |
|---|---:|---:|---:|---:|---:|
| Tanpa index | 147,8 ms | 153,4 ms | 124,5 ms | **124,5 ms** | **147,8 ms** |
| Lima index | 993,8 ms | 938,6 ms | 908,4 ms | **908,4 ms** | **938,6 ms** |
| Lebih lambat | 572,4% | 511,9% | 629,6% | 629,6% | **535,0%** |

| Tabel | Heap | Index | Total | Selisih |
|---|---:|---:|---:|---:|
| `tulis_tanpa_index` | 45 MB | 0 byte | 45 MB | — |
| `tulis_lima_index` | 45 MB | 27 MB | 72 MB | **+58,6%** |

Rincian kelima index: ekspresi `lower(email)` 14 MB · B-Tree majemuk 8.344 kB · GIN
`jsonb_path_ops` 4.792 kB · partial 176 kB · BRIN **24 kB**.

## Tabel keputusan (Q29–Q30)

| Index | `idx_scan` | Ukuran | Keputusan | Angka dasarnya |
|---|---:|---:|---|---|
| `event_log_pkey` | 9 | 43 MB | dipertahankan | penjaga keunikan |
| `ev_cover3_idx` | 6 | 77 MB | dipertahankan | menyerap `ev_benar_idx` |
| `ev_gagal_idx` | 6 | 896 kB | dipertahankan | 0,19% heap |
| `idx_gin_tags` | 8 | 4.664 kB | dipertahankan | 1,00% heap |
| `idx_gin_payload` | 4 | 7.096 kB | dipertahankan | 1,51% heap |
| `idx_brin_terjadi` | 3 | 32 kB | dipertahankan | 0,01% heap |
| `idx_status` | 5 | 13 MB | ditinjau ulang | 84% baris `SUKSES` |
| `idx_btree_terjadi` | 4 | 43 MB | ditinjau ulang | unggul 1,3 ms atas BRIN |
| `ev_benar_idx` | 18 | 60 MB | digabung | awalan `ev_cover3_idx` |
| `ev_terjadi_pada_idx` | **0** | 43 MB | dihapus | kembar, tak pernah dipakai |
| `ev_salah_idx` | 1 | 60 MB | dihapus | satu kali pakai |
| `ev_email_lower_idx` | 3 | 86 MB | dihapus | 3 baris terbaca |

Penghematan bila kandidat hapus dieksekusi: **249 MB dari 438 MB**, jejak index turun ke
sekitar 189 MB (41% dari heap); 292 MB bila `idx_btree_terjadi` ikut diganti BRIN.
