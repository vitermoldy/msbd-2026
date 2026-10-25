-- Q10: Bandingkan ukuran ev_salah_idx dan ev_benar_idx, lalu jelaskan dengan percobaan
-- terkendali mengapa kolom yang sama dapat menghasilkan ukuran berbeda.
\timing on
CREATE EXTENSION IF NOT EXISTS pgstattuple;

CREATE INDEX IF NOT EXISTS ev_salah_idx
ON lab6.event_log (terjadi_pada, customer_id);

-- 1 · Ukuran kedua index yang diminta soal
SELECT indexrelname AS index,
       pg_size_pretty(pg_relation_size(indexrelid)) AS ukuran,
       pg_relation_size(indexrelid) AS byte,
       pg_relation_size(indexrelid)/8192 AS halaman
FROM pg_stat_user_indexes
WHERE schemaname = 'lab6' AND indexrelname IN ('ev_salah_idx','ev_benar_idx')
ORDER BY indexrelname;

SELECT c.relname AS index, s.leaf_pages, s.internal_pages, s.avg_leaf_density
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN LATERAL pgstatindex(c.oid) s
WHERE n.nspname = 'lab6' AND c.relname IN ('ev_salah_idx','ev_benar_idx')
ORDER BY c.relname;

-- 2 · Penyebab pertama: fillfactor (kolom sama, hanya padatnya berbeda)
CREATE INDEX ev_ff50_idx ON lab6.event_log (customer_id, terjadi_pada DESC) WITH (fillfactor=50);
SELECT 'fillfactor 90 (bawaan)' AS varian, pg_size_pretty(pg_relation_size('lab6.ev_benar_idx')) AS ukuran
UNION ALL
SELECT 'fillfactor 50', pg_size_pretty(pg_relation_size('lab6.ev_ff50_idx'));
DROP INDEX lab6.ev_ff50_idx;

-- 3 · Penyebab kedua: deduplikasi daun hanya bekerja bila kunci berulang
CREATE INDEX ev_status_dedup_idx ON lab6.event_log (status);
CREATE INDEX ev_status_id_idx    ON lab6.event_log (status, event_id);
SELECT 'status (3 nilai berulang, deduplikasi aktif)' AS varian,
       pg_size_pretty(pg_relation_size('lab6.ev_status_dedup_idx')) AS ukuran
UNION ALL
SELECT 'status + event_id (setiap kunci unik, tidak bisa dideduplikasi)',
       pg_size_pretty(pg_relation_size('lab6.ev_status_id_idx'));
DROP INDEX lab6.ev_status_dedup_idx;
DROP INDEX lab6.ev_status_id_idx;

-- 4 · Penyebab ketiga: index diisi bertahap lawan dibangun sekaligus
DROP TABLE IF EXISTS lab6.urut_acak, lab6.urut_sekali;
CREATE TABLE lab6.urut_acak (customer_id integer, terjadi_pada timestamptz);
CREATE INDEX urut_acak_idx ON lab6.urut_acak (customer_id, terjadi_pada DESC);
INSERT INTO lab6.urut_acak SELECT customer_id, terjadi_pada FROM lab6.event_log
WHERE event_id <= 500000 ORDER BY random();
CREATE TABLE lab6.urut_sekali AS SELECT customer_id, terjadi_pada FROM lab6.event_log
WHERE event_id <= 500000;
CREATE INDEX urut_sekali_idx ON lab6.urut_sekali (customer_id, terjadi_pada DESC);
SELECT 'diisi bertahap lewat INSERT' AS varian,
       pg_size_pretty(pg_relation_size('lab6.urut_acak_idx')) AS ukuran,
       (SELECT round(avg_leaf_density::numeric,1) FROM pgstatindex('lab6.urut_acak_idx')) AS kerapatan_daun
UNION ALL
SELECT 'dibangun sekaligus oleh CREATE INDEX',
       pg_size_pretty(pg_relation_size('lab6.urut_sekali_idx')),
       (SELECT round(avg_leaf_density::numeric,1) FROM pgstatindex('lab6.urut_sekali_idx'));
DROP TABLE lab6.urut_acak, lab6.urut_sekali;
