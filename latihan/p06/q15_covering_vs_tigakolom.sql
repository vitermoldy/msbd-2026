-- Q15: Ganti ev_cover_idx (INCLUDE) dengan index tiga kolom biasa yang
-- memuat kolom yang sama, bandingkan ukuran dan rencana eksekusinya.
\timing on
SET max_parallel_workers_per_gather = 0;

-- Ukuran index INCLUDE dicatat lebih dulu, sebelum ia dihapus
SELECT 'ev_cover_idx (customer_id) INCLUDE (terjadi_pada, jumlah)' AS nama_index,
       pg_size_pretty(pg_relation_size('lab6.ev_cover_idx')) AS ukuran,
       pg_relation_size('lab6.ev_cover_idx') AS ukuran_byte;

-- Pembeda sebenarnya baru terlihat pada query yang mengurutkan atau
-- menyaring kolom kedua. Dengan INCLUDE, kolom itu tidak bisa dipakai
-- sebagai Index Cond maupun sebagai urutan.
\echo '===== Q15a INCLUDE, ORDER BY kolom kedua · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211 ORDER BY terjadi_pada LIMIT 5;
\echo '===== Q15a INCLUDE, ORDER BY kolom kedua · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211 ORDER BY terjadi_pada LIMIT 5;
\echo '===== Q15a INCLUDE, ORDER BY kolom kedua · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211 ORDER BY terjadi_pada LIMIT 5;

\echo '===== Q15b INCLUDE, predikat pada kolom kedua · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211 AND terjadi_pada >= timestamptz '2024-06-01 00:00+07';

-- Sekarang diganti dengan index tiga kolom biasa
DROP INDEX IF EXISTS lab6.ev_cover_idx;
CREATE INDEX IF NOT EXISTS ev_cover3_idx
    ON lab6.event_log (customer_id, terjadi_pada, jumlah);
ANALYZE lab6.event_log;

SELECT 'ev_cover3_idx (3 kolom biasa)' AS nama_index,
       pg_size_pretty(pg_relation_size('lab6.ev_cover3_idx')) AS ukuran,
       pg_relation_size('lab6.ev_cover3_idx') AS ukuran_byte;

\echo '===== Q15c tiga kolom, ORDER BY kolom kedua · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211 ORDER BY terjadi_pada LIMIT 5;
\echo '===== Q15c tiga kolom, ORDER BY kolom kedua · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211 ORDER BY terjadi_pada LIMIT 5;
\echo '===== Q15c tiga kolom, ORDER BY kolom kedua · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211 ORDER BY terjadi_pada LIMIT 5;

\echo '===== Q15d tiga kolom, predikat pada kolom kedua · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211 AND terjadi_pada >= timestamptz '2024-06-01 00:00+07';
