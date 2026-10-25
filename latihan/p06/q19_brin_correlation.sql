-- Q19: Periksa correlation terjadi_pada di pg_stats dan bandingkan ukuran BRIN
-- dengan B-Tree pada kolom yang sama.
\timing on
SET max_parallel_workers_per_gather = 0;

-- 1. Buat BRIN pada terjadi_pada. Tanpa baris ini, seluruh perbandingan Q19 dan Q20
--    tidak dapat dijalankan ulang dari berkas ini.
CREATE INDEX IF NOT EXISTS idx_brin_terjadi ON lab6.event_log
    USING brin (terjadi_pada) WITH (pages_per_range = 128);

-- 2. Buat B-Tree pembanding di kolom yang sama (terjadi_pada)
CREATE INDEX IF NOT EXISTS idx_btree_terjadi ON lab6.event_log (terjadi_pada);
ANALYZE lab6.event_log;

-- 3. Periksa nilai correlation beberapa kolom di pg_stats
SELECT tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'lab6' AND tablename = 'event_log'
  AND attname IN ('terjadi_pada','event_id','customer_id','status')
ORDER BY correlation DESC NULLS LAST;

-- 4. Bandingkan ukuran indeks BRIN vs B-Tree
SELECT
    pg_size_pretty(pg_relation_size('lab6.idx_brin_terjadi')) AS ukuran_brin,
    pg_size_pretty(pg_relation_size('lab6.idx_btree_terjadi')) AS ukuran_btree,
    pg_size_pretty(pg_relation_size('lab6.event_log')) AS ukuran_heap,
    round(pg_relation_size('lab6.idx_btree_terjadi')::numeric
          / pg_relation_size('lab6.idx_brin_terjadi'), 0) AS btree_berapa_kali_brin;

-- 5. Bukti bahwa ukuran kecil saja tidak cukup: BRIN pada kolom yang tidak
--    terkorelasi tidak menyaring apa pun.
CREATE INDEX IF NOT EXISTS idx_brin_customer ON lab6.event_log
    USING brin (customer_id) WITH (pages_per_range = 128);
SELECT 'BRIN terjadi_pada (correlation mendekati 1)' AS varian,
       pg_size_pretty(pg_relation_size('lab6.idx_brin_terjadi')) AS ukuran
UNION ALL
SELECT 'BRIN customer_id (correlation mendekati 0)',
       pg_size_pretty(pg_relation_size('lab6.idx_brin_customer'));

\echo '===== Q19 BRIN pada customer_id saat dipaksa dipakai · run 1'
BEGIN;
DROP INDEX lab6.ev_benar_idx;
DROP INDEX lab6.ev_cover3_idx;
SET LOCAL enable_seqscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM lab6.event_log WHERE customer_id = 4211;
ROLLBACK;
DROP INDEX lab6.idx_brin_customer;
