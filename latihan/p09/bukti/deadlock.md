# Bukti Eksperimen Row Lock dan Deadlock (Q18–Q23)

> **Bagian Langkah 4.** Kerangka ini disiapkan bersama Langkah 1–2 agar struktur folder
> `bukti/` sesuai ketentuan soal. Pengisiannya oleh anggota pemegang Langkah 4.

Pola pencatatan mengikuti `isolation-level.md`: satu tabel urutan per eksperimen, berisi kolom
**Urutan · Sesi · Perintah · Hasil**, lalu blok pesan galat apa adanya, lalu penjelasan sebab.

## Q19 · Antrean lock pada baris yang sama

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | |
| 2 | A | `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | |
| 3 | B | `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | *(menunggu)* |
| 4 | A | `COMMIT;` | |
| 5 | B | — | *(baris diperoleh)* |

Catat juga keluaran `SELECT pg_blocking_pids(pg_backend_pid());` yang dijalankan di Sesi B saat
masih menunggu, sebagai bukti bahwa yang menghalangi adalah backend Sesi A.

## Q20 · Deadlock

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` lalu kunci rekening 1 | |
| 2 | B | `BEGIN;` lalu kunci rekening 2 | |
| 3 | A | kunci rekening 2 | *(menunggu)* |
| 4 | B | kunci rekening 1 | **ERROR `40P01`?** |

Salin pesan galat lengkapnya (jalankan `\set VERBOSITY verbose` lebih dulu), termasuk baris
`DETAIL: Process … waits for ShareLock on transaction …` dan `HINT`, lalu sebutkan sesi mana
yang dibatalkan dan sesi mana yang lanjut.

## Q21 · Urutan penguncian konsisten

Ulangi Q20 dengan kedua sesi mengunci `rekening_id` dari kecil ke besar, lalu catat apakah
deadlock masih terjadi atau berubah menjadi antrean biasa.

## Q22–Q23

Q22 dan Q23 berupa penjelasan; dasarnya tetap bukti dari Q19–Q21 ditambah keluaran
`SHOW lock_timeout`, `SHOW statement_timeout`, `SHOW idle_in_transaction_session_timeout`, dan
`SHOW deadlock_timeout` yang sudah tercatat pada bagian Kondisi Uji `laporan.md`.
