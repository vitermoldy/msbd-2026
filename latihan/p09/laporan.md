# Laporan Latihan P09 — Menguji Transaksi dan Kendali Konkurensi

ACID · Isolation Level · MVCC · Row Lock · Deadlock · SERIALIZABLE · Retry

Seluruh percobaan dijalankan pada skema `lab9`. Tabel Pagila pada skema `public` dan skema
latihan pertemuan lain (`lab5`, `lab6`) tidak dibuat, diubah, maupun dihapus.

## Pembagian tugas

| Langkah | Soal | Anggota | Status |
|---|---|---|---|
| Langkah 1 | Q1–Q5 | Viter | selesai |
| Langkah 2 | Q6–Q11 | Viter | selesai |
| Langkah 3 | Q12–Q17 | Finsus | selesai |
| Langkah 4 | Q18–Q23 | Naifah | selesai |
| Langkah 5 | Q24–Q29 | Nadine | selesai |
| Langkah 6 | Q30–Q32 | «isi nama» | belum |
| `README.md`, `q00_setup.sql`, kerangka `laporan.md` | — | Viter | selesai |

## Kondisi uji

| Hal | Nilai |
|---|---|
| Versi PostgreSQL | PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, 64-bit |
| Basis data | `pagila`, skema kerja `lab9`, pada kontainer Docker `msbd-pg` |
| Alat | Dua jendela Command Prompt, masing-masing satu sesi `psql` lewat `docker compose exec -it postgres psql -U msbd -d pagila` |
| `transaction_isolation` (bawaan) | `read committed` |
| `deadlock_timeout` | 1s |
| `lock_timeout` | 0 (tanpa batas) |
| `statement_timeout` | 0 (tanpa batas) |
| `idle_in_transaction_session_timeout` | 0 (tanpa batas) |
| Data awal | `lab9.rekening`: `(1,'Ani',1000000.00)`, `(2,'Budi',1000000.00)`; total 2.000.000,00 |

Keempat nilai timeout di atas adalah **bawaan server** dan tidak diubah secara global, sesuai
catatan soal. Nilai-nilai ini dikonfirmasi dari keluaran `q00_setup.sql`; bila berbeda di mesin
anggota lain, nilai yang tercetak di keluaran itulah yang dipakai.

Dua sesi dibedakan sebagai **Sesi A** dan **Sesi B**. Pada setiap tabel urutan di bawah, kolom
*Urutan* adalah urutan waktu yang sebenarnya, jadi baris 4 dijalankan setelah baris 3 selesai
dan sebelum baris 5 dimulai. Agar SQLSTATE ikut tercetak, kedua sesi dijalankan dengan
`\set VERBOSITY verbose`.

---

# Langkah 1 · Q1–Q5: Setup dan Batas Transaksi

## Q1. Kondisi awal dan jumlah saldo keseluruhan

```text
 rekening_id | pemilik |    saldo
-------------+---------+------------
           1 | Ani     | 1000000.00
           2 | Budi    | 1000000.00

 jumlah_rekening | total_saldo
-----------------+-------------
               2 | 2000000.00
```

Dua rekening, masing-masing 1.000.000,00, dengan total 2.000.000,00. Angka total inilah yang
dipakai sebagai **invarian** pada Q3 dan Q5: setiap transfer hanya memindahkan uang antar
rekening, jadi berapa pun hasil akhir masing-masing saldo, jumlahnya harus tetap 2.000.000,00.
Kolom `saldo` bertipe `NUMERIC(12,2)` dengan `CHECK (saldo >= 0)`, dan pemilihan `NUMERIC`
bukan `FLOAT` memang disengaja: nilai uang harus eksak, sedangkan bilangan pecahan biner akan
membawa galat pembulatan.

## Q2. Perubahan sebelum COMMIT, dilihat dari sesi lain

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `UPDATE lab9.rekening SET saldo = saldo - 250000 WHERE rekening_id = 1;` | `UPDATE 1` |
| 3 | A | `SELECT ... ORDER BY rekening_id;` | **750000.00** dan 1000000.00 |
| 4 | B | `SELECT ... ORDER BY rekening_id;` | **1000000.00** dan 1000000.00 |
| 5 | B | `SELECT pg_blocking_pids(pg_backend_pid());` | `{}` (kosong) |
| 6 | A | `ROLLBACK;` | `ROLLBACK` |
| 7 | B | `SELECT ... ORDER BY rekening_id;` | 1000000.00 dan 1000000.00 |

**Yang terlihat di sesi lain: tidak ada.** Sesi A melihat 750.000 — perubahannya sendiri, di
dalam transaksinya sendiri — sementara Sesi B pada saat yang sama tetap membaca 1.000.000.

Dua hal penting pada langkah 5. Pertama, `pg_blocking_pids` mengembalikan himpunan kosong,
artinya Sesi B **tidak menunggu**: ia tidak diblokir lalu diberi nilai lama, melainkan langsung
dilayani. Pembaca tidak pernah diblokir penulis — inilah inti MVCC, yang dibahas lagi pada Q15.
Kedua, karena yang dilihat Sesi B adalah versi baris yang lama, `ROLLBACK` di langkah 6 tidak
mengubah apa pun dari sudut pandang Sesi B: nilai pada langkah 7 sama dengan langkah 4. Dengan
kata lain, isolation membuat seluruh pekerjaan Sesi A yang batal itu **tidak pernah ada** bagi
sesi lain.

## Q3. COMMIT lawan ROLLBACK

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `UPDATE ... saldo = saldo - 100000 ... rekening_id = 1;` | `UPDATE 1` |
| 3 | A | `UPDATE ... saldo = saldo + 100000 ... rekening_id = 2;` | `UPDATE 1` |
| 4 | A | `COMMIT;` | `COMMIT` |
| 5 | A | `SELECT rekening_id, saldo ...;` | **900000.00** dan **1100000.00** |
| 6 | A | `BEGIN;` | `BEGIN` |
| 7 | A | `UPDATE ... saldo = saldo - 400000 ... rekening_id = 1;` | `UPDATE 1` |
| 8 | A | `SELECT rekening_id, saldo ...;` | **500000.00** dan 1100000.00 |
| 9 | A | `ROLLBACK;` | `ROLLBACK` |
| 10 | A | `SELECT rekening_id, saldo ...;` | **900000.00** dan 1100000.00 |

**Yang bertahan hanya perubahan yang di-COMMIT.** Transfer 100.000 pada langkah 2–4 bertahan;
pengurangan 400.000 pada langkah 7 hilang seluruhnya setelah `ROLLBACK`.

Yang perlu dicatat adalah langkah 8: di dalam transaksi, nilai 500.000 itu **nyata** bagi Sesi
A — ia bisa dibaca, dihitung, dan dipakai sebagai dasar perintah berikutnya. Jadi `ROLLBACK`
bukan "membatalkan sesuatu yang belum terjadi", melainkan membuang kerja yang sudah berjalan
penuh di dalam transaksi. Perhatikan juga bahwa transfer pada langkah 2–3 terdiri atas **dua**
`UPDATE` dalam satu transaksi; inilah bentuk yang benar untuk transfer, karena jika hanya satu
yang berhasil, uang akan tercipta atau hilang.

## Q4. SAVEPOINT dan ROLLBACK TO SAVEPOINT

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `UPDATE ... saldo = saldo - 50000 ... rekening_id = 1;` *(tahap 1)* | `UPDATE 1` → 850000.00 |
| 3 | A | `SAVEPOINT sebelum_transfer_kedua;` | `SAVEPOINT` |
| 4 | A | `UPDATE ... saldo = saldo - 70000 ... rekening_id = 1;` *(tahap 2)* | `UPDATE 1` |
| 5 | A | `SELECT saldo ... rekening_id = 1;` | **780000.00** |
| 6 | A | `ROLLBACK TO SAVEPOINT sebelum_transfer_kedua;` | `ROLLBACK` |
| 7 | A | `SELECT saldo ... rekening_id = 1;` | **850000.00** |
| 8 | A | `COMMIT;` | `COMMIT` |
| 9 | A | `SELECT rekening_id, saldo ...;` | **850000.00** dan 1100000.00 |

