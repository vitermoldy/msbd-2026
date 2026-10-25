-- Q7: Rencana baseline tanpa index sama sekali pada customer_id maupun terjadi_pada.
-- Aturan pengukuran: parallel worker dimatikan, query dijalankan tiga kali, BUFFERS disertakan.
\timing on
SET max_parallel_workers_per_gather = 0;

SELECT indexname FROM pg_indexes WHERE schemaname = 'lab6' AND tablename = 'event_log';

\echo '===== Q7 baseline tanpa index · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
\echo '===== Q7 baseline tanpa index · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
\echo '===== Q7 baseline tanpa index · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
