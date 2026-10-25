-- Diminta: membandingkan ukuran total tabel pada kedua keadaan Q27.
-- Dipilih: pg_relation_size (heap), pg_indexes_size (semua index), dan pg_total_relation_size (termasuk TOAST) dipisah agar terlihat bagian mana yang membesar.
-- Alternatif: hanya pg_total_relation_size; tidak dipilih karena tidak menunjukkan bahwa heap kedua tabel sama besar.
\timing on
SELECT relname AS tabel,
       pg_size_pretty(pg_relation_size(c.oid))        AS heap,
       pg_size_pretty(pg_indexes_size(c.oid))         AS index,
       pg_size_pretty(pg_total_relation_size(c.oid))  AS total,
       pg_total_relation_size(c.oid)                  AS total_byte
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='lab6' AND relname IN ('tulis_tanpa_index','tulis_lima_index')
ORDER BY relname;

SELECT round(100.0*(pg_total_relation_size('lab6.tulis_lima_index')
                    - pg_total_relation_size('lab6.tulis_tanpa_index'))
             / pg_total_relation_size('lab6.tulis_tanpa_index'), 1) AS persen_lebih_besar;

SELECT indexrelname AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS ukuran
FROM pg_stat_user_indexes WHERE schemaname='lab6' AND relname='tulis_lima_index'
ORDER BY pg_relation_size(indexrelid) DESC;