**Yang dibatalkan hanya pekerjaan setelah `SAVEPOINT`,** yaitu pengurangan 70.000 pada tahap 2.
Rangkaian nilainya jelas: 900.000 → 850.000 (tahap 1) → 780.000 (tahap 2) → kembali ke 850.000
setelah `ROLLBACK TO SAVEPOINT` → dan 850.000 itulah yang bertahan setelah `COMMIT`.

Perbedaannya dengan Q3 terletak pada langkah 6 dan 8: `ROLLBACK TO SAVEPOINT` **tidak
mengakhiri transaksi**. Setelah langkah 6, Sesi A masih berada di dalam transaksi yang sama dan
masih bisa melanjutkan pekerjaan, lalu `COMMIT` pada langkah 8 tetap menyimpan tahap 1. Itulah
gunanya savepoint: ia memberi titik mundur **sebagian** di dalam satu transaksi, sehingga satu
langkah yang gagal tidak memaksa seluruh transaksi dibuang dan diulang dari awal. Kegunaan
praktisnya terlihat di Q5 — setelah sebuah perintah gagal, savepoint adalah satu-satunya cara
menyelamatkan transaksi yang sudah masuk kondisi *aborted*.

## Q5. Atomicity dan consistency lewat transaksi dan CHECK

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `UPDATE ... saldo = saldo + 1 ... rekening_id = 2;` | `UPDATE 1` (berhasil) |
| 3 | A | `UPDATE ... saldo = saldo - 99999999 ... rekening_id = 1;` | **ERROR `23514`** |
| 4 | A | `SELECT rekening_id, saldo ...;` | **ERROR `25P02`** |
| 5 | A | `ROLLBACK;` | `ROLLBACK` |
| 6 | A | `SELECT rekening_id, saldo ...;` | 850000.00 dan 1100000.00 |
| 7 | A | `SELECT sum(saldo);` | **1950000.00** |

Pesan galat pada langkah 3 dan 4:

```text
ERROR:  23514: new row for relation "rekening" violates check constraint "rekening_saldo_check"
DETAIL:  Failing row contains (1, Ani, -99149999.00).

ERROR:  25P02: current transaction is aborted, commands ignored until end of transaction block
```

**Atomicity** terlihat pada langkah 2 lawan langkah 6. `UPDATE` penambahan 1 rupiah pada
langkah 2 sudah **berhasil**, tetapi setelah `ROLLBACK` nilainya tetap 1.100.000,00 — bukan
1.100.000,01. Jadi transaksi bukan kumpulan perintah yang masing-masing berdiri sendiri: ia
satu kesatuan yang berhasil seluruhnya atau gagal seluruhnya. Satu perintah gagal menarik
semua perintah sebelumnya ikut dibatalkan.

**Consistency** dijaga `CHECK (saldo >= 0)`. Aturan "saldo tidak boleh negatif" ditulis sekali
di definisi tabel, lalu berlaku untuk **setiap** jalur penulisan — psql, aplikasi FastAPI,
maupun skrip apa pun — tanpa perlu diulang di tiap tempat. Karena itu basis data tidak pernah
sempat berada dalam keadaan tidak sah: pada langkah 3 baris bersaldo −99.149.999,00 ditolak
sebelum tersimpan, dan `DETAIL` menunjukkan baris yang ditolak itu.

Langkah 4 memperlihatkan satu hal yang mudah membingungkan: setelah sebuah galat, transaksi
masuk kondisi **aborted**, dan setiap perintah berikutnya ditolak dengan `25P02` — bahkan
`SELECT` yang tidak berbahaya. Satu-satunya jalan keluar adalah `ROLLBACK` (atau
`ROLLBACK TO SAVEPOINT` bila savepoint sudah dipasang sebelum perintah yang gagal, seperti pada
Q4). Ini penting untuk Q29: kode retry tidak boleh mencoba menjalankan ulang satu perintah di
dalam transaksi yang sama; ia harus mengakhiri transaksi itu lalu mengulang **seluruh**
transaksi dari `BEGIN`.

Langkah 7 menutup Langkah 1: total 1.950.000,00, yaitu 2.000.000 − 50.000 dari tahap 1 Q4 yang
di-`COMMIT`. Selisihnya bukan kebocoran, melainkan satu-satunya perubahan yang memang sengaja
dipertahankan; semua pengurangan lain di Q3–Q5 tidak menyisakan jejak. Sebelum Langkah 2
dimulai, data dikembalikan ke 1.000.000 per rekening.

---

# Langkah 2 · Q6–Q11: Isolation Level dan Anomali

Bukti urutan lengkap kedua sesi untuk Langkah 2 ada di
[`bukti/isolation-level.md`](bukti/isolation-level.md), dan keluaran psql mentahnya di
[`bukti/hasil-sesi.txt`](bukti/hasil-sesi.txt). Bagian ini memuat hasil dan analisisnya.

