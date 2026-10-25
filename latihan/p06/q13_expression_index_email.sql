-- Q13: Bandingkan query `email = ...` (kolom apa adanya) dengan
-- `lower(email) = ...` (sesuai definisi index ekspresi), untuk melihat
-- index mana -- kalau ada -- yang dipakai optimizer.
\timing on
SET max_parallel_workers_per_gather = 0;

CREATE INDEX IF NOT EXISTS ev_email_lower_idx
    ON lab6.event_log (lower(email));
ANALYZE lab6.event_log;

SELECT pg_size_pretty(pg_relation_size('lab6.ev_email_lower_idx')) AS ukuran_index_ekspresi;
SELECT email FROM lab6.event_log WHERE event_id = 12345;

-- Versi 1: tanpa ekspresi -- index ekspresi TIDAK cocok untuk ini
\echo '===== Q13a email = ... tanpa ekspresi · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE email = 'user12345@contoh.ac.id';
\echo '===== Q13a email = ... tanpa ekspresi · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE email = 'user12345@contoh.ac.id';
\echo '===== Q13a email = ... tanpa ekspresi · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE email = 'user12345@contoh.ac.id';

-- Versi 2: pakai lower(email), persis sesuai definisi index
\echo '===== Q13b lower(email) = ... cocok dengan index · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE lower(email) = lower('user12345@contoh.ac.id');
\echo '===== Q13b lower(email) = ... cocok dengan index · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE lower(email) = lower('user12345@contoh.ac.id');
\echo '===== Q13b lower(email) = ... cocok dengan index · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE lower(email) = lower('user12345@contoh.ac.id');

-- Versi 3: ekspresi lain (upper) -- index tetap tidak terpakai
\echo '===== Q13c upper(email) = ... ekspresi berbeda · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE upper(email) = upper('user12345@contoh.ac.id');
