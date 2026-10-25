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

VACUUM ANALYZE lab6.hot_penuh;
VACUUM ANALYZE lab6.hot_longgar;

UPDATE lab6.hot_penuh SET catatan = 'Revisi';
UPDATE lab6.hot_longgar SET catatan = 'Revisi';

SELECT
    relname AS nama_tabel,
    n_tup_upd AS total_update,
    n_tup_hot_upd AS total_hot_update,
    ROUND((n_tup_hot_upd::numeric / NULLIF(n_tup_upd, 0)) * 100, 2) AS persentase_hot_pct
FROM pg_stat_user_tables
WHERE relname IN ('hot_penuh', 'hot_longgar');
