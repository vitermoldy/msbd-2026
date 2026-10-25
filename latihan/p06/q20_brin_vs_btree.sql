-- Q20: Uji rentang tujuh hari dengan BRIN dan B-Tree, catat pemenang
-- serta selisih Buffers.
\timing on
SET max_parallel_workers_per_gather = 0;

SELECT count(*) AS baris_tujuh_hari,
       round(100.0*count(*)/2000000, 2) AS persen_tabel
FROM lab6.event_log
WHERE terjadi_pada >= '2024-05-01 00:00+07'
  AND terjadi_pada <  '2024-05-08 00:00+07';

-- 1. Hanya BRIN yang tersedia. Index B-Tree pada waktu dan index lebar yang
--    bisa melayani query ini dihapus sementara di dalam transaksi, lalu
--    dikembalikan oleh ROLLBACK.
BEGIN;
DROP INDEX lab6.idx_btree_terjadi;
DROP INDEX lab6.ev_terjadi_pada_idx;
DROP INDEX lab6.ev_cover3_idx;
\echo '===== Q20a hanya BRIN · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log
WHERE terjadi_pada >= '2024-05-01 00:00+07'
  AND terjadi_pada <  '2024-05-08 00:00+07';
\echo '===== Q20a hanya BRIN · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log
WHERE terjadi_pada >= '2024-05-01 00:00+07'
  AND terjadi_pada <  '2024-05-08 00:00+07';
\echo '===== Q20a hanya BRIN · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log
WHERE terjadi_pada >= '2024-05-01 00:00+07'
  AND terjadi_pada <  '2024-05-08 00:00+07';
ROLLBACK;

-- 2. Hanya B-Tree yang tersedia
BEGIN;
DROP INDEX lab6.idx_brin_terjadi;
DROP INDEX lab6.ev_terjadi_pada_idx;
DROP INDEX lab6.ev_cover3_idx;
\echo '===== Q20b hanya B-Tree · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log
WHERE terjadi_pada >= '2024-05-01 00:00+07'
  AND terjadi_pada <  '2024-05-08 00:00+07';
\echo '===== Q20b hanya B-Tree · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log
WHERE terjadi_pada >= '2024-05-01 00:00+07'
  AND terjadi_pada <  '2024-05-08 00:00+07';
\echo '===== Q20b hanya B-Tree · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log
WHERE terjadi_pada >= '2024-05-01 00:00+07'
  AND terjadi_pada <  '2024-05-08 00:00+07';
ROLLBACK;

-- 3. Ukuran keduanya, sebagai sisi lain dari perbandingan
SELECT pg_size_pretty(pg_relation_size('lab6.idx_brin_terjadi')) AS ukuran_brin,
       pg_size_pretty(pg_relation_size('lab6.idx_btree_terjadi')) AS ukuran_btree;
