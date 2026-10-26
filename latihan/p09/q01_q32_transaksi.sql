-- =====================================================================
-- Latihan P09 · Menguji Transaksi dan Kendali Konkurensi
-- Berkas ini memuat seluruh perintah Q1-Q32 dalam urutan pengerjaan.
--
-- CARA MEMBACA: perintah ditandai sesi yang menjalankannya.
--   [A] dijalankan di Sesi A      [B] dijalankan di Sesi B
--   [A+B] boleh di sesi mana pun (tidak bergantung konkurensi)
-- Perintah dijalankan BERURUTAN dari atas ke bawah, berpindah jendela
-- sesuai tandanya. Jangan menutup transaksi sebelum diperintahkan.
--
-- Bagian Q1-Q11 diisi oleh Viter (Langkah 1 dan 2).
-- Q12-Q32 menyusul dari anggota lain, memakai pola penandaan yang sama.
-- =====================================================================


-- =====================================================================
-- LANGKAH 1 · Q1-Q5 · Setup dan Batas Transaksi (satu sesi saja)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. Kondisi awal dan jumlah saldo keseluruhan.
-- ---------------------------------------------------------------------
-- [A]
SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;
-- [A]
SELECT count(*) AS jumlah_rekening, sum(saldo) AS total_saldo FROM lab9.rekening;

-- ---------------------------------------------------------------------
-- Q2. BEGIN, ubah saldo, periksa sebelum COMMIT. Apa yang terlihat di sesi lain?
--     Bagian ini WAJIB dua sesi.
-- ---------------------------------------------------------------------
-- [A]
BEGIN;
-- [A]
UPDATE lab9.rekening SET saldo = saldo - 250000 WHERE rekening_id = 1;
-- [A] Sesi A melihat perubahannya sendiri
SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;
-- [B] Sesi B membaca tabel yang sama, TANPA menunggu
SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;
-- [B] Bukti bahwa Sesi B tidak sedang diblokir siapa pun
SELECT pg_blocking_pids(pg_backend_pid()) AS menunggu_pid;
-- [A]
ROLLBACK;
-- [B] Sesudah ROLLBACK, Sesi B tetap melihat nilai lama
SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;

-- ---------------------------------------------------------------------
-- Q3. COMMIT lawan ROLLBACK: perubahan mana yang bertahan?
-- ---------------------------------------------------------------------
-- [A] Transfer yang di-COMMIT
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1;
UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 2;
COMMIT;
-- [A] Hasilnya bertahan: 900000 dan 1100000
SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;

-- [A] Perubahan yang di-ROLLBACK
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 400000 WHERE rekening_id = 1;
-- [A] Di dalam transaksi terlihat 500000
SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;
ROLLBACK;
-- [A] Sesudah ROLLBACK kembali ke 900000
SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;

-- ---------------------------------------------------------------------
-- Q4. SAVEPOINT dan ROLLBACK TO SAVEPOINT: bagian mana yang dibatalkan?
-- ---------------------------------------------------------------------
-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 50000 WHERE rekening_id = 1;   -- tahap 1
SAVEPOINT sebelum_transfer_kedua;
UPDATE lab9.rekening SET saldo = saldo - 70000 WHERE rekening_id = 1;   -- tahap 2
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;     -- 780000
ROLLBACK TO SAVEPOINT sebelum_transfer_kedua;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;     -- 850000
COMMIT;
-- [A] Yang bertahan hanya tahap 1
SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;

-- ---------------------------------------------------------------------
-- Q5. Atomicity dan consistency lewat transaksi dan CHECK (saldo >= 0).
-- ---------------------------------------------------------------------
-- [A] \set VERBOSITY verbose  -- agar SQLSTATE ikut tercetak
BEGIN;
UPDATE lab9.rekening SET saldo = saldo + 1 WHERE rekening_id = 2;          -- berhasil
UPDATE lab9.rekening SET saldo = saldo - 99999999 WHERE rekening_id = 1;   -- ditolak CHECK, SQLSTATE 23514
SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;         -- SQLSTATE 25P02
ROLLBACK;
-- [A] Kedua UPDATE hilang bersama-sama, dan total saldo tetap
SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;
SELECT sum(saldo) AS total_saldo FROM lab9.rekening;

-- [A] Kembalikan data ke kondisi awal sebelum Langkah 2
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1, 2);
SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;


-- =====================================================================
-- LANGKAH 2 · Q6-Q11 · Isolation Level dan Anomali (dua sesi)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q6. Non-repeatable read pada READ COMMITTED.
-- ---------------------------------------------------------------------
-- [A]
BEGIN;
SHOW transaction_isolation;                                               -- read committed
SELECT saldo AS bacaan_pertama FROM lab9.rekening WHERE rekening_id = 1;  -- 1000000.00
-- [B] Sesi B mengubah dan MENGAKHIRI transaksinya (autocommit)
UPDATE lab9.rekening SET saldo = saldo - 300000 WHERE rekening_id = 1;
-- [A] Pembacaan kedua di transaksi yang SAMA
SELECT saldo AS bacaan_kedua FROM lab9.rekening WHERE rekening_id = 1;    -- 700000.00
COMMIT;