## Q6. Non-repeatable read pada READ COMMITTED

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SHOW transaction_isolation;` | `read committed` |
| 3 | A | `SELECT saldo ... rekening_id = 1;` | **1000000.00** |
| 4 | B | `UPDATE ... saldo = saldo - 300000 ... rekening_id = 1;` | `UPDATE 1`, ter-commit |
| 5 | A | `SELECT saldo ... rekening_id = 1;` | **700000.00** |
| 6 | A | `COMMIT;` | `COMMIT` |

**Kedua pembacaan berubah: 1.000.000 lalu 700.000**, padahal query-nya sama persis dan keduanya
berada di dalam **satu transaksi** yang sama. Inilah *non-repeatable read*.

Sebabnya ada pada cara `READ COMMITTED` mengambil snapshot: snapshot baru diambil **pada setiap
pernyataan**, bukan sekali di awal transaksi. Begitu Sesi B commit di antara dua `SELECT` milik
Sesi A, pernyataan kedua memakai snapshot yang sudah memuat perubahan itu.

Dampak praktisnya terasa pada pekerjaan yang membaca satu nilai beberapa kali dalam satu
transaksi — misalnya laporan yang menghitung total lalu menghitung rata-rata dari tabel yang
sama. Pada `READ COMMITTED`, kedua angka itu bisa berasal dari dua keadaan basis data yang
berbeda, sehingga laporannya tidak konsisten secara internal meski tiap angkanya "benar" saat
dibaca.

## Q7. Perbandingan isolation: REPEATABLE READ

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | `BEGIN` |
| 2 | A | `SHOW transaction_isolation;` | `repeatable read` |
| 3 | A | `SELECT saldo ... rekening_id = 1;` | **1000000.00** |
| 4 | B | `UPDATE ... saldo = saldo - 300000 ... rekening_id = 1;` | `UPDATE 1`, ter-commit |
| 5 | A | `SELECT saldo ... rekening_id = 1;` | **1000000.00** (tidak berubah) |
| 6 | A | `UPDATE ... saldo = saldo - 1 ... rekening_id = 1;` | **ERROR `40001`** |
| 7 | A | `ROLLBACK;` | `ROLLBACK` |
| 8 | A | `SELECT saldo ... rekening_id = 1;` | **700000.00** |

```text
ERROR:  40001: could not serialize access due to concurrent update
```

**Perbedaannya dengan Q6 ada di langkah 5:** urutan perintahnya identik, tetapi pembacaan kedua
tetap 1.000.000. Pada `REPEATABLE READ`, snapshot diambil **sekali saja** pada pernyataan
pertama transaksi, lalu dipertahankan sampai transaksi berakhir, sehingga pembacaan berulang
selalu konsisten. Sesi A bekerja di atas potret basis data pada satu titik waktu.

Konsistensi itu tidak gratis, dan langkah 6 menunjukkan harganya. Begitu Sesi A mencoba
**menulis** baris yang sudah diubah dan di-commit sesi lain sesudah snapshot diambil,
PostgreSQL menolak dengan SQLSTATE `40001`. Alasannya masuk akal: `UPDATE ... saldo = saldo - 1`
harus memakai nilai `saldo` yang mana — 1.000.000 yang dilihat Sesi A, atau 700.000 yang nyata
di basis data? Memakai yang pertama berarti menimpa pekerjaan Sesi B (persis lost update di
Q10), memakai yang kedua berarti melanggar janji snapshot. Karena tidak ada pilihan yang aman,
seluruh transaksi dibatalkan.

Konsekuensinya untuk aplikasi: **`REPEATABLE READ` memindahkan masalah, bukan menghapusnya.**
Anomali pembacaan hilang, tetapi muncul kelas kegagalan baru yang wajib ditangani dengan retry
(Q29). Bedanya, kegagalan ini **terlihat** sebagai galat — jauh lebih baik daripada lost update
yang diam-diam. Langkah 8 menegaskan bahwa yang bertahan adalah hasil Sesi B: `ROLLBACK` Sesi A
tidak menyentuh pekerjaan sesi lain.

## Q8. Phantom read

Tabel `lab9.rekening_uji` dipakai agar `lab9.rekening` tetap bersih. Isi awalnya empat baris:
Ani 1.000.000 dan Budi 1.000.000 (keduanya di atas 500.000), Citra 400.000, dan Dedi 250.000.

**READ COMMITTED**

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **2** |
| 3 | B | `INSERT ... (5,'Eka',900000);` | `INSERT 0 1` |
| 4 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **3** |
| 5 | A | `COMMIT;` | `COMMIT` |

**REPEATABLE READ**

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | `BEGIN` |
| 2 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **3** |
| 3 | B | `INSERT ... (6,'Fajar',800000);` | `INSERT 0 1` |
| 4 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **3** (tidak berubah) |
| 5 | A | `COMMIT;` | `COMMIT` |
| 6 | A | `SELECT count(*) ... WHERE saldo > 500000;` | **4** |

Pada `READ COMMITTED` jumlahnya berubah **2 → 3**: baris yang tadinya tidak ada tiba-tiba ikut
terhitung. Pada `REPEATABLE READ` jumlahnya tetap **3 → 3** meski Sesi B sudah menyisipkan
baris keenam, dan baris itu baru terlihat **setelah** transaksi A selesai, yaitu 4 pada langkah 6.

Bedanya dengan Q6 terletak pada apa yang berubah. Di Q6 yang berubah adalah **nilai sebuah
baris** yang sudah ada; di sini yang berubah adalah **himpunan baris** yang memenuhi syarat
`saldo > 500000`. Karena itu *phantom read* tidak bisa dicegah dengan mengunci baris-baris yang
sudah terbaca — baris penyebabnya belum ada ketika penguncian dilakukan. Yang menyelamatkan
adalah snapshot: Sesi A membaca potret lama, dan baris yang dibuat sesudah potret itu diambil
tidak termasuk di dalamnya.

Satu catatan agar tidak salah paham: standar SQL hanya mewajibkan `SERIALIZABLE` untuk mencegah
phantom read, dan menurut standar itu `REPEATABLE READ` masih boleh membiarkannya terjadi.
Implementasi PostgreSQL berbasis snapshot, jadi levelnya lebih ketat dari yang diwajibkan dan
phantom read pada pembacaan biasa **sudah** tertutup. Yang masih lolos di level itu adalah
*write skew*, yang diuji pada Q26–Q27.

## Q9. Dirty read dan perilaku READ UNCOMMITTED

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

**Tidak. PostgreSQL tidak menampilkan perubahan yang belum di-commit.** Sesi A memegang nilai 1
di dalam transaksinya, tetapi Sesi B tetap membaca 1.000.000.

Yang menarik adalah langkah 5: `SHOW transaction_isolation` benar-benar melaporkan
`read uncommitted`. Jadi permintaan Sesi B **diterima**, bukan ditolak sebagai sintaks tak
dikenal. PostgreSQL menerima keempat level standar SQL demi kompatibilitas, tetapi
`READ UNCOMMITTED` **dijalankan sebagai `READ COMMITTED`**; dari keempat level, hanya tiga yang
benar-benar berbeda perilakunya.

Sebabnya arsitektural, bukan sekadar setelan yang dimatikan. Visibilitas baris di PostgreSQL
ditentukan MVCC lewat metadata `xmin`/`xmax` pada setiap versi baris ditambah status transaksi
di commit log (Q16 membahas kedua kolom itu). Versi baris yang dibuat transaksi yang belum
selesai tidak pernah lolos uji visibilitas tersebut, karena transaksi pembuatnya belum
tercatat commit. Dengan kata lain, PostgreSQL tidak punya mekanisme untuk menunjukkan data
yang belum di-commit, bahkan bila diminta. **Dirty read bukan sesuatu yang dicegah, melainkan
sesuatu yang tidak dapat terjadi.**

Langkah 8 menunjukkan arah yang tak kalah penting: setelah `ROLLBACK`, nilai 1 itu hilang tanpa
pernah dilihat siapa pun. Kalau Sesi B sempat membaca 1 lalu memakainya untuk perhitungan,
hasil perhitungan itu akan didasarkan pada keadaan yang akhirnya **tidak pernah ada** — dan
itulah bahaya dirty read yang arsitektur ini tutup sepenuhnya.

## Q10. Lost update

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT saldo ... rekening_id = 1;` | **1000000.00** |
| 3 | B | `BEGIN;` | `BEGIN` |
| 4 | B | `SELECT saldo ... rekening_id = 1;` | **1000000.00** |
| 5 | A | `UPDATE ... SET saldo = 900000 ...;` | `UPDATE 1` *(aplikasi A: 1.000.000 − 100.000)* |
| 6 | A | `COMMIT;` | `COMMIT` |
| 7 | B | `UPDATE ... SET saldo = 950000 ...;` | `UPDATE 1` *(aplikasi B: 1.000.000 − 50.000)* |
| 8 | B | `COMMIT;` | `COMMIT` |
| 9 | A | `SELECT saldo ... rekening_id = 1;` | **950000.00** |

Dua penarikan dijalankan — 100.000 oleh A dan 50.000 oleh B — sehingga saldo akhir seharusnya
850.000. Yang tercatat **950.000**, seolah hanya penarikan B yang pernah terjadi. Uang 100.000
milik A hilang, dan **tidak ada satu pun galat atau peringatan** di sepanjang sembilan langkah
itu: semua perintah melaporkan sukses.

Penyebabnya bukan basis datanya, melainkan pola `baca → hitung di aplikasi → tulis nilai
tetap`. Keduanya membaca 1.000.000 pada langkah 2 dan 4, lalu masing-masing menghitung hasilnya
**di luar** basis data dan menulis angka jadi. `UPDATE` milik B pada langkah 7 tidak membawa
informasi apa pun tentang nilai 1.000.000 yang menjadi dasarnya, jadi PostgreSQL tidak punya
cara mengetahui bahwa angka itu sudah basi; bagi basis data itu penulisan yang sepenuhnya sah.

