-- Q22: Buat index pada status, lalu salin rencana untuk status SUKSES dan GAGAL.
\timing on
SET max_parallel_workers_per_gather = 0;

-- 1. Buat Indeks pada Kolom Status
CREATE INDEX IF NOT EXISTS idx_status ON lab6.event_log (status);
ANALYZE lab6.event_log;
SELECT pg_size_pretty(pg_relation_size('lab6.idx_status')) AS ukuran_idx_status;

-- 2. Uji Status SUKSES (84% baris)
\echo '===== Q22a status SUKSES 84 persen · run 1'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'SUKSES';
\echo '===== Q22a status SUKSES 84 persen · run 2'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'SUKSES';
\echo '===== Q22a status SUKSES 84 persen · run 3'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'SUKSES';

-- 3. Uji Status GAGAL (2% baris)
\echo '===== Q22b status GAGAL 2 persen · run 1'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'GAGAL';
\echo '===== Q22b status GAGAL 2 persen · run 2'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'GAGAL';
\echo '===== Q22b status GAGAL 2 persen · run 3'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'GAGAL';

-- 4. Uji Status TERTUNDA (14% baris), titik tengah di antara keduanya
\echo '===== Q22c status TERTUNDA 14 persen · run 1'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'TERTUNDA';
\echo '===== Q22c status TERTUNDA 14 persen · run 2'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'TERTUNDA';
\echo '===== Q22c status TERTUNDA 14 persen · run 3'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'TERTUNDA';

-- 5. SUKSES dipaksa memakai index, sebagai pembanding harga
\echo '===== Q22d status SUKSES dipaksa memakai index · run 1'
BEGIN; SET LOCAL enable_seqscan = off;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'SUKSES';
ROLLBACK;
