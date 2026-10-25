-- Q9: Hapus index urutan salah, buat ev_benar_idx (customer_id, terjadi_pada DESC),
-- lalu bandingkan tiga waktu dalam satu tabel bersama Q7 dan Q8.
\timing on
SET max_parallel_workers_per_gather = 0;

DROP INDEX IF EXISTS lab6.ev_salah_idx;

CREATE INDEX ev_benar_idx
ON lab6.event_log (customer_id, terjadi_pada DESC);
ANALYZE lab6.event_log;

SELECT pg_size_pretty(pg_relation_size('lab6.ev_benar_idx')) AS ukuran_ev_benar_idx;

\echo '===== Q9 urutan benar · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
\echo '===== Q9 urutan benar · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
\echo '===== Q9 urutan benar · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
