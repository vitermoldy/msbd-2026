-- Diminta: menyusun rekomendasi final (dipertahankan, dihapus, digabung) yang masing-masing disertai satu angka pengukuran.
-- Dipilih: satu query yang mengumpulkan ukuran, idx_scan, dan definisi untuk setiap index event_log, ditambah pemeriksaan pasangan index yang saling menjadi awalan (kandidat gabung).
-- Alternatif: menulis rekomendasi langsung di laporan tanpa query; tidak dipilih karena setiap baris rekomendasi harus bisa ditelusuri ke satu angka.
\timing on
\echo '----- bahan rekomendasi: ukuran, pemakaian, dan definisi'
SELECT s.indexrelname AS index, s.idx_scan,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS ukuran,
       round(100.0*pg_relation_size(s.indexrelid)/pg_relation_size('lab6.event_log'), 2) AS persen_heap,
       pg_get_indexdef(s.indexrelid) AS definisi
FROM pg_stat_user_indexes s
WHERE s.schemaname='lab6' AND s.relname='event_log'
ORDER BY pg_relation_size(s.indexrelid) DESC;

\echo '----- kandidat gabung: index yang kolom kuncinya menjadi awalan kolom kunci index lain'
WITH ix AS (
  SELECT s.indexrelname, s.indexrelid, s.idx_scan, i.indnkeyatts, c.relam,
         string_to_array(i.indkey::text, ' ') AS kunci, i.indpred
  FROM pg_stat_user_indexes s
  JOIN pg_index i ON i.indexrelid = s.indexrelid
  JOIN pg_class c ON c.oid = s.indexrelid
  WHERE s.schemaname='lab6' AND s.relname='event_log'
)
SELECT a.indexrelname AS index_sempit, a.idx_scan AS scan_sempit,
       pg_size_pretty(pg_relation_size(a.indexrelid)) AS ukuran_sempit,
       b.indexrelname AS index_lebar,  b.idx_scan AS scan_lebar,
       pg_size_pretty(pg_relation_size(b.indexrelid)) AS ukuran_lebar,
       pg_get_indexdef(a.indexrelid) AS definisi_sempit,
       pg_get_indexdef(b.indexrelid) AS definisi_lebar
FROM ix a JOIN ix b
  ON a.indexrelid <> b.indexrelid
 AND a.relam = b.relam
 AND a.indnkeyatts <= b.indnkeyatts
 AND a.kunci[1:a.indnkeyatts] = b.kunci[1:a.indnkeyatts]
WHERE a.indpred IS NULL AND b.indpred IS NULL
  AND NOT ('0' = ANY(a.kunci[1:a.indnkeyatts]))   -- lewati index ekspresi
ORDER BY 1, 4;
-- Catatan: arah urutan (ASC/DESC) tidak diperiksa query ini, jadi periksa definisinya sebelum menghapus.

\echo '----- harga tulis dan ruang, sebagai dasar keputusan'
SELECT pg_size_pretty(pg_relation_size('lab6.event_log')) AS heap,
       pg_size_pretty(pg_indexes_size('lab6.event_log'))  AS semua_index,
       round(100.0*pg_indexes_size('lab6.event_log')/pg_relation_size('lab6.event_log'), 1) AS persen_index_atas_heap,
       pg_size_pretty(pg_total_relation_size('lab6.event_log')) AS total;
