-- 1. Buat Indeks GIN pada kolom payload
CREATE INDEX IF NOT EXISTS idx_gin_payload ON lab6.event_log USING gin (payload jsonb_path_ops);

-- 2. Uji Query JSONB dengan GIN 3x
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE payload @> '{"promo": true}';

-- 3. Cek Ukuran Indeks GIN vs Heap
SELECT 
    pg_size_pretty(pg_relation_size('idx_gin_payload')) AS ukuran_gin_payload,
    pg_size_pretty(pg_relation_size('lab6.event_log')) AS ukuran_heap;