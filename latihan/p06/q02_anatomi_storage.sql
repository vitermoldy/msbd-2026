-- Q2: Hitung tuple per halaman lewat ctid dan bandingkan dengan batas teoretis 291.
-- Q3: Periksa attstorage pada pg_attribute, kolom mana yang bernilai x atau e.
\timing on
SET max_parallel_workers_per_gather = 0;

-- ================= Q2 · tuple per halaman =================
SELECT
    (ctid::text::point)[0] AS page_number,
    COUNT(*) AS tuple_count
FROM lab6.event_log
GROUP BY 1
ORDER BY 1
LIMIT 10;

SELECT min(tuple_count) AS minimum,
       round(avg(tuple_count), 2) AS rata_rata,
       max(tuple_count) AS maksimum,
       count(*) AS jumlah_halaman
FROM (
  SELECT (ctid::text::point)[0]::bigint AS halaman, count(*) AS tuple_count
  FROM lab6.event_log GROUP BY 1
) p;

-- Batas teoretis: (8192 - 24 header halaman) / (4 line pointer + 24 header tuple) = 291
SELECT 8192 AS ukuran_halaman,
       24 AS page_header,
       4 AS line_pointer,
       (8192 - 24) / (4 + 24) AS batas_teoretis_tuple,
       round((pg_relation_size('lab6.event_log') / 2000000.0)::numeric, 1) AS byte_per_baris_nyata,
       round((8160 / (pg_relation_size('lab6.event_log') / 2000000.0))::numeric, 1) AS perkiraan_tuple_per_halaman;

-- ================= Q3 · TOAST dan attstorage =================
SELECT a.attname, format_type(a.atttypid, a.atttypmod) AS tipe, a.attstorage,
       CASE a.attstorage WHEN 'p' THEN 'plain: tidak bisa dikompresi atau di-TOAST'
                         WHEN 'm' THEN 'main: boleh dikompresi, TOAST pilihan terakhir'
                         WHEN 'x' THEN 'extended: boleh dikompresi dan dipindah ke TOAST'
                         WHEN 'e' THEN 'external: langsung ke TOAST tanpa kompresi' END AS arti
FROM pg_attribute a
WHERE a.attrelid = 'lab6.event_log'::regclass AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;

SELECT c.reltoastrelid::regclass AS tabel_toast,
       pg_size_pretty(pg_relation_size(c.reltoastrelid)) AS ukuran_toast
FROM pg_class c WHERE c.oid = 'lab6.event_log'::regclass;

SELECT max(pg_column_size(payload)) AS payload_terbesar,
       max(pg_column_size(tags))    AS tags_terbesar,
       max(pg_column_size(email))   AS email_terbesar,
       2000 AS ambang_toast_kira_kira
FROM lab6.event_log;