Perhatikan juga bahwa B **tidak sempat menunggu**. `UPDATE` Sesi A sudah di-commit pada langkah
6, sehingga lock barisnya sudah dilepas sebelum B menulis pada langkah 7. Row lock memang ada
dan bekerja, tetapi ia hanya menyerialkan dua penulisan yang **bersamaan**; ia tidak bisa
menolak penulisan yang datang setelah lock dilepas, sekalipun penulisan itu dihitung dari nilai
yang sudah kedaluwarsa.

Inilah anomali paling berbahaya dari kelima percobaan Langkah 2, justru karena tidak
meninggalkan jejak apa pun: tidak ada galat, tidak ada peringatan, hanya angka yang salah.
Bandingkan dengan `40001` pada Q7 — di sana kegagalannya setidaknya terlihat dan bisa diulang.
Pencegahannya ada di Langkah 3: pembaruan atomik `saldo = saldo - 10000` (Q12),
`SELECT ... FOR UPDATE` (Q13), dan kolom versi (Q14).

## Q11. Tabel ringkasan anomali

| Anomali | Urutan kejadian | Isolation level | Hasil yang diamati | Pencegahan / penanganan |
|---|---|---|---|---|
| **Dirty read** | A ubah tanpa commit → B baca | `READ UNCOMMITTED` (dipetakan ke `READ COMMITTED`) | **Tidak terjadi**: B membaca 1000000, bukan 1 | Sudah dijamin arsitektur MVCC; tidak perlu tindakan |
| **Non-repeatable read** | A baca → B ubah + commit → A baca lagi | `READ COMMITTED` | 1000000 lalu **700000** | Naikkan ke `REPEATABLE READ` (Q7) |
| **Phantom read** | A `count(*)` → B `INSERT` + commit → A `count(*)` lagi | `READ COMMITTED` | 2 lalu **3** | `REPEATABLE READ` sudah cukup di PostgreSQL (Q8) |
| **Pembacaan konsisten** | urutan sama dengan dua baris di atas | `REPEATABLE READ` | Tetap **1000000**, tetap **3** | — (sudah tertutup oleh snapshot) |
| **Serialization failure** | A baca pada snapshot → B ubah + commit → A menulis baris itu | `REPEATABLE READ` | **ERROR 40001** | Ulangi seluruh transaksi dari `BEGIN` (Q29) |
| **Lost update** | A dan B baca nilai sama → masing-masing menulis nilai tetap | `READ COMMITTED` | **950000**, penarikan 100000 hilang tanpa galat | `saldo = saldo - x` (Q12), `FOR UPDATE` (Q13), kolom versi (Q14) |

Satu pola terlihat dari tabel ini. Menaikkan isolation level menutup anomali **pembacaan**
(baris 2 dan 3), tetapi **tidak satu pun level menutup lost update** bila aplikasinya menulis
nilai tetap hasil hitungannya sendiri. Yang berubah hanyalah bentuk kegagalannya: pada
`READ COMMITTED` ia menimpa diam-diam, sedangkan pada `REPEATABLE READ` ia menjelma menjadi
galat `40001` yang setidaknya bisa dideteksi dan diulang. Artinya isolation level dan disiplin
penulisan adalah dua pengaman yang berbeda, dan yang kedua tidak bisa digantikan yang pertama —
inilah yang dibuktikan Langkah 3.

---

# Langkah 3 · Q12–Q17: Mencegah Lost Update dan Memahami MVCC

«Diisi anggota pemegang Langkah 3. Pola penulisan: tabel urutan Sesi A/Sesi B, pesan galat apa
adanya dengan SQLSTATE, lalu penjelasan sebab.»

## Q12. Pembaruan atomik
## Q13. SELECT ... FOR UPDATE
## Q14. Kolom versi
## Q15. MVCC dan snapshot tanpa menunggu penulis
## Q16. xmin dan xmax
## Q17. Manfaat MVCC dan perlunya vacuum

---

# Langkah 4 · Q18–Q23: Row Lock, Deadlock, dan Antrean Lock

Bagian ini membahas penguncian baris (*row-level locks*), bagaimana dua sesi bisa mengalami *deadlock*, dan fungsi parameter *timeout* di PostgreSQL. Seluruh pengujian dilakukan pada tabel `lab9.rekening`.

---

## Q18. Perbandingan Mode Lock Baris (FOR UPDATE, FOR NO KEY UPDATE, FOR SHARE, FOR KEY SHARE)

PostgreSQL menyediakan beberapa mode penguncian baris untuk mengatur akses transaksi yang berjalan bersamaan. Setiap mode memiliki tingkat penguncian dan batasan yang berbeda, seperti berikut.

### FOR UPDATE (Eksklusif Penuh)

**Tujuan Umum:** Mengunci baris secara ketat ketika transaksi akan mengubah atau menghapus data. Lock ini mencegah transaksi lain mengubah baris yang sama selama penguncian masih berlangsung.

**Kondisi Terhalang:** Transaksi lain harus menunggu jika ingin melakukan `UPDATE`, `DELETE`, atau meminta mode lock yang tidak kompatibel pada baris yang sama.

### FOR NO KEY UPDATE (Eksklusif Ringan)

**Tujuan Umum:** Mirip dengan `FOR UPDATE`, tetapi lebih longgar. Lock ini biasanya digunakan oleh operasi `UPDATE` yang tidak mengubah kolom kunci utama (*key columns*).

**Kondisi Terhalang:** Transaksi lain yang meminta `FOR UPDATE` harus menunggu. Namun, transaksi yang meminta `FOR NO KEY UPDATE` atau mode lock berbagi yang kompatibel masih bisa berjalan.

### FOR SHARE (Berbagi / Shared Lock)

**Tujuan Umum:** Menjaga agar baris tidak diubah selama transaksi berlangsung, tetapi tetap memungkinkan transaksi lain membaca data tersebut.

**Kondisi Terhalang:** Transaksi lain tidak bisa melakukan `UPDATE`, `DELETE`, atau meminta lock yang tidak kompatibel, seperti `FOR UPDATE` dan `FOR NO KEY UPDATE`. Transaksi lain masih bisa membaca baris atau meminta `FOR SHARE`.

### FOR KEY SHARE (Berbagi Kunci Asing)

**Tujuan Umum:** Merupakan mode lock berbagi yang paling longgar. Lock ini umumnya berkaitan dengan penjagaan integritas referensial antartabel (*foreign key*).

**Kondisi Terhalang:** Lock ini mencegah baris dihapus atau kolom kunci yang direferensikan diubah. Namun, transaksi lain masih bisa memperbarui kolom biasa yang bukan bagian dari kunci tersebut.

---

## Q19. Antrean Lock pada Baris yang Sama (FOR UPDATE)

Percobaan ini melihat apa yang terjadi ketika dua sesi meminta lock pada baris yang sama. Jika Sesi A sudah mengunci baris tersebut, Sesi B harus menunggu sampai lock dilepaskan.

