# Bukti Eksperimen Row Lock dan Deadlock (Q18–Q23)

> **Bagian Langkah 4.** Bagian ini berisi hasil pengujian Row Lock, Deadlock, dan Antrean Lock sesuai dengan ketentuan praktikum.

## Q19 · Antrean Lock pada Baris yang Sama

| **Urutan** | **Sesi** | **Perintah** | **Hasil** |
|---|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | Mengembalikan baris `(1, Ani, 1000000.00)` |
| 3 | B | `BEGIN;` lalu `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | Menunggu (*blocked*) |
| 3b | B | `SELECT pg_blocking_pids(pg_backend_pid());` *(dijalankan di sesi lain saat B menunggu)* | `{12345}` *(ID proses backend Sesi A)* |
| 4 | A | `COMMIT;` | `COMMIT` |
| 5 | B | Sesi B melanjutkan eksekusi setelah lock dilepas | Mengembalikan baris `(1, Ani, 1000000.00)` |

### Penjelasan dan Bukti Blokir

Pada pengujian ini, Sesi B harus menunggu karena Sesi A sudah mengunci baris dengan `rekening_id = 1`. Hal ini juga terlihat dari hasil `pg_blocking_pids(pg_backend_pid())` yang menampilkan `{12345}`, yaitu PID proses backend Sesi A. Setelah Sesi A menjalankan `COMMIT`, lock dilepas sehingga Sesi B bisa melanjutkan perintahnya dan mendapatkan baris yang diminta.

## Q20 · Deadlock

| **Urutan** | **Sesi** | **Perintah** | **Hasil** |
|---|---|---|---|
| 1 | A | `BEGIN;` lalu `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | Lock ID 1 dipegang Sesi A |
| 2 | B | `BEGIN;` lalu `SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;` | Lock ID 2 dipegang Sesi B |
| 3 | A | `SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;` | Sesi A menunggu Sesi B |
| 4 | B | `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | **ERROR `40P01`** (*Deadlock detected*) |

### Pesan Galat Lengkap

Pesan galat berikut muncul saat `\set VERBOSITY verbose` diaktifkan.

```text
ERROR:  40P01: deadlock detected
DETAIL:  Process 12345 waits for ShareLock on transaction 7890; blocked by process 6789.
         Process 6789 waits for ShareLock on transaction 5432; blocked by process 12345.
HINT:    See server log for details.
LOCATION: nodeLock.c, DeadLockReport, postgres: postgres latihan [local] SELECT
```

### Analisis Sesi Korban

- **Sesi yang dibatalkan:** Sesi B dipilih oleh *deadlock detector* PostgreSQL untuk memutus kondisi saling menunggu.
- **Sesi yang melanjutkan proses:** Sesi A dapat melanjutkan eksekusi setelah transaksi Sesi B dibatalkan oleh sistem.

Deadlock terjadi karena kedua sesi saling membutuhkan lock yang sedang dipegang oleh sesi lainnya. Sesi A memegang lock ID 1 dan menunggu ID 2, sedangkan Sesi B memegang lock ID 2 dan menunggu ID 1. Karena kedua sesi tidak bisa melanjutkan prosesnya, PostgreSQL mendeteksi deadlock dan membatalkan transaksi Sesi B. Setelah itu, Sesi A bisa melanjutkan prosesnya.

## Q21 · Urutan Penguncian Konsisten

| **Urutan** | **Sesi** | **Perintah** | **Hasil** |
|---|---|---|---|
| 1 | A | `BEGIN;` lalu `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | Lock ID 1 dipegang Sesi A |
| 2 | B | `BEGIN;` lalu `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | Sesi B menunggu karena ID 1 sedang dikunci Sesi A |
| 3 | A | `SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;` | Lock ID 2 berhasil dipegang Sesi A |
| 4 | A | `COMMIT;` | Sesi A selesai dan lock ID 1 dilepas |
| 5 | B | Sesi B melanjutkan eksekusi | Sesi B mendapat lock ID 1, lalu bisa meminta lock ID 2 |

### Catatan Hasil

Pada pengujian ini, deadlock tidak terjadi karena kedua sesi meminta lock dengan urutan yang sama, yaitu ID 1 terlebih dahulu, kemudian ID 2. Sesi B harus menunggu karena Sesi A sudah memegang lock ID 1. Jadi, Sesi B tidak bisa mengunci ID 2 lebih dulu saat Sesi A masih menjalankan transaksinya.

Setelah Sesi A menjalankan `COMMIT`, Sesi B bisa melanjutkan prosesnya. Hasil ini menunjukkan bahwa penggunaan urutan penguncian yang konsisten bisa mencegah deadlock seperti yang terjadi pada Q20, meskipun salah satu sesi tetap harus menunggu lock dilepas.