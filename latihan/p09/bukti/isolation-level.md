# Bukti Eksperimen Isolation Level dan Anomali (Q6–Q11)

Seluruh percobaan di berkas ini dijalankan dengan **dua sesi psql terpisah** pada basis data
yang sama. Penanda `[A]` dan `[B]` menunjukkan sesi yang menjalankan perintah, dan urutan
baris adalah urutan waktu yang sebenarnya. Data dikembalikan ke kondisi awal
(`rekening 1 = 1.000.000`, `rekening 2 = 1.000.000`) sebelum dan sesudah setiap percobaan.

---

## Q6 · Non-repeatable read pada READ COMMITTED

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SHOW transaction_isolation;` | `read committed` |
| 3 | A | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | **1000000.00** |
| 4 | B | `UPDATE lab9.rekening SET saldo = saldo - 300000 WHERE rekening_id = 1;` | `UPDATE 1`, ter-commit otomatis |
| 5 | A | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | **700000.00** |
| 6 | A | `COMMIT;` | `COMMIT` |

**Hasil.** Dua pembacaan yang sama persis di dalam **satu transaksi** memberi dua nilai
berbeda: 1.000.000 lalu 700.000. Inilah *non-repeatable read*.

**Sebab.** Pada `READ COMMITTED`, PostgreSQL mengambil snapshot baru **pada setiap pernyataan**,
bukan sekali di awal transaksi. Begitu Sesi B commit di antara dua `SELECT` milik Sesi A,
pernyataan kedua memakai snapshot yang sudah memuat perubahan itu.

---

## Q7 · Skenario sama pada REPEATABLE READ

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | `BEGIN` |
| 2 | A | `SHOW transaction_isolation;` | `repeatable read` |
| 3 | A | `SELECT saldo ... rekening_id = 1;` | **1000000.00** |
| 4 | B | `UPDATE ... saldo = saldo - 300000 ... rekening_id = 1;` | `UPDATE 1`, ter-commit |
| 5 | A | `SELECT saldo ... rekening_id = 1;` | **1000000.00** (tidak berubah) |
| 6 | A | `UPDATE ... saldo = saldo - 1 ... rekening_id = 1;` | **ERROR `40001`** |
| 7 | A | `ROLLBACK;` | `ROLLBACK` |
| 8 | A | `SELECT saldo ... rekening_id = 1;` | **700000.00** (hasil Sesi B) |

Pesan galat pada langkah 6, dengan `\set VERBOSITY verbose`:

```text
ERROR:  40001: could not serialize access due to concurrent update
LOCATION:  ExecUpdate, nodeModifyTable.c
```

**Perbedaan dengan READ COMMITTED.** Snapshot diambil **sekali saja**, pada pernyataan pertama
transaksi, lalu dipertahankan sampai akhir. Karena itu pembacaan berulang selalu konsisten.

**Harga yang dibayar.** Konsistensi itu tidak gratis: begitu Sesi A mencoba **menulis** baris
yang sudah diubah dan di-commit sesi lain sesudah snapshot diambil, PostgreSQL tidak punya
cara menggabungkan keduanya dengan aman, sehingga transaksi A dibatalkan dengan SQLSTATE
`40001`. Aplikasi yang memakai `REPEATABLE READ` wajib siap mengulang transaksinya — inilah
alasan strategi retry pada Q29 ada.

---

## Q8 · Phantom read

Tabel eksperimen terpisah, `lab9.rekening_uji`, berisi empat baris awal: dua baris bersaldo
di atas 500.000 (Ani dan Budi) dan dua di bawahnya (Citra 400.000, Dedi 250.000).

### Bagian 1 — READ COMMITTED

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **2** |
| 3 | B | `INSERT INTO lab9.rekening_uji VALUES (5,'Eka',900000);` | `INSERT 0 1` |
| 4 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **3** |
| 5 | A | `COMMIT;` | `COMMIT` |

### Bagian 2 — REPEATABLE READ

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | `BEGIN` |
| 2 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **3** |
| 3 | B | `INSERT INTO lab9.rekening_uji VALUES (6,'Fajar',800000);` | `INSERT 0 1` |
| 4 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **3** (tidak berubah) |
| 5 | A | `COMMIT;` | `COMMIT` |
| 6 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **4** |

**Hasil.** Pada `READ COMMITTED` jumlah baris berubah 2 → 3 di tengah transaksi: baris yang
tadinya tidak ada tiba-tiba ikut terhitung. Pada `REPEATABLE READ` jumlahnya tetap 3 meski
Sesi B sudah menyisipkan baris keenam; baris itu baru terlihat **setelah** transaksi A selesai.

**Catatan penting.** Standar SQL hanya mewajibkan `SERIALIZABLE` untuk mencegah phantom read,
tetapi implementasi `REPEATABLE READ` PostgreSQL berbasis snapshot sehingga **sudah** menutup
phantom read pada pembacaan biasa. Yang masih lolos di level itu adalah *write skew*, yang
diuji pada Q26.

---

## Q9 · Dirty read dan perilaku READ UNCOMMITTED

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `UPDATE lab9.rekening SET saldo = 1 WHERE rekening_id = 1;` | `UPDATE 1` (belum di-commit) |
| 3 | A | `SELECT saldo ...;` | **1.00** |
| 4 | B | `BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` | `BEGIN` |
| 5 | B | `SHOW transaction_isolation;` | **`read uncommitted`** |
| 6 | B | `SELECT saldo ...;` | **1000000.00** |
| 7 | B | `COMMIT;` | `COMMIT` |
| 8 | A | `ROLLBACK;` | `ROLLBACK` |

**Hasil.** Tidak. PostgreSQL **tidak pernah** menampilkan perubahan yang belum di-commit.
Sesi B tetap membaca 1.000.000 padahal Sesi A sedang memegang nilai 1.

**Penjelasan.** PostgreSQL menerima sintaks `READ UNCOMMITTED` demi kompatibilitas standar SQL,
dan `SHOW transaction_isolation` memang melaporkan `read uncommitted`, tetapi secara internal
level itu **dijalankan sebagai `READ COMMITTED`**. Sebabnya ada pada arsitekturnya: visibilitas
baris ditentukan MVCC lewat `xmin`/`xmax` dan status transaksi di commit log, dan versi baris
yang dibuat transaksi yang belum selesai tidak pernah lolos uji visibilitas itu. Jadi dirty
read bukan sesuatu yang "dimatikan" oleh setelan — ia memang **tidak dapat terjadi** di
PostgreSQL. Langkah 8 membuktikan arahnya juga aman: setelah `ROLLBACK`, nilai 1 itu hilang
tanpa pernah dilihat siapa pun.

---

## Q10 · Lost update

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT saldo ... rekening_id = 1;` | **1000000.00** |
| 3 | B | `BEGIN;` | `BEGIN` |
| 4 | B | `SELECT saldo ... rekening_id = 1;` | **1000000.00** |
| 5 | A | `UPDATE ... SET saldo = 900000 ...;` | `UPDATE 1` (aplikasi A: 1.000.000 − 100.000) |
| 6 | A | `COMMIT;` | `COMMIT` |
| 7 | B | `UPDATE ... SET saldo = 950000 ...;` | `UPDATE 1` (aplikasi B: 1.000.000 − 50.000) |
| 8 | B | `COMMIT;` | `COMMIT` |
| 9 | A | `SELECT saldo ... rekening_id = 1;` | **950000.00** |

