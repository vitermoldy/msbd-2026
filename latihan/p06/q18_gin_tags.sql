-- Q18: Uji keanggotaan tags dengan @>, bandingkan rencana dengan dan tanpa GIN.
\timing on
SET max_parallel_workers_per_gather = 0;

CREATE INDEX IF NOT EXISTS idx_gin_tags ON lab6.event_log USING gin (tags);
ANALYZE lab6.event_log;

SELECT pg_size_pretty(pg_relation_size('lab6.idx_gin_tags')) AS ukuran_gin_tags,
       (SELECT count(*) FROM lab6.event_log WHERE tags @> ARRAY['kanal:1']) AS baris_satu_tag,
       (SELECT count(*) FROM lab6.event_log WHERE tags @> ARRAY['kanal:1','sumber:1']) AS baris_dua_tag;

-- 1. Uji DENGAN GIN Index, tiga kali
\echo '===== Q18a satu tag dengan GIN · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];
\echo '===== Q18a satu tag dengan GIN · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];
\echo '===== Q18a satu tag dengan GIN · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];

-- 2. Dua tag sekaligus, lebih selektif
\echo '===== Q18b dua tag dengan GIN · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1','sumber:1'];
\echo '===== Q18b dua tag dengan GIN · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1','sumber:1'];
\echo '===== Q18b dua tag dengan GIN · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1','sumber:1'];

-- 3. Uji TANPA GIN Index
SET enable_indexscan = off;
SET enable_bitmapscan = off;
\echo '===== Q18c satu tag tanpa GIN · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];
\echo '===== Q18c satu tag tanpa GIN · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];
\echo '===== Q18c satu tag tanpa GIN · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];

-- 4. Kembalikan Setting Index Scan
SET enable_indexscan = on;
SET enable_bitmapscan = on;
