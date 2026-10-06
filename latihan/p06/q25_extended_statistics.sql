-- 1. Cek estimasi baris SEBELUM extended statistics
EXPLAIN ANALYZE
SELECT * FROM lab6.event_log WHERE wilayah = 'SUMUT' AND kota = 'MEDAN';

-- 2. Buat extended statistics untuk korelasi kolom wilayah dan kota
CREATE STATISTICS IF NOT EXISTS stat_wilayah_kota (dependencies, ndistinct)
ON wilayah, kota FROM lab6.event_log;

-- 3. Perbarui statistik tabel
ANALYZE lab6.event_log;

-- 4. Cek estimasi baris SESUDAH extended statistics
EXPLAIN ANALYZE
SELECT * FROM lab6.event_log WHERE wilayah = 'SUMUT' AND kota = 'MEDAN';