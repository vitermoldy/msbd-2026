-- 1. Buat B-Tree pembanding di kolom yang sama (terjadi_pada)
CREATE INDEX IF NOT EXISTS idx_btree_terjadi ON lab6.event_log (terjadi_pada);

-- 2. Periksa nilai correlation kolom terjadi_pada di pg_stats
SELECT tablename, attname, correlation 
FROM pg_stats 
WHERE tablename = 'event_log' AND attname = 'terjadi_pada';

-- 3. Bandingkan ukuran indeks BRIN vs B-Tree
SELECT 
    pg_size_pretty(pg_relation_size('lab6.idx_brin_terjadi')) AS ukuran_brin,
    pg_size_pretty(pg_relation_size('lab6.idx_btree_terjadi')) AS ukuran_btree;