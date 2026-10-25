-- Q8: Buat ev_salah_idx (terjadi_pada, customer_id), lalu periksa apakah index dipakai
-- dan apakah node Sort masih muncul.
\timing on
SET max_parallel_workers_per_gather = 0;

CREATE INDEX ev_salah_idx
ON lab6.event_log (terjadi_pada, customer_id);
ANALYZE lab6.event_log;

SELECT pg_size_pretty(pg_relation_size('lab6.ev_salah_idx')) AS ukuran_ev_salah_idx;

\echo '===== Q8 urutan salah · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
\echo '===== Q8 urutan salah · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
\echo '===== Q8 urutan salah · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