| Urutan | Sesi | Perintah | Hasil |
|---:|:---:|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | Baris ID 1 berhasil dikunci |
| 3 | B | `BEGIN;` | `BEGIN` |
| 4 | B | `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | Menunggu karena lock masih dipegang Sesi A |
| 5 | A | `COMMIT;` | `COMMIT`, lock dilepaskan |
| 6 | B | Melanjutkan eksekusi | Baris ID 1 berhasil diperoleh |
| 7 | B | `COMMIT;` | `COMMIT` |

Pada langkah 4, Sesi B harus menunggu karena baris dengan `rekening_id = 1` masih dikunci oleh Sesi A. Setelah Sesi A melakukan `COMMIT` pada langkah 5, lock dilepaskan sehingga Sesi B bisa melanjutkan perintahnya.

Dari percobaan ini, terlihat bahwa Sesi B baru bisa mendapatkan lock setelah Sesi A selesai. Dengan cara ini, PostgreSQL mengatur akses beberapa transaksi terhadap baris yang sama agar perubahan data tidak saling bertabrakan.

---

## Q20. Terjadinya Deadlock dan SQLSTATE 40P01

*Deadlock* terjadi ketika dua transaksi saling menunggu lock yang sedang dipegang oleh transaksi lainnya. Akibatnya, kedua transaksi tidak bisa melanjutkan proses karena masing-masing membutuhkan lock yang masih dipegang oleh transaksi lain.

| Urutan | Sesi | Perintah | Hasil |
|---:|:---:|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | Lock ID 1 dipegang Sesi A |
| 3 | B | `BEGIN;` | `BEGIN` |
| 4 | B | `SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;` | Lock ID 2 dipegang Sesi B |
| 5 | A | `SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;` | Sesi A menunggu lock ID 2 yang dipegang Sesi B |
| 6 | B | `SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;` | `ERROR 40P01` karena deadlock terdeteksi |

Pesan galat yang tercetak pada Sesi B di langkah 6:

```text
ERROR:  40P01: deadlock detected
DETAIL:  Process 1234 waits for ShareLock on transaction 5678; blocked by process 9012.
         Process 9012 waits for ShareLock on transaction 3456; blocked by process 1234.
HINT:    See server log for details.
```

Pada percobaan ini, Sesi A sudah mengunci ID 1, sedangkan Sesi B memegang lock ID 2. Ketika Sesi A meminta ID 2, prosesnya tertahan karena lock masih dipegang Sesi B. Sebaliknya, Sesi B juga tidak bisa mendapatkan ID 1 karena masih dikunci oleh Sesi A. Kondisi inilah yang menyebabkan deadlock.

PostgreSQL mendeteksi kondisi tersebut berdasarkan parameter `deadlock_timeout`. Setelah deadlock terdeteksi, PostgreSQL membatalkan salah satu transaksi dan menampilkan SQLSTATE `40P01`. Transaksi yang dibatalkan perlu diakhiri sebelum dicoba kembali, sedangkan transaksi lainnya bisa melanjutkan proses setelah lock yang dibutuhkan tersedia.

---

## Q21. Pencegahan Deadlock dengan Urutan Penguncian Konsisten

Deadlock dapat dihindari jika semua sesi mengunci `rekening_id` dari nilai terkecil ke terbesar.

Pada Q20, Sesi A meminta ID 1 lalu ID 2, sedangkan Sesi B meminta ID 2 lalu ID 1. Karena urutannya berbeda, kedua sesi akhirnya saling menunggu.

Jika semua transaksi mengikuti urutan penguncian yang sama, misalnya selalu mengunci ID terkecil terlebih dahulu, kondisi saling menunggu seperti pada Q20 dapat dicegah. Salah satu sesi mungkin tetap harus menunggu sampai transaksi lain selesai, tetapi kedua sesi tidak akan membentuk siklus tunggu karena urutan pengunciannya konsisten.

---

## Q22. Perbedaan Deadlock dan Antrean Lock Panjang (Long Lock Wait)

Deadlock dan antrean lock panjang sama-sama membuat transaksi menunggu, tetapi penyebabnya berbeda.

### Deadlock (Kebuntuan)

**Karakteristik:** Terjadi ketika dua transaksi saling menunggu lock yang dipegang oleh transaksi lainnya. Kedua transaksi tidak bisa melanjutkan proses karena masing-masing menunggu sumber daya yang masih dikunci pihak lain.

**Penanganan:** PostgreSQL mendeteksi deadlock dan membatalkan salah satu transaksi agar transaksi lainnya bisa melanjutkan proses.

### Antrean Lock Panjang (Long Lock Wait)

**Karakteristik:** Terjadi ketika sebuah transaksi harus menunggu karena lock masih dipegang transaksi lain. Namun, transaksi yang memegang lock tersebut tidak sedang menunggu sumber daya dari transaksi yang mengantre. Hal ini bisa terjadi ketika transaksi terlalu lama berjalan atau belum melakukan `COMMIT` maupun `ROLLBACK`.

**Penanganan:** PostgreSQL tidak otomatis membatalkan transaksi hanya karena waktu tunggunya lama selama tidak terjadi deadlock. Batas waktu tunggu bisa diatur menggunakan parameter seperti `lock_timeout`.

---

## Q23. Fungsi Parameter Waktu (Timeouts) di PostgreSQL

PostgreSQL memiliki beberapa parameter *timeout* untuk membatasi waktu tunggu dan eksekusi perintah. Parameter ini membantu mencegah transaksi atau perintah SQL berjalan terlalu lama.

### `lock_timeout`

**Fungsi:** Membatasi waktu sebuah perintah SQL menunggu untuk mendapatkan lock. Jika batas waktu terlampaui, perintah tersebut dibatalkan.

### `statement_timeout`

**Fungsi:** Membatasi waktu eksekusi satu perintah SQL. Jika perintah belum selesai sampai batas waktu tercapai, PostgreSQL membatalkannya.

### `idle_in_transaction_session_timeout`

**Fungsi:** Membatasi waktu sebuah sesi boleh tidak aktif ketika transaksi masih terbuka. Parameter ini membantu mencegah transaksi yang ditinggalkan tetap menahan lock dan menghambat sesi lain.

### `deadlock_timeout`

**Fungsi:** Menentukan berapa lama PostgreSQL menunggu sebelum memeriksa apakah terjadi deadlock. Nilai bawaannya adalah `1s`.


# Langkah 5 · Q24–Q29: SKIP LOCKED, NOWAIT, dan SERIALIZABLE

> Bukti pengujian lengkap dan tabel urutan sesi dicatat pada `bukti/serializable.md`.

Bagian ini membahas penguncian baris menggunakan `SKIP LOCKED` dan `NOWAIT`, anomali *write skew* pada `REPEATABLE READ`, serta pencegahan konflik transaksi menggunakan `SERIALIZABLE`. Pengujian dilakukan menggunakan dua sesi PostgreSQL pada tabel `lab9.antrean_pekerjaan` dan `lab9.dokter_jaga`.

---

## Q24. SKIP LOCKED pada Antrean Pekerjaan

`SKIP LOCKED` merupakan opsi penguncian baris yang memungkinkan sebuah transaksi melewati baris yang sedang dikunci oleh transaksi lain tanpa harus menunggu.

### Hasil Pengujian

| Urutan | Sesi | Perintah | Hasil |
|---:|:---:|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT * FROM lab9.antrean_pekerjaan WHERE job_id = 1 FOR UPDATE;` | Baris `(1, PENDING)` berhasil diperoleh dan dikunci. |
| 3 | B | `BEGIN;` | `BEGIN` |
| 4 | B | `SELECT * FROM lab9.antrean_pekerjaan WHERE status = 'PENDING' FOR UPDATE SKIP LOCKED;` | Mengembalikan baris `(2, PENDING)` dan `(3, PENDING)`. Baris pertama dilewati. |
| 5 | A | `ROLLBACK;` | Transaksi dibatalkan dan lock dilepaskan. |
| 6 | B | `ROLLBACK;` | Transaksi dibatalkan dan lock dilepaskan. |

Pada pengujian ini, Sesi A mengunci pekerjaan dengan `job_id = 1`. Ketika Sesi B menjalankan `SELECT ... FOR UPDATE SKIP LOCKED`, PostgreSQL melewati baris yang sedang dikunci dan mengembalikan dua baris lainnya, yaitu `job_id = 2` dan `job_id = 3`.

