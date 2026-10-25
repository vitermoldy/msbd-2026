-- Q14: Uji query yang seharusnya bisa dijawab index-only scan (semua kolom
-- yang diminta ada di ev_cover_idx: customer_id sebagai key, terjadi_pada
-- dan jumlah lewat INCLUDE). Jalankan sebelum dan sesudah VACUUM (ANALYZE)
-- untuk melihat perubahan Heap Fetches.
\timing on
SET max_parallel_workers_per_gather = 0;

CREATE INDEX IF NOT EXISTS ev_cover_idx
    ON lab6.event_log (customer_id)
    INCLUDE (terjadi_pada, jumlah);
ANALYZE lab6.event_log;

SELECT pg_size_pretty(pg_relation_size('lab6.ev_cover_idx')) AS ukuran_ev_cover_idx;

-- Keadaan visibility map sebelum percobaan
SELECT 'sebelum UPDATE' AS tahap, relallvisible, relpages,
       round(100.0*relallvisible/nullif(relpages,0), 2) AS persen_all_visible
FROM pg_class WHERE oid = 'lab6.event_log'::regclass;

-- Baris milik customer uji diperbarui supaya halamannya berhenti all-visible.
-- Tanpa langkah ini, autovacuum sudah menandai halaman all-visible dan
-- Heap Fetches langsung nol, sehingga percobaan kehilangan maknanya.
UPDATE lab6.event_log SET kota = kota WHERE customer_id = 4211;

SELECT 'sesudah UPDATE' AS tahap, relallvisible, relpages,
       round(100.0*relallvisible/nullif(relpages,0), 2) AS persen_all_visible
FROM pg_class WHERE oid = 'lab6.event_log'::regclass;

-- ===========================================================
-- PENGUKURAN 1: SEBELUM VACUUM, rencana apa adanya
-- ===========================================================
\echo '===== Q14a sebelum VACUUM, rencana apa adanya · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log WHERE customer_id = 4211;
\echo '===== Q14a sebelum VACUUM, rencana apa adanya · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log WHERE customer_id = 4211;
\echo '===== Q14a sebelum VACUUM, rencana apa adanya · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log WHERE customer_id = 4211;

-- ===========================================================
-- PENGUKURAN 2: SEBELUM VACUUM, index-only scan dipaksa.
-- Sebelum VACUUM optimizer justru menghindari index-only scan karena
-- biayanya membengkak, jadi Heap Fetches hanya terlihat bila dipaksa.
-- ===========================================================
BEGIN;
SET LOCAL enable_bitmapscan = off;
SET LOCAL enable_seqscan = off;
\echo '===== Q14b sebelum VACUUM, index-only dipaksa · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log WHERE customer_id = 4211;
\echo '===== Q14b sebelum VACUUM, index-only dipaksa · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log WHERE customer_id = 4211;
\echo '===== Q14b sebelum VACUUM, index-only dipaksa · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log WHERE customer_id = 4211;
ROLLBACK;

-- ===========================================================
-- VACUUM manual -- ini yang mengisi dan memperbarui visibility map
-- ===========================================================
VACUUM (ANALYZE) lab6.event_log;

SELECT 'sesudah VACUUM' AS tahap, relallvisible, relpages,
       round(100.0*relallvisible/nullif(relpages,0), 2) AS persen_all_visible
FROM pg_class WHERE oid = 'lab6.event_log'::regclass;

-- ===========================================================
-- PENGUKURAN 3: SESUDAH VACUUM, query identik, definisi index tidak berubah
-- ===========================================================
\echo '===== Q14c sesudah VACUUM · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log WHERE customer_id = 4211;
\echo '===== Q14c sesudah VACUUM · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log WHERE customer_id = 4211;
\echo '===== Q14c sesudah VACUUM · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah FROM lab6.event_log WHERE customer_id = 4211;
