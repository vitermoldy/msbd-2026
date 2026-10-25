-- Q4: Bandingkan n_tup_hot_upd pada fillfactor 100 lawan 80.
-- Q5: Bandingkan ukuran kedua tabel sebelum dan sesudah UPDATE.
-- Q6: Bandingkan UPDATE kolom terindeks dan kolom tidak terindeks.
\timing on
SET max_parallel_workers_per_gather = 0;

DROP TABLE IF EXISTS lab6.hot_penuh;
CREATE TABLE lab6.hot_penuh (
    id INT PRIMARY KEY,
    nama TEXT,
    catatan TEXT
) WITH (fillfactor = 100);

DROP TABLE IF EXISTS lab6.hot_longgar;
CREATE TABLE lab6.hot_longgar (
    id INT PRIMARY KEY,
    nama TEXT,
    catatan TEXT
) WITH (fillfactor = 80);

INSERT INTO lab6.hot_penuh SELECT g, 'User ' || g, 'Awal' FROM generate_series(1, 10000) g;
INSERT INTO lab6.hot_longgar SELECT g, 'User ' || g, 'Awal' FROM generate_series(1, 10000) g;

-- Index tambahan pada kolom nama, dipakai Q6 untuk menguji UPDATE kolom terindeks
CREATE INDEX hot_longgar_nama_idx ON lab6.hot_longgar (nama);

VACUUM ANALYZE lab6.hot_penuh;
VACUUM ANALYZE lab6.hot_longgar;

-- ================= Q5 · ukuran sebelum UPDATE =================
SELECT 'sebelum UPDATE' AS tahap,
       pg_size_pretty(pg_relation_size('lab6.hot_penuh'))   AS hot_penuh,
       pg_size_pretty(pg_relation_size('lab6.hot_longgar')) AS hot_longgar;

-- ================= Q4 · UPDATE kolom catatan (TIDAK terindeks) =================
UPDATE lab6.hot_penuh SET catatan = 'Revisi';
UPDATE lab6.hot_longgar SET catatan = 'Revisi';
SELECT pg_stat_force_next_flush();

SELECT
    relname AS nama_tabel,
    n_tup_upd AS total_update,
    n_tup_hot_upd AS total_hot_update,
    ROUND((n_tup_hot_upd::numeric / NULLIF(n_tup_upd, 0)) * 100, 2) AS persentase_hot_pct
FROM pg_stat_user_tables
WHERE relname IN ('hot_penuh', 'hot_longgar')
ORDER BY relname;

-- ================= Q5 · ukuran sesudah UPDATE =================
SELECT 'sesudah UPDATE' AS tahap,
       pg_size_pretty(pg_relation_size('lab6.hot_penuh'))   AS hot_penuh,
       pg_size_pretty(pg_relation_size('lab6.hot_longgar')) AS hot_longgar,
       pg_size_pretty(pg_total_relation_size('lab6.hot_penuh'))   AS total_penuh,
       pg_size_pretty(pg_total_relation_size('lab6.hot_longgar')) AS total_longgar;

-- ================= Q6 · kolom terindeks lawan tidak terindeks =================
-- Keadaan awal pencacah untuk tabel hot_longgar
SELECT n_tup_upd AS upd_sebelum_q6, n_tup_hot_upd AS hot_sebelum_q6
FROM pg_stat_user_tables WHERE relname = 'hot_longgar';

-- (a) UPDATE kolom nama yang TERINDEKS oleh hot_longgar_nama_idx
UPDATE lab6.hot_longgar SET nama = nama || '!' WHERE id <= 5000;
SELECT pg_stat_force_next_flush();
SELECT 'sesudah UPDATE kolom terindeks (nama)' AS tahap,
       n_tup_upd, n_tup_hot_upd
FROM pg_stat_user_tables WHERE relname = 'hot_longgar';

-- (b) UPDATE kolom catatan yang TIDAK terindeks, jumlah baris sama persis
UPDATE lab6.hot_longgar SET catatan = 'Revisi 2' WHERE id <= 5000;
SELECT pg_stat_force_next_flush();
SELECT 'sesudah UPDATE kolom tidak terindeks (catatan)' AS tahap,
       n_tup_upd, n_tup_hot_upd
FROM pg_stat_user_tables WHERE relname = 'hot_longgar';