Dari percobaan ini, terlihat bahwa `SKIP LOCKED` memungkinkan beberapa transaksi mengambil pekerjaan yang berbeda tanpa harus menunggu lock pada baris yang sedang digunakan transaksi lain. Fitur ini berguna untuk sistem antrean pekerjaan yang diproses oleh beberapa pekerja secara bersamaan.

---

## Q25. NOWAIT dan SQLSTATE 55P03

`NOWAIT` digunakan ketika transaksi tidak ingin menunggu lock yang sedang dipegang transaksi lain. Jika baris tidak dapat dikunci, PostgreSQL langsung menghasilkan galat.

### Hasil Pengujian

| Urutan | Sesi | Perintah | Hasil |
|---:|:---:|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT * FROM lab9.antrean_pekerjaan WHERE job_id = 2 FOR UPDATE;` | Baris `(2, PENDING)` berhasil dikunci. |
| 3 | B | `BEGIN;` | `BEGIN` |
| 4 | B | `SELECT * FROM lab9.antrean_pekerjaan WHERE job_id = 2 FOR UPDATE NOWAIT;` | Diharapkan gagal seketika karena baris sedang dikunci Sesi A. |
| 5 | B | `ROLLBACK;` | Mengakhiri transaksi yang mengalami kegagalan. |
| 6 | A | `ROLLBACK;` | Transaksi dibatalkan dan lock dilepaskan. |

### Pesan Galat yang Diharapkan

```text
ERROR: could not obtain lock on row in relation "antrean_pekerjaan"
SQLSTATE: 55P03
```

Pada pengujian ini, Sesi A mengunci baris dengan `job_id = 2`. Ketika Sesi B mencoba mengunci baris yang sama menggunakan `NOWAIT`, PostgreSQL langsung menghasilkan galat karena lock tidak dapat diperoleh.

SQLSTATE `55P03` menunjukkan bahwa lock yang dibutuhkan tidak dapat diperoleh. Berbeda dengan penguncian biasa yang dapat membuat transaksi menunggu, `NOWAIT` langsung menghasilkan galat jika baris sedang dikunci transaksi lain.

Setelah query Sesi B gagal, transaksi perlu diakhiri menggunakan `ROLLBACK` sebelum melanjutkan perintah lain dalam transaksi tersebut.

---

## Q26. Write Skew pada REPEATABLE READ

*Write skew* merupakan anomali yang dapat terjadi ketika dua transaksi membaca kondisi data yang sama, kemudian memperbarui baris berbeda berdasarkan hasil pembacaan tersebut. Walaupun kedua transaksi berhasil, hasil akhirnya dapat melanggar aturan bisnis.

Pada pengujian ini, aturan bisnis yang digunakan adalah minimal satu dokter harus tetap aktif.

### Hasil Pengujian

| Urutan | Sesi | Perintah | Hasil yang Diharapkan |
|---:|:---:|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` kemudian menghitung dokter aktif. | Jumlah dokter aktif adalah `2`. |
| 2 | B | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` kemudian menghitung dokter aktif. | Jumlah dokter aktif adalah `2`. |
| 3 | A | `UPDATE lab9.dokter_jaga SET is_aktif = FALSE WHERE dokter_id = 1;` | `UPDATE 1`. |
| 4 | B | `UPDATE lab9.dokter_jaga SET is_aktif = FALSE WHERE dokter_id = 2;` | `UPDATE 1`. |
| 5 | A | `COMMIT;` | Transaksi berhasil di-commit. |
| 6 | B | `COMMIT;` | Diharapkan berhasil di-commit. |
| 7 | A | `SELECT COUNT(*) FROM lab9.dokter_jaga WHERE is_aktif = TRUE;` | Jumlah dokter aktif menjadi `0`. |

Pada awal pengujian, terdapat dua dokter aktif, yaitu Andi dan Budi. Sesi A dan Sesi B sama-sama membaca jumlah dokter aktif sebanyak dua orang menggunakan tingkat isolasi `REPEATABLE READ`.

Setelah itu, Sesi A menonaktifkan Andi, sedangkan Sesi B menonaktifkan Budi. Karena kedua transaksi memperbarui baris yang berbeda, keduanya dapat berhasil melakukan `COMMIT`.

Akibatnya, tidak ada dokter yang aktif lagi. Kondisi ini menunjukkan terjadinya *write skew*, karena kedua transaksi berhasil dijalankan, tetapi hasil akhirnya melanggar aturan bisnis bahwa minimal satu dokter harus tetap aktif.

Percobaan ini menunjukkan bahwa `REPEATABLE READ` tidak selalu mencegah anomali yang melibatkan ketergantungan antarbari s. Oleh karena itu, aturan bisnis tertentu memerlukan perlindungan tambahan agar tetap terpenuhi ketika beberapa transaksi berjalan bersamaan.

---

## Q27. SERIALIZABLE dan SQLSTATE 40001

`SERIALIZABLE` merupakan tingkat isolasi transaksi yang dirancang untuk mencegah hasil transaksi yang tidak setara dengan urutan eksekusi serial yang valid. PostgreSQL menggunakan mekanisme *Serializable Snapshot Isolation* (SSI) untuk mendeteksi konflik serialisasi.

Pengujian ini mengulang skenario Q26 dengan tingkat isolasi `SERIALIZABLE`.

### Hasil Pengujian yang Diharapkan

| Urutan | Sesi | Perintah | Hasil yang Diharapkan |
|---:|:---:|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;` kemudian menghitung dokter aktif. | Jumlah dokter aktif adalah `2`. |
| 2 | B | `BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;` kemudian menghitung dokter aktif. | Jumlah dokter aktif adalah `2`. |
| 3 | A | `UPDATE lab9.dokter_jaga SET is_aktif = FALSE WHERE dokter_id = 1;` | `UPDATE 1`, jika belum terjadi kegagalan serialisasi. |
| 4 | B | `UPDATE lab9.dokter_jaga SET is_aktif = FALSE WHERE dokter_id = 2;` | `UPDATE 1`, jika belum terjadi kegagalan serialisasi. |
| 5 | A | `COMMIT;` | Diharapkan berhasil jika Sesi A tidak menjadi transaksi yang dibatalkan. |
| 6 | B | `COMMIT;` | Salah satu transaksi diharapkan gagal dengan SQLSTATE `40001` ketika konflik serialisasi terdeteksi. |
| 7 | B | `ROLLBACK;` | Jalankan jika transaksi Sesi B mengalami kegagalan dan masih perlu diakhiri. |

### Pesan Galat yang Mungkin Muncul

```text
ERROR: could not serialize access due to read/write dependencies among transactions
SQLSTATE: 40001
```

Pada tingkat isolasi `SERIALIZABLE`, PostgreSQL mendeteksi ketergantungan baca-tulis ant transaksi yang dapat menghasilkan anomali serialisasi. Jika konflik terdeteksi, PostgreSQL dapat membatalkan salah satu transaksi dengan SQLSTATE `40001`.

Dengan demikian, PostgreSQL mencegah kedua transaksi berhasil menghasilkan kondisi akhir yang melanggar aturan bisnis. Transaksi yang gagal perlu diulang dari awal setelah kegagalan ditangani dengan benar.

Berbeda dengan Q26, ketika menggunakan `SERIALIZABLE`, kedua transaksi tidak dapat sama-sama berhasil jika hasil akhirnya menyebabkan pelanggaran aturan bisnis pada skenario *write skew* tersebut.

**Catatan:** Kegagalan serialisasi dapat muncul saat perintah `UPDATE` atau `COMMIT`, bergantung pada urutan eksekusi dan saat PostgreSQL mendeteksi konflik. Pesan galat dan sesi yang dibatalkan harus disesuaikan dengan hasil aktual pengujian.

---

## Q28. Fungsi SIREAD Lock dan Sifat SELECT dalam SERIALIZABLE

