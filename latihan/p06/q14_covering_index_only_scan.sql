-- Q14: Uji query yang seharusnya bisa dijawab index-only scan (semua kolom
-- yang diminta ada di ev_cover_idx: customer_id sebagai key, terjadi_pada
-- dan jumlah lewat INCLUDE). Jalankan sebelum dan sesudah VACUUM (ANALYZE)
-- untuk melihat perubahan Heap Fetches.

SET max_parallel_workers_per_gather = 0;
\timing on

CREATE INDEX IF NOT EXISTS ev_cover_idx
    ON lab6.event_log (customer_id)
    INCLUDE (terjadi_pada, jumlah);

-- ===========================================================
-- PENGUKURAN 1: SEBELUM VACUUM manual
-- Tabel baru selesai dimuat lewat INSERT besar + ANALYZE (dari q00_setup),
-- tapi VACUUM belum pernah dijalankan -- visibility map kemungkinan besar
-- belum lengkap, sehingga Heap Fetches diperkirakan TINGGI.
-- Jalankan TIGA KALI, catat waktu tercepat & median, DAN salin baris
-- "Heap Fetches: ..." dari keluarannya.
-- ===========================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah
FROM lab6.event_log
WHERE customer_id = 4211;

-- ===========================================================
-- VACUUM manual -- ini yang mengisi/memperbarui visibility map
-- ===========================================================
VACUUM (ANALYZE) lab6.event_log;

-- ===========================================================
-- PENGUKURAN 2: SESUDAH VACUUM
-- Query IDENTIK dengan di atas. Definisi index tidak berubah sama sekali.
-- Jalankan TIGA KALI juga, catat waktu dan Heap Fetches yang baru.
-- ===========================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT terjadi_pada, jumlah
FROM lab6.event_log
WHERE customer_id = 4211;
