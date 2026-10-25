# Hasil Pengukuran P06

## Kondisi uji

| Hal | Nilai |
|---|---|
| Versi PostgreSQL | PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, 64-bit |
| Basis data | `pagila`, skema kerja `lab6`, pada kontainer Docker `msbd-pg` |
| Mesin | Intel Core Ultra 9 275HX, 24 core / 24 thread, RAM 31,4 GB, Windows + Docker Desktop |
| `shared_buffers` | 128MB (bawaan kontainer) |
| `max_parallel_workers_per_gather` | bawaan 2; disetel **0** pada berkas pengukuran |
| `random_page_cost` | 4 (bawaan); 1.1 hanya pada Q24, lalu `RESET` |
| Jumlah pengulangan | 3 kali per query; dilaporkan tercepat dan median |
| Jumlah baris `lab6.event_log` | 2.000.000 (`INSERT 0 2000000`) |
| Halaman heap | 58.572 (`relpages`), 34,15 baris per halaman |

## Waktu dan Buffers

Tabel ini dapat dihasilkan ulang dari berkas bukti:

```bat
python latihan\p06\rangkum_pengukuran.py latihan\p06\explain
```

| Query / keadaan | Node | Tercepat | Median | Buffers |
|---|---|---:|---:|---|
| Q17 `payload @> '{"promo": true}'` dengan GIN | Bitmap Heap Scan | 1.548,401 ms | — | hit=2 read=58.585 |
| Q18 `tags @> ARRAY['kanal:1']` dengan GIN | Bitmap Heap Scan | 297,229 ms | 321,077 ms | hit=1 read=58.641 |
| Q18 tanpa GIN | Seq Scan | 531,721 ms | 582,267 ms | hit=16.344 read=42.222 |
| Q20 rentang tujuh hari, BRIN | Bitmap Heap Scan | 11,276 ms | 13,864 ms | hit=1.417 read=1 |
| Q20 rentang tujuh hari, B-Tree | Index Scan | 11,189 ms | 11,342 ms | hit=1.678 |
| Q22 `status='GAGAL'` (2%) | Index Scan | 108,216 ms | 138,654 ms | — |
| Q22 `status='SUKSES'` (84%) | Seq Scan | 319,486 ms | 361,549 ms | — |
| Q24 `SUKSES` dengan `random_page_cost`=1.1 | Seq Scan | 341,589 ms | 498,867 ms | — |

Baris Q7–Q16 menyusul dari jawaban Langkah 3 dan Langkah 4; berkas buktinya sudah ada di
`explain/`.

## Ukuran index pada `lab6.event_log`

Heap 458 MB, seluruh index 434 MB (**94,7% dari heap**), total relasi 891 MB.

| Index | Jenis | `idx_scan` | Ukuran | % heap |
|---|---|---:|---:|---:|
| `ev_email_lower_idx` | B-Tree ekspresi `lower(email)` | 1 | 86 MB | 18,84 |
| `ev_cover3_idx` | B-Tree `(customer_id, terjadi_pada, jumlah)` | 1 | 77 MB | 16,91 |
| `ev_benar_idx` | B-Tree `(customer_id, terjadi_pada DESC)` | 1 | 60 MB | 13,15 |
| `ev_salah_idx` | B-Tree `(terjadi_pada, customer_id)` | **0** | 60 MB | 13,13 |
| `ev_terjadi_pada_idx` | B-Tree `(terjadi_pada DESC)` | 1 | 43 MB | 9,37 |
| `idx_btree_terjadi` | B-Tree `(terjadi_pada)` | 1 | 43 MB | 9,37 |
| `event_log_pkey` | B-Tree unik `(event_id)` | 6 | 43 MB | 9,37 |
| `idx_status` | B-Tree `(status)` | 1 | 13 MB | 2,90 |
| `idx_gin_payload` | GIN `payload jsonb_path_ops` | 1 | 7.096 kB | 1,51 |
| `ev_gagal_idx` | B-Tree partial `status='GAGAL'` | 1 | 896 kB | 0,19 |

Seluruh skema `lab6`: **17 index, 461 MB**, dan **8 index (88 MB) belum pernah dipakai**.

## Harga tulis (Q27–Q28)

INSERT 200.000 baris, tabel berstruktur sama, satu polos dan satu dengan lima index:

| Keadaan | Ulangan 1 | Ulangan 2 | Ulangan 3 | Tercepat | Median |
|---|---:|---:|---:|---:|---:|
| Tanpa index | 143,4 ms | 148,0 ms | 126,0 ms | **126,0 ms** | **143,4 ms** |
| Lima index | 987,5 ms | 942,0 ms | 998,7 ms | **942,0 ms** | **987,5 ms** |
| Lebih lambat | 588,6% | 536,5% | 692,6% | 647,6% | **588,6%** |

Ukuran kedua tabel sesudah pengujian:

| Tabel | Heap | Index | Total | Selisih |
|---|---:|---:|---:|---:|
| `tulis_tanpa_index` | 45 MB | 0 byte | 45 MB | — |
| `tulis_lima_index` | 45 MB | 27 MB | 72 MB | **+58,5%** |

Rincian kelima index: ekspresi `lower(email)` 14 MB · B-Tree majemuk 8.312 kB · GIN
`jsonb_path_ops` 4.808 kB · partial 176 kB · BRIN 24 kB.

## Tabel keputusan (Q29–Q30)

| Index | `idx_scan` | Ukuran | Keputusan | Angka dasarnya |
|---|---:|---:|---|---|
| `event_log_pkey` | 6 | 43 MB | dipertahankan | terbanyak dipakai, menjaga keunikan |
| `ev_gagal_idx` | 1 | 896 kB | dipertahankan | 0,19% heap |
| `idx_gin_payload` | 1 | 7.096 kB | dipertahankan | 1,51% heap untuk 80.000 baris |
| `ev_cover3_idx` | 1 | 77 MB | dipertahankan sebagai gabungan | menyerap `ev_benar_idx` |
| `ev_benar_idx` | 1 | 60 MB | digabung | kolom kuncinya awalan `ev_cover3_idx` |
| `ev_terjadi_pada_idx` | 1 | 43 MB | digabung | kembar dengan `idx_btree_terjadi` |
| `idx_status` | 1 | 13 MB | ditinjau ulang | 84% baris `SUKSES` |
| `ev_salah_idx` | **0** | 60 MB | dihapus | tidak pernah dipakai |
| `ev_email_lower_idx` | 1 | 86 MB | dihapus | 18,84% heap untuk 1 baris terbaca |

Penghematan bila kandidat hapus dieksekusi: **249 MB dari 434 MB**, jejak index turun ke
sekitar 185 MB (40% dari heap).

## Catatan reproduksi

Saat seluruh rangkaian dijalankan ulang dari nol di satu mesin, dua galat muncul dan keduanya
berasal dari berkas Langkah 5:

```text
ERROR:  relation "idx_gin_payload" does not exist
ERROR:  relation "lab6.idx_brin_terjadi" does not exist
```

Yang pertama karena nama index ditulis tanpa skema pada `q17_gin_payload.sql`. Yang kedua
karena tidak ada berkas yang membuat index BRIN, sehingga angka BRIN pada Q19–Q20 belum dapat
direproduksi dari repositori. Keduanya perlu diperbaiki sebelum pengumpulan.