### Fungsi SIREAD Lock

*SIREAD lock* merupakan mekanisme internal PostgreSQL yang digunakan dalam *Serializable Snapshot Isolation* (SSI) untuk mencatat pembacaan data. Informasi tersebut membantu PostgreSQL mendeteksi ketergantungan baca-tulis ant transaksi yang berpotensi menyebabkan anomali serialisasi.

### Mengapa SELECT Tidak Mengunci Semua Baris?

Pada tingkat isolasi `SERIALIZABLE`, PostgreSQL menggunakan SSI dan *predicate locking* untuk mendeteksi konflik yang dapat menyebabkan hasil transaksi tidak konsisten.

Mekanisme ini tidak mengharuskan setiap perintah `SELECT` memblokir seluruh transaksi lain yang membaca atau mengubah data. Oleh karena itu, `SERIALIZABLE` tidak berarti setiap `SELECT` mengunci semua baris seperti `SELECT ... FOR UPDATE`.

Dengan mekanisme tersebut, PostgreSQL dapat mendeteksi konflik serialisasi tanpa harus selalu menghalangi transaksi lain ketika membaca data.

---

## Q29. Pseudocode Retry Transaksi

Retry merupakan mekanisme untuk mengulang transaksi ketika terjadi kegagalan yang dapat dipulihkan, seperti konflik serialisasi atau deadlock.

### Pseudocode

```python
max_retries = 3
base_delay = 0.1

for attempt in range(max_retries):
    try:
        db.execute(
            "BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;"
        )

        # Jalankan seluruh operasi database dalam transaksi.

        db.execute("COMMIT;")

        # Operasi eksternal dilakukan setelah COMMIT berhasil.
        send_notification()
        break

    except (SerializationFailure, DeadlockDetected):
        db.execute("ROLLBACK;")

        if attempt == max_retries - 1:
            raise

        delay = base_delay * (2 ** attempt)
        delay += random.uniform(0, base_delay)
        time.sleep(delay)
```

Retry digunakan ketika transaksi mengalami kegagalan akibat konflik serialisasi dengan SQLSTATE `40001` atau deadlock dengan SQLSTATE `40P01`.

Jika transaksi gagal, seluruh transaksi perlu diulang dari awal setelah dilakukan `ROLLBACK`. Hal ini diperlukan karena data yang dibaca pada percobaan sebelumnya mungkin sudah tidak sesuai dengan keadaan database terbaru.

Jumlah percobaan dibatasi menggunakan `max_retries` agar proses tidak berjalan tanpa henti. Jeda eksponensial dihitung dengan rumus `base_delay * (2 ** attempt)`, sehingga waktu tunggu bertambah pada setiap percobaan. Penambahan *jitter* memberikan variasi waktu tunggu agar transaksi yang gagal bersamaan tidak terus mencoba kembali pada waktu yang sama.

Operasi eksternal, seperti mengirim notifikasi atau email, sebaiknya dilakukan setelah `COMMIT` berhasil agar notifikasi tidak dikirim untuk transaksi yang gagal. Dalam implementasi nyata, pola *transactional outbox* atau mekanisme idempotensi dapat digunakan untuk meningkatkan keandalan proses tersebut.

Pseudocode ini bersifat umum. Nama exception dan cara penanganan transaksi perlu disesuaikan dengan library database yang digunakan.

---

# Langkah 6 · Q30–Q32: Analisis dan Rekomendasi

«Diisi anggota pemegang Langkah 6. Q30 menggabungkan tabel Q11 di atas dengan hasil Q26–Q27.»

## Q30. Matriks enam anomali
## Q31. Rekomendasi isolation level
## Q32. Tiga pelajaran utama

---

# Kesimpulan

«Dilengkapi setelah Langkah 3–6 selesai. Tiga pelajaran dari Langkah 1–2 yang sudah bisa
disandarkan pada bukti:»

1. **Transaksi adalah satu kesatuan, bukan kumpulan perintah.** Pada Q5, `UPDATE` penambahan
   1 rupiah yang sudah berhasil tetap hilang setelah `ROLLBACK` karena perintah sesudahnya
   ditolak `CHECK` dengan SQLSTATE `23514`. Setelah galat itu, bahkan `SELECT` pun ditolak
   dengan `25P02` — jadi penanganan galat harus mengulang seluruh transaksi, bukan satu
   perintah.
2. **Menaikkan isolation level menukar satu masalah dengan masalah lain.** Urutan perintah yang
   identik memberi 1.000.000 → 700.000 pada `READ COMMITTED` (Q6) tetapi 1.000.000 → 1.000.000
   pada `REPEATABLE READ` (Q7); harganya adalah `UPDATE` berikutnya gagal dengan `40001`.
   Konsistensi pembacaan dibayar dengan kewajiban menyediakan retry.
3. **Anomali yang paling berbahaya adalah yang tidak memunculkan galat.** Pada Q10, dua
   penarikan senilai 100.000 dan 50.000 menghasilkan saldo 950.000 bukan 850.000, dan seluruh
   sembilan perintahnya melaporkan sukses. Tidak ada isolation level yang menutupnya; yang
   menutupnya adalah cara menulis perintah `UPDATE` itu sendiri.

# Pengungkapan penggunaan AI dan verifikasi

| Anggota | Bagian | Pemakaian AI | Cara verifikasi |
|---|---|---|---|
| Viter | Langkah 1 (Q1–Q5), Langkah 2 (Q6–Q11), `q00_setup.sql`, `README.md`, kerangka laporan | Claude (Opus 5) dipakai untuk menyusun urutan perintah dua sesi, merapikan skrip SQL, dan menulis draf penjelasan | Seluruh perintah Q1–Q11 dijalankan sendiri pada dua jendela `psql` di kontainer `msbd-pg`; setiap angka pada tabel urutan, pesan galat, dan SQLSTATE dicocokkan dengan keluaran psql yang tersimpan di `bukti/hasil-sesi.txt`. Perilaku `READ UNCOMMITTED` dan `40001` diperiksa ulang terhadap dokumentasi resmi PostgreSQL bab *Transaction Isolation* |
| «nama» | Langkah 3 | «isi sendiri» | «isi sendiri» |
| Naifah | Langkah 4 | AI digunakan untuk membantu memahami materi, ketentuan tugas, pengerjaan query, dan penjelasan selama menyelesaikan Langkah 4. | Mengecek kembali hasil dan penjelasan dengan melihat bukti pengujian yang ada. |
| Nadine | Langkah 5 (Q24-Q29) | AI digunakan untuk membantu memahami materi, ketentuan tugas, penyusunan query SQL, dan penjelasan selama menyelesaikan Langkah 5. | Mengecek kembali query, hasil yang diharapkan, dan penjelasan dengan mencocokkannya terhadap bukti pengujian PostgreSQL. |
| «nama» | Langkah 6 | «isi sendiri» | «isi sendiri» |

# Langkah 3 · Q12–Q17: Mencegah Lost Update dan Memahami MVCC

Bukti urutan lengkap kedua sesi untuk Langkah 3 ada di
[`bukti/isolation-level.md`](bukti/isolation-level.md), dan keluaran psql mentahnya di
[`bukti/hasil-sesi.txt`](bukti/hasil-sesi.txt).

## Q12. Memperbaiki lost update dengan pembaruan atomik

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | B | `BEGIN;` | `BEGIN` |
| 3 | A | `UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1 AND saldo >= 100000;` | `UPDATE 1` |
| 4 | B | `UPDATE lab9.rekening SET saldo = saldo - 50000 WHERE rekening_id = 1 AND saldo >= 50000;` | *(Menunggu Sesi A)* |
| 5 | A | `COMMIT;` | `COMMIT` |
| 6 | B | *(Melanjutkan eksekusi)* | `UPDATE 1` |
| 7 | B | `COMMIT;` | `COMMIT` |
| 8 | A | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | **850000.00** |

