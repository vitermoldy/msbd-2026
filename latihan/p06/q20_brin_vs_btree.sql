DROP INDEX IF EXISTS lab6.idx_btree_terjadi;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log 
WHERE terjadi_pada >= '2024-05-01 00:00+07' 
  AND terjadi_pada < '2024-05-08 00:00+07';

-- Menguji Performa B-Tree (Buat B-Tree kembali)

CREATE INDEX idx_btree_terjadi ON lab6.event_log (terjadi_pada);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log 
WHERE terjadi_pada >= '2024-05-01 00:00+07' 
  AND terjadi_pada < '2024-05-08 00:00+07';