-- [A] Kembalikan kondisi awal
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1, 2);

-- ---------------------------------------------------------------------
-- Q7. Skenario yang sama pada REPEATABLE READ.
-- ---------------------------------------------------------------------
-- [A] \set VERBOSITY verbose
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SHOW transaction_isolation;                                               -- repeatable read
SELECT saldo AS bacaan_pertama FROM lab9.rekening WHERE rekening_id = 1;  -- 1000000.00
-- [B]
UPDATE lab9.rekening SET saldo = saldo - 300000 WHERE rekening_id = 1;
-- [A] Pembacaan kedua TIDAK berubah, snapshot dipertahankan
SELECT saldo AS bacaan_kedua FROM lab9.rekening WHERE rekening_id = 1;    -- 1000000.00
-- [A] Tetapi menulis baris yang sudah diubah sesi lain akan gagal: SQLSTATE 40001
UPDATE lab9.rekening SET saldo = saldo - 1 WHERE rekening_id = 1;
-- [A]
ROLLBACK;
-- [A] Nilai yang bertahan adalah hasil Sesi B
SELECT saldo AS setelah_semua FROM lab9.rekening WHERE rekening_id = 1;   -- 700000.00

-- [A] Kembalikan kondisi awal
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1, 2);

-- ---------------------------------------------------------------------
-- Q8. Phantom read: READ COMMITTED lawan REPEATABLE READ.
-- ---------------------------------------------------------------------
-- [A] Tabel eksperimen terpisah agar lab9.rekening tetap bersih
DROP TABLE IF EXISTS lab9.rekening_uji;
CREATE TABLE lab9.rekening_uji (
    rekening_id INT PRIMARY KEY,
    pemilik TEXT NOT NULL,
    saldo NUMERIC(12,2) NOT NULL
);
INSERT INTO lab9.rekening_uji VALUES
  (1,'Ani',1000000), (2,'Budi',1000000), (3,'Citra',400000), (4,'Dedi',250000);

-- Bagian 1: READ COMMITTED
-- [A]
BEGIN;
SELECT count(*) AS hitung_pertama_rc FROM lab9.rekening_uji WHERE saldo > 500000;  -- 2
-- [B] Baris baru yang memenuhi syarat, langsung ter-commit
INSERT INTO lab9.rekening_uji VALUES (5,'Eka',900000);
-- [A] Query yang sama, hasil berubah: baris hantu muncul
SELECT count(*) AS hitung_kedua_rc FROM lab9.rekening_uji WHERE saldo > 500000;    -- 3
COMMIT;

-- Bagian 2: REPEATABLE READ
-- [A]
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) AS hitung_pertama_rr FROM lab9.rekening_uji WHERE saldo > 500000;  -- 3
-- [B]
INSERT INTO lab9.rekening_uji VALUES (6,'Fajar',800000);
-- [A] Hasil TIDAK berubah
SELECT count(*) AS hitung_kedua_rr FROM lab9.rekening_uji WHERE saldo > 500000;    -- 3
COMMIT;
-- [A] Sesudah transaksi selesai, baris keenam baru terlihat
SELECT count(*) AS hitung_setelah_commit FROM lab9.rekening_uji WHERE saldo > 500000;  -- 4

-- ---------------------------------------------------------------------
-- Q9. Dirty read dan perilaku READ UNCOMMITTED di PostgreSQL.
-- ---------------------------------------------------------------------
-- [A] Perubahan ekstrem yang SENGAJA tidak di-COMMIT
BEGIN;
UPDATE lab9.rekening SET saldo = 1 WHERE rekening_id = 1;
SELECT saldo AS yang_dilihat_a FROM lab9.rekening WHERE rekening_id = 1;  -- 1.00
-- [B] Minta level terendah yang dikenal standar SQL
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SHOW transaction_isolation;                                               -- read uncommitted
SELECT saldo AS yang_dilihat_b FROM lab9.rekening WHERE rekening_id = 1;  -- 1000000.00
COMMIT;
-- [A]
ROLLBACK;

