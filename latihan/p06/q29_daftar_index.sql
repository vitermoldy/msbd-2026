-- Diminta: mendaftar seluruh index lab6 beserta idx_scan dan ukurannya, lalu menentukan index dengan idx_scan nol.
-- Dipilih: pg_stat_user_indexes digabung dengan pg_relation_size dan definisi index, diurutkan dari yang paling jarang dipakai, agar kandidat hapus langsung terlihat.
-- Alternatif: hanya \di+; tidak dipilih karena tidak menampilkan idx_scan sehingga tidak bisa dipakai mengambil keputusan.
\timing on
SELECT s.relname AS tabel, s.indexrelname AS index, s.idx_scan, s.idx_tup_read, s.idx_tup_fetch,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS ukuran,
       pg_relation_size(s.indexrelid) AS byte
FROM pg_stat_user_indexes s
WHERE s.schemaname = 'lab6'
ORDER BY s.idx_scan, pg_relation_size(s.indexrelid) DESC;

\echo '----- index yang belum pernah dipakai sama sekali'
SELECT s.indexrelname AS index, pg_size_pretty(pg_relation_size(s.indexrelid)) AS ukuran,
       pg_get_indexdef(s.indexrelid) AS definisi,
       i.indisunique AS menjaga_keunikan, i.indisprimary AS primary_key
FROM pg_stat_user_indexes s JOIN pg_index i ON i.indexrelid = s.indexrelid
WHERE s.schemaname='lab6' AND s.idx_scan = 0
ORDER BY pg_relation_size(s.indexrelid) DESC;

\echo '----- total ruang index pada skema lab6'
SELECT pg_size_pretty(sum(pg_relation_size(indexrelid))) AS total_index,
       pg_size_pretty(sum(pg_relation_size(indexrelid)) FILTER (WHERE idx_scan=0)) AS index_tak_terpakai,
       count(*) AS jumlah_index, count(*) FILTER (WHERE idx_scan=0) AS jumlah_tak_terpakai
FROM pg_stat_user_indexes WHERE schemaname='lab6';
