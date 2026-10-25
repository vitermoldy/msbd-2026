-- Q12: Bandingkan ukuran ev_gagal_idx (partial, hanya baris status='GAGAL')
-- dengan index penuh pada kolom yang sama (terjadi_pada), lalu hitung
-- persentase penghematan ruang.
\timing on
SET max_parallel_workers_per_gather = 0;

-- Index penuh, sebagai pembanding "tanpa partial"
CREATE INDEX IF NOT EXISTS ev_terjadi_pada_idx
    ON lab6.event_log (terjadi_pada DESC);

-- Index parsial dari soal
CREATE INDEX IF NOT EXISTS ev_gagal_idx
    ON lab6.event_log (terjadi_pada DESC)
    WHERE status = 'GAGAL';
ANALYZE lab6.event_log;

SELECT
    'ev_terjadi_pada_idx (penuh)' AS nama_index,
    pg_size_pretty(pg_relation_size('lab6.ev_terjadi_pada_idx')) AS ukuran,
    pg_relation_size('lab6.ev_terjadi_pada_idx') AS ukuran_byte
UNION ALL
SELECT
    'ev_gagal_idx (partial)',
    pg_size_pretty(pg_relation_size('lab6.ev_gagal_idx')),
    pg_relation_size('lab6.ev_gagal_idx');

SELECT
    round(
        100.0 * (1 - pg_relation_size('lab6.ev_gagal_idx')::numeric
                     / pg_relation_size('lab6.ev_terjadi_pada_idx')),
        2
    ) AS persen_penghematan,
    (SELECT round(100.0*count(*) FILTER (WHERE status='GAGAL')/count(*), 2) FROM lab6.event_log)
      AS persen_baris_gagal;

-- Bukti bahwa partial index itu memang dipakai, dijalankan tiga kali
\echo '===== Q12 query memakai partial index · run 1'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, terjadi_pada FROM lab6.event_log
WHERE status = 'GAGAL' ORDER BY terjadi_pada DESC LIMIT 20;
\echo '===== Q12 query memakai partial index · run 2'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, terjadi_pada FROM lab6.event_log
WHERE status = 'GAGAL' ORDER BY terjadi_pada DESC LIMIT 20;
\echo '===== Q12 query memakai partial index · run 3'
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, terjadi_pada FROM lab6.event_log
WHERE status = 'GAGAL' ORDER BY terjadi_pada DESC LIMIT 20;