-- ---------------------------------------------------------------------
-- Q10. Lost update: dua sesi menghitung di sisi aplikasi lalu menulis nilai tetap.
-- ---------------------------------------------------------------------
-- [A]
BEGIN;
SELECT saldo AS dibaca_a FROM lab9.rekening WHERE rekening_id = 1;   -- 1000000.00
-- [B]
BEGIN;
SELECT saldo AS dibaca_b FROM lab9.rekening WHERE rekening_id = 1;   -- 1000000.00
-- [A] Aplikasi A menghitung 1000000 - 100000 dan menulis nilai TETAP
UPDATE lab9.rekening SET saldo = 900000 WHERE rekening_id = 1;
COMMIT;
-- [B] Aplikasi B menghitung 1000000 - 50000 dari nilai yang sudah basi
UPDATE lab9.rekening SET saldo = 950000 WHERE rekening_id = 1;
COMMIT;
-- [A] Hasil akhir 950000: penarikan 100000 milik A hilang tanpa jejak
SELECT saldo AS saldo_akhir FROM lab9.rekening WHERE rekening_id = 1;

-- [A] Kembalikan kondisi awal sebelum Langkah 3
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1, 2);
SELECT rekening_id, pemilik, saldo FROM lab9.rekening ORDER BY rekening_id;

-- ---------------------------------------------------------------------
-- Q11. Tabel ringkas anomali -- jawabannya berupa tabel di laporan.md,
--      disusun dari hasil Q6 sampai Q10 di atas.
-- ---------------------------------------------------------------------


-- =====================================================================
-- LANGKAH 3 · Q12-Q17 · Mencegah Lost Update dan Memahami MVCC
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q12. Perbaiki lost update menggunakan pembaruan atomik (in-database update)
-- ---------------------------------------------------------------------
-- [A]
BEGIN;
-- [B]
BEGIN;
-- [A] Penarikan 100.000 secara atomik di basis data
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1 AND saldo >= 100000;
-- [B] Penarikan 50.000 secara atomik: Sesi B MENUNGGU Sesi A selesai
UPDATE lab9.rekening SET saldo = saldo - 50000 WHERE rekening_id = 1 AND saldo >= 50000;
-- [A]
COMMIT;
-- [B] Sesi B otomatis lanjut sesudah commit A, mengevaluasi saldo terkini (900000)
COMMIT;
-- [A] Saldo akhir benar 850.000 (kedua penarikan berhasil tanpa lost update)
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

-- [A] Kembalikan saldo awal
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;

-- ---------------------------------------------------------------------
-- Q13. Ulangi skenario menggunakan SELECT ... FOR UPDATE (pessimistic lock)
-- ---------------------------------------------------------------------
-- [A]
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- [B]
BEGIN;
-- [B] Sesi B tertahan (MENUNGGU lock baris dilepas oleh Sesi A)
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- [A] Sesi A melakukan mutasi dan commit
UPDATE lab9.rekening SET saldo = 900000 WHERE rekening_id = 1;
COMMIT;
-- [B] Sesi B baru terlepas dan melihat saldo 900000 yang mutakhir
UPDATE lab9.rekening SET saldo = 850000 WHERE rekening_id = 1;
COMMIT;
-- [A]
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

-- [A] Kembalikan saldo awal
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;

-- ---------------------------------------------------------------------
-- Q14. Kolom versi (optimistic locking) atau saldo lama sebagai kondisi WHERE
-- ---------------------------------------------------------------------
-- [A] Tambah kolom versi
ALTER TABLE lab9.rekening ADD COLUMN IF NOT EXISTS version_no INT DEFAULT 1;
UPDATE lab9.rekening SET version_no = 1, saldo = 1000000 WHERE rekening_id = 1;

-- [A] Aplikasi A membaca saldo dan versi
BEGIN;
SELECT saldo, version_no FROM lab9.rekening WHERE rekening_id = 1;
-- [B] Aplikasi B membaca saldo dan versi yang sama
BEGIN;
SELECT saldo, version_no FROM lab9.rekening WHERE rekening_id = 1;

-- [A] Aplikasi A commit duluan, menaikkan version_no
UPDATE lab9.rekening SET saldo = 900000, version_no = version_no + 1 WHERE rekening_id = 1 AND version_no = 1;
COMMIT;

-- [B] Aplikasi B mencoba menulis dengan modal version_no = 1
UPDATE lab9.rekening SET saldo = 950000, version_no = version_no + 1 WHERE rekening_id = 1 AND version_no = 1;
-- [B] Output: UPDATE 0 (Aplikasi mengetahui data berubah karena baris terdampak = 0)
COMMIT;

-- [A] Bersihkan kolom versi dan reset saldo
ALTER TABLE lab9.rekening DROP COLUMN IF EXISTS version_no;
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;

-- ---------------------------------------------------------------------
-- Q15. Dua SELECT biasa di tengah transaksi berbeda (Non-blocking MVCC)
-- ---------------------------------------------------------------------
-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = 500000 WHERE rekening_id = 1;
-- [B] Pembacaan tanpa FOR UPDATE langsung keluar seketika (tanpa menunggu Sesi A)
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [B] Bukti bahwa Sesi B tidak diblokir
SELECT pg_blocking_pids(pg_backend_pid()) AS antrean;
-- [A]
ROLLBACK;

-- ---------------------------------------------------------------------
-- Q16. Membaca metadata transaksi internal xmin dan xmax
-- ---------------------------------------------------------------------
-- [A]
SELECT ctid, xmin, xmax, rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = 888000 WHERE rekening_id = 1;
SELECT ctid, xmin, xmax, rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
ROLLBACK;
-- [A] Nilai xmax tetap terisi pointer transaksi batal (bukti satu nilai tak cukup)
SELECT ctid, xmin, xmax, rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

-- ---------------------------------------------------------------------
-- Q17. Manfaat MVCC dan kebutuhan VACUUM
-- ---------------------------------------------------------------------
-- [A] Cek dead tuples akibat update berkali-kali
SELECT relname, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'rekening';
-- [A] Bersihkan baris mati/kedaluwarsa
VACUUM VERBOSE lab9.rekening;

-- LANGKAH 4 · Q18-Q23 -- diisi anggota berikutnya

-- =====================================================================
-- LANGKAH 5 · Q24-Q29 · SKIP LOCKED dan SERIALIZABLE (dua sesi)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q24. SKIP LOCKED
-- ---------------------------------------------------------------------

DROP TABLE IF EXISTS lab9.antrean_pekerjaan;

CREATE TABLE lab9.antrean_pekerjaan (
    job_id SERIAL PRIMARY KEY,
    status TEXT NOT NULL
);

INSERT INTO lab9.antrean_pekerjaan (job_id, status)
VALUES
    (1, 'PENDING'),
    (2, 'PENDING'),
    (3, 'PENDING');

BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE job_id = 1
FOR UPDATE;

BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE status = 'PENDING'
FOR UPDATE SKIP LOCKED;

ROLLBACK;

ROLLBACK;

-- ---------------------------------------------------------------------
-- Q25. NOWAIT
-- ---------------------------------------------------------------------

BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE job_id = 2
FOR UPDATE;

BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE job_id = 2
FOR UPDATE NOWAIT;

ROLLBACK;

ROLLBACK;

-- ---------------------------------------------------------------------
-- Q26. WRITE SKEW DENGAN REPEATABLE READ
-- ---------------------------------------------------------------------

DROP TABLE IF EXISTS lab9.dokter_jaga;

CREATE TABLE lab9.dokter_jaga (
    dokter_id INT PRIMARY KEY,
    nama TEXT,
    is_aktif BOOLEAN
);

INSERT INTO lab9.dokter_jaga (dokter_id, nama, is_aktif)
VALUES
    (1, 'Andi', TRUE),
    (2, 'Budi', TRUE);

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT COUNT(*)
FROM lab9.dokter_jaga
WHERE is_aktif = TRUE;

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT COUNT(*)
FROM lab9.dokter_jaga
WHERE is_aktif = TRUE;

UPDATE lab9.dokter_jaga
SET is_aktif = FALSE
WHERE dokter_id = 1;

UPDATE lab9.dokter_jaga
SET is_aktif = FALSE
WHERE dokter_id = 2;

COMMIT;

COMMIT;

SELECT *
FROM lab9.dokter_jaga
ORDER BY dokter_id;

SELECT COUNT(*) AS jumlah_dokter_aktif
FROM lab9.dokter_jaga
WHERE is_aktif = TRUE;

-- ---------------------------------------------------------------------
-- Q27. SERIALIZABLE
-- ---------------------------------------------------------------------

UPDATE lab9.dokter_jaga
SET is_aktif = TRUE;

SELECT *
FROM lab9.dokter_jaga
ORDER BY dokter_id;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*)
FROM lab9.dokter_jaga
WHERE is_aktif = TRUE;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*)
FROM lab9.dokter_jaga
WHERE is_aktif = TRUE;

UPDATE lab9.dokter_jaga
SET is_aktif = FALSE
WHERE dokter_id = 1;

UPDATE lab9.dokter_jaga
SET is_aktif = FALSE
WHERE dokter_id = 2;

COMMIT;

COMMIT;

SELECT *
FROM lab9.dokter_jaga
ORDER BY dokter_id;

SELECT COUNT(*) AS jumlah_dokter_aktif
FROM lab9.dokter_jaga
WHERE is_aktif = TRUE;

-- ---------------------------------------------------------------------
-- Q28. SIREAD LOCK
-- Penjelasan ditulis pada laporan.md.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- Q29. PSEUDOCODE RETRY
-- Penjelasan ditulis pada laporan.md.
-- ---------------------------------------------------------------------

-- LANGKAH 6 · Q30-Q32 -- diisi anggota berikutnya
-- =====================================================================