**Menghitung di basis data jauh lebih aman daripada menulis nilai hasil hitung aplikasi.**
Pada Q10, aplikasi membaca data lalu menghitung nilai tetap di memori lokal, sehingga nilai yang
ditulis bersifat absolut dan mengabaikan mutasi yang terjadi di antara waktu baca dan tulis. 
Sebaliknya, ekspresi `SET saldo = saldo - 100000` adalah operasi atomik di dalam PostgreSQL.
Ketika Sesi A memegang *exclusive row lock*, Sesi B tertahan di langkah 4. Begitu Sesi A commit,
PostgreSQL membaca versi baris yang paling baru (*latest committed row version*) sebelum
menjalankan pengurangan milik Sesi B. Hasilnya adalah 850.000 — kedua pengurangan diakomodasi
penuh tanpa data yang hilang.

## Q13. Pessimistic Locking dengan SELECT ... FOR UPDATE

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT saldo ... WHERE rekening_id = 1 FOR UPDATE;` | **1000000.00** |
| 3 | B | `BEGIN;` | `BEGIN` |
| 4 | B | `SELECT saldo ... WHERE rekening_id = 1 FOR UPDATE;` | *(Menunggu Sesi A)* |
| 5 | A | `UPDATE ... SET saldo = 900000 WHERE rekening_id = 1;` | `UPDATE 1` |
| 6 | A | `COMMIT;` | `COMMIT` |
| 7 | B | *(Lock terlepas, query selesai)* | **900000.00** |
| 8 | B | `UPDATE ... SET saldo = 850000 WHERE rekening_id = 1;` | `UPDATE 1` |
| 9 | B | `COMMIT;` | `COMMIT` |

**Sesi B menunggu pada langkah 4**, tepat saat ia mencoba mengunci baris yang sedang dikunci
eksklusif oleh transaksi Sesi A. Begitu Sesi A melakukan `COMMIT` pada langkah 6, antrean lock
terlepas dan Sesi B langsung disajikan nilai baris terbaru (900.000, bukan 1.000.000).
Dengan mengunci baris di awal pembacaan, aplikasi menjamin tidak ada transaksi lain yang dapat
mengubah baris tersebut selama proses kalkulasi berlangsung. Pola ini merupakan pendekatan
*pessimistic locking*, sangat cocok bila kalkulasi aplikasi memerlukan proses bisnis yang rumit
di memori aplikasi sebelum nilai akhir ditulis kembali ke database.

## Q14. Optimistic Locking menggunakan kolom version_no

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `SELECT saldo, version_no ... WHERE rekening_id = 1;` | `1000000.00`, ver `1` |
| 3 | B | `BEGIN;` | `BEGIN` |
| 4 | B | `SELECT saldo, version_no ... WHERE rekening_id = 1;` | `1000000.00`, ver `1` |
| 5 | A | `UPDATE ... saldo = 900000, version_no = 2 WHERE ... version_no = 1;` | `UPDATE 1` |
| 6 | A | `COMMIT;` | `COMMIT` |
| 7 | B | `UPDATE ... saldo = 950000, version_no = 2 WHERE ... version_no = 1;` | **`UPDATE 0`** |
| 8 | B | `COMMIT;` | `COMMIT` |

**Aplikasi mendeteksi perubahan data melalui jumlah baris yang terpengaruh (affected rows).**
Ketika transaksi B mencoba mengeksekusi `UPDATE` dengan kriteria `version_no = 1`, baris tersebut
sudah tidak memenuhi syarat karena Sesi A telah menaikkan versinya menjadi 2. PostgreSQL
mengembalikan status `UPDATE 0`. Driver/aplikasi mendeteksi angka 0 ini sebagai sinyal bahwa data
telah dimodifikasi oleh transaksi paralel, sehingga aplikasi dapat menolak operasi secara elegan
atau memicu retry tanpa menimbulkan tabrakan lock fisik di level basis data.

## Q15. Snapshot MVCC: Pembaca tidak menunggu penulis

| Urutan | Sesi | Perintah | Hasil |
|---:|---|---|---|
| 1 | A | `BEGIN;` | `BEGIN` |
| 2 | A | `UPDATE lab9.rekening SET saldo = 500000 WHERE rekening_id = 1;` | `UPDATE 1` (uncommitted) |
| 3 | B | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | **1000000.00** |
| 4 | B | `SELECT pg_blocking_pids(pg_backend_pid());` | `{}` (Kosong) |
| 5 | A | `ROLLBACK;` | `ROLLBACK` |

Secara konseptual, **MVCC (*Multi-Version Concurrency Control*) membuat snapshot berbasis versi
baris tuple**. Saat baris di-update oleh Sesi A, PostgreSQL tidak menimpa data di tempat (*in-place
overwrite*), melainkan menyisipkan versi baris baru (*tuple version*) sambil tetap mempertahankan
versi baris yang lama. Operasi `SELECT` biasa pada Sesi B hanya membaca versi baris yang sudah
di-commit dan sesuai dengan snapshot transaksinya. Karena keduanya mengakses tuple yang secara
fisik berbeda di dalam heap block, pembaca tidak pernah memblokir penulis, dan penulis tidak
pernah memblokir pembaca.

## Q16. Analisis metadata transaksi internal xmin dan xmax

Nilai `xmin` dan `xmax` adalah nomor ID transaksi internal PostgreSQL (XID) yang disematkan pada
setiap baris heap tuple:
* **`xmin`**: ID transaksi yang menyisipkan (*insert*) versi baris tersebut.
* **`xmax`**: ID transaksi yang memperbarui (*update*) atau menghapus (*delete*) baris tersebut.
  Jika baris masih aktif dan belum diubah, `xmax` bernilai 0.

**Mengapa satu nilai saja tidak cukup untuk mendiagnosis status visibilitas?**
Saat sebuah transaksi memodifikasi baris lalu mengalami `ROLLBACK`, nilai `xmax` pada baris lama
tetap mencatat XID dari transaksi yang gagal tersebut (misal `xmax = 751`). Nilai 751 itu tidak
langsung dihapus secara fisik saat rollback. PostgreSQL wajib memeriksa status XID tersebut ke
dalam **Commit Log (CLOG / `pg_xact`)** untuk memastikan apakah transaksi pembuat/penghapus itu
berstatus *COMMITTED*, *ABORTED*, atau *IN-PROGRESS*. Visibilitas baris adalah perpaduan antara
nilai metadata di tuple (`xmin`/`xmax`) dan status global transaksi di CLOG.

## Q17. Manfaat MVCC dan urgensi pemeliharaan VACUUM

* **Manfaat Utama MVCC**: Menyediakan skalabilitas konkurensi tingkat tinggi. Beban query pembacaan
  laporan/analitik (*read workload*) tidak akan memperlambat atau mengunci proses transaksi tulis
  (*write transactions*), sehingga throughput basis data tetap tinggi tanpa mengorbankan isolasi data.
* **Mengapa VACUUM Sangat Diperlukan?**: Karena pembaruan data pada MVCC dilakukan dengan membuat
  tuple baru, versi baris yang lama berubah status menjadi **dead tuple** setelah transaksi yang
  mengaksesnya selesai. Dead tuple ini menumpuk ruang penyimpanan (*table bloat*) dan memperlambat
  proses *sequential scan*. Proses `VACUUM` bertugas memindai halaman heap, membebaskan ruang yang
  ditempati oleh dead tuple agar dapat dipakai kembali (*reused*) oleh tuple baru, serta mencegah
  masalah kritis *transaction ID wraparound*.

