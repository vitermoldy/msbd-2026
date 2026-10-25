-- Q17: Uji payload @> '{"promo": true}', pastikan GIN dipakai, dan bandingkan
-- ukurannya dengan heap.
\timing on
SET max_parallel_workers_per_gather = 0;

-- 1. Buat Indeks GIN pada kolom payload
CREATE INDEX IF NOT EXISTS idx_gin_payload ON lab6.event_log USING gin (payload jsonb_path_ops);
ANALYZE lab6.event_log;

-- 2. Uji Query JSONB dengan GIN, tiga kali
\echo '===== Q17 payload @> promo dengan GIN · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE payload @> '{"promo": true}';
\echo '===== Q17 payload @> promo dengan GIN · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE payload @> '{"promo": true}';
\echo '===== Q17 payload @> promo dengan GIN · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE payload @> '{"promo": true}';

-- 3. Pembanding tanpa GIN: index dihapus sementara di dalam transaksi
\echo '===== Q17 tanpa GIN · run 1'
BEGIN;
DROP INDEX lab6.idx_gin_payload;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE payload @> '{"promo": true}';
ROLLBACK;

-- 4. Cek Ukuran Indeks GIN vs Heap (nama index WAJIB diawali skema lab6)
SELECT
    pg_size_pretty(pg_relation_size('lab6.idx_gin_payload')) AS ukuran_gin_payload,
    pg_size_pretty(pg_relation_size('lab6.event_log')) AS ukuran_heap,
    round(100.0*pg_relation_size('lab6.idx_gin_payload')/pg_relation_size('lab6.event_log'), 2)
      AS persen_dari_heap,
    (SELECT count(*) FROM lab6.event_log WHERE payload @> '{"promo": true}') AS baris_cocok;
