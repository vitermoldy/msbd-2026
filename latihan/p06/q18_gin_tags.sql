-- 1. Uji DENGAN GIN Index 3x
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];

-- 2. Uji TANPA GIN Index
SET enable_indexscan = off;
SET enable_bitmapscan = off;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];

-- 3. Kembalikan Setting Index Scan
SET enable_indexscan = on;
SET enable_bitmapscan = on;