**Hasil.** Dua penarikan dijalankan — 100.000 oleh A dan 50.000 oleh B — tetapi saldo akhir
950.000, seolah hanya penarikan B yang pernah terjadi. Uang 100.000 milik A **hilang tanpa
pesan galat apa pun**.

**Sebab.** Keduanya membaca 1.000.000, lalu masing-masing menghitung hasilnya **di sisi
aplikasi** dan menulis **nilai tetap**. `UPDATE` milik B tidak tahu bahwa angka 1.000.000 yang
dipakainya sudah basi; bagi PostgreSQL itu penulisan yang sah. Perhatikan juga bahwa B tidak
sempat menunggu: `UPDATE` A sudah di-commit pada langkah 6, sehingga lock barisnya sudah
dilepas sebelum B menulis.

**Inilah anomali paling berbahaya di antara kelima percobaan**, karena tidak meninggalkan
jejak: tidak ada galat, tidak ada peringatan, hanya angka yang salah. Pencegahannya dibahas
pada Q12 (pembaruan atomik `saldo = saldo - 10000`), Q13 (`SELECT ... FOR UPDATE`), dan Q14
(kolom versi).

---

## Q11 · Ringkasan anomali

| Anomali | Urutan kejadian | Isolation level | Hasil yang diamati | Pencegahan |
|---|---|---|---|---|
| **Dirty read** | A ubah tanpa commit → B baca | `READ UNCOMMITTED` (dipetakan ke `READ COMMITTED`) | **Tidak terjadi**: B membaca 1000000, bukan 1 | Sudah dijamin arsitektur MVCC PostgreSQL |
| **Non-repeatable read** | A baca → B ubah dan commit → A baca lagi | `READ COMMITTED` | 1000000 lalu **700000** | Naikkan ke `REPEATABLE READ` (Q7) |
| **Phantom read** | A hitung → B sisip baris baru dan commit → A hitung lagi | `READ COMMITTED` | 2 lalu **3** | `REPEATABLE READ` sudah cukup di PostgreSQL (Q8) |
| **Non-repeatable read / phantom** | urutan sama | `REPEATABLE READ` | Tetap **1000000** dan tetap **3** | — (sudah tertutup) |
| **Serialization failure** | A baca pada snapshot → B ubah dan commit → A menulis baris itu | `REPEATABLE READ` | **ERROR 40001** | Retry seluruh transaksi (Q29) |
| **Lost update** | A dan B baca nilai sama → masing-masing menulis nilai tetap | `READ COMMITTED` | 950000, penarikan 100000 **hilang** | `saldo = saldo - x` (Q12), `FOR UPDATE` (Q13), kolom versi (Q14) |

Satu pola yang terlihat dari tabel ini: menaikkan isolation level menutup anomali **pembacaan**
(baris 2 dan 3), tetapi tidak satu pun level yang menutup *lost update* bila aplikasinya
menulis nilai tetap hasil hitungan sendiri. Yang berubah hanyalah cara kegagalannya muncul —
pada `READ COMMITTED` ia diam-diam menimpa, sedangkan pada `REPEATABLE READ` ia berubah menjadi
galat `40001` yang setidaknya **bisa dideteksi dan diulang**.
