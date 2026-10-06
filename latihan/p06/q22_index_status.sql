-- 1. Buat Indeks pada Kolom Status
CREATE INDEX IF NOT EXISTS idx_status ON lab6.event_log (status);

-- 2. Uji Status SUKSES
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE status = 'SUKSES';

-- 3. Uji Status GAGAL
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE status = 'GAGAL';