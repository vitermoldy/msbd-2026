-- Q13: Bandingkan query `email = ...` (kolom apa adanya) dengan
-- `lower(email) = ...` (sesuai definisi index ekspresi), untuk melihat
-- index mana -- kalau ada -- yang dipakai optimizer.

SET max_parallel_workers_per_gather = 0;
\timing on

CREATE INDEX IF NOT EXISTS ev_email_lower_idx
    ON lab6.event_log (lower(email));

-- GANTI nilai email di bawah dengan email yang benar-benar ada di tabelmu.
-- Contoh data dari q00_setup.sql: 'user' || g || '@contoh.ac.id' untuk g tertentu.
-- Cari dulu satu yang valid:
-- SELECT email FROM lab6.event_log LIMIT 1;

-- Jalankan MASING-MASING query ini TIGA KALI (sesuai Aturan Pengukuran),
-- catat waktu tercepat dan median untuk tiap versi.

-- Versi 1: tanpa ekspresi -- index ekspresi TIDAK cocok untuk ini
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE email = 'user12345@contoh.ac.id';

-- Versi 2: pakai lower(email), persis sesuai definisi index
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE lower(email) = lower('user12345@contoh.ac.id');
