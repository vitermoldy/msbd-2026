-- Q25: Buat extended statistics dependencies dan ndistinct pada wilayah-kota,
-- lalu bandingkan estimasi baris dengan kenyataan sebelum dan sesudah ANALYZE.
\timing on
SET max_parallel_workers_per_gather = 0;
DROP STATISTICS IF EXISTS lab6.stat_wilayah_kota;

-- Nilai kota pada data ini berbentuk '<WILAYAH>-<angka 1..9>', misalnya 'SUMUT-3'.
-- Karena itu kota menentukan wilayah secara penuh, dan asumsi kemandirian
-- yang dipakai optimizer pasti meleset.
SELECT count(DISTINCT wilayah) AS wilayah_distinct,
       count(DISTINCT kota) AS kota_distinct,
       count(*) FILTER (WHERE wilayah = 'SUMUT' AND kota = 'SUMUT-3') AS baris_nyata,
       round(2000000.0/(count(DISTINCT wilayah)*count(DISTINCT kota)), 0) AS estimasi_kalau_mandiri
FROM lab6.event_log;

SELECT DISTINCT kota FROM lab6.event_log WHERE wilayah = 'SUMUT' ORDER BY kota LIMIT 9;

-- 1. Cek estimasi baris SEBELUM extended statistics
\echo '===== Q25a sebelum extended statistics · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE wilayah = 'SUMUT' AND kota = 'SUMUT-3';
\echo '===== Q25a sebelum extended statistics · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE wilayah = 'SUMUT' AND kota = 'SUMUT-3';

-- 2. Buat extended statistics untuk korelasi kolom wilayah dan kota
CREATE STATISTICS IF NOT EXISTS lab6.stat_wilayah_kota (dependencies, ndistinct)
ON wilayah, kota FROM lab6.event_log;

\echo '----- statistik sudah dibuat tetapi ANALYZE belum dijalankan'
EXPLAIN SELECT * FROM lab6.event_log WHERE wilayah = 'SUMUT' AND kota = 'SUMUT-3';

-- 3. Perbarui statistik tabel
ANALYZE lab6.event_log;

-- 4. Cek estimasi baris SESUDAH extended statistics
\echo '===== Q25b sesudah ANALYZE · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE wilayah = 'SUMUT' AND kota = 'SUMUT-3';
\echo '===== Q25b sesudah ANALYZE · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE wilayah = 'SUMUT' AND kota = 'SUMUT-3';

SELECT stxdndistinct AS ndistinct, stxddependencies AS dependencies
FROM pg_statistic_ext s JOIN pg_statistic_ext_data d ON d.stxoid = s.oid
WHERE s.stxname = 'stat_wilayah_kota';
