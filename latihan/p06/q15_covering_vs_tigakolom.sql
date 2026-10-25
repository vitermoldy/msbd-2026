-- Q15: Ganti ev_cover_idx (INCLUDE) dengan index tiga kolom biasa yang
-- memuat kolom yang sama, bandingkan ukuran dan rencana eksekusinya.
--
-- PENTING: catat dulu ukuran ev_cover_idx SEBELUM di-drop (butuh untuk
-- perbandingan di laporan):
-- SELECT pg_size_pretty(pg_relation_size('lab6.ev_cover_idx'));

SET max_parallel_workers_per_gather = 0;
\timing on

DROP INDEX IF EXISTS lab6.ev_cover_idx;

CREATE INDEX ev_cover3_idx
    ON lab6.event_log (customer_id, terjadi_pada, jumlah);

SELECT
    'ev_cover3_idx (3 kolom biasa)' AS nama_index,
    pg_size_pretty(pg_relation_size('lab6.ev_cover3_idx')) AS ukuran,
    pg_relation_size('lab6.ev_cover3_idx') AS ukuran_byte;

-- Query SAMA PERSIS dengan Q14, supaya rencana eksekusinya bisa
-- dibandingkan apel-ke-apel. Jalankan tiga kali seperti biasa.
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah
FROM lab6.event_log
WHERE customer_id = 4211;
