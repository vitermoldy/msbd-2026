-- Diminta: mencatat ukuran total tabel, menghitung rata-rata byte per baris, dan membandingkannya dengan perkiraan dari definisi kolom.
-- Dipilih: pg_relation_size dipisah dari pg_total_relation_size, dan perkiraan dihitung dari avg(pg_column_size(kolom)) agar angkanya berbasis data nyata.
-- Alternatif: menghitung perkiraan dari lebar tipe di dokumentasi saja; tidak dipilih karena text/jsonb/array panjangnya bergantung isi.
\timing on
SELECT pg_size_pretty(pg_relation_size('lab6.event_log'))             AS heap,
       pg_size_pretty(pg_indexes_size('lab6.event_log'))              AS semua_index,
       pg_size_pretty(pg_total_relation_size('lab6.event_log'))       AS total,
       pg_relation_size('lab6.event_log')/2000000.0                   AS byte_per_baris_heap;

-- Perkiraan dari definisi kolom: header tuple 23 byte + line pointer 4 byte + isi kolom
SELECT round(avg(pg_column_size(event_id)),1)        AS event_id,
       round(avg(pg_column_size(customer_id)),1)     AS customer_id,
       round(avg(pg_column_size(terjadi_pada)),1)    AS terjadi_pada,
       round(avg(pg_column_size(status)),1)          AS status,
       round(avg(pg_column_size(wilayah)),1)         AS wilayah,
       round(avg(pg_column_size(kota)),1)            AS kota,
       round(avg(pg_column_size(email)),1)           AS email,
       round(avg(pg_column_size(idempotency_key)),1) AS idempotency_key,
       round(avg(pg_column_size(jumlah)),1)          AS jumlah,
       round(avg(pg_column_size(tags)),1)            AS tags,
       round(avg(pg_column_size(payload)),1)         AS payload
FROM lab6.event_log;

SELECT round(avg(pg_column_size(e.*)),1) AS avg_tuple_tanpa_header,
       round(avg(pg_column_size(e.*)) + 23 + 4, 1) AS perkiraan_dengan_header_dan_pointer
FROM lab6.event_log e;

SELECT relpages, reltuples::bigint, round((reltuples/relpages)::numeric,1) AS tuple_per_halaman_katalog
FROM pg_class WHERE oid = 'lab6.event_log'::regclass;
