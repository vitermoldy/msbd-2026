-- Q24: Setel random_page_cost = 1.1, ulangi sapuan Q23, jelaskan pergeseran
-- titik peralihan, lalu jalankan RESET.
\timing on
SET max_parallel_workers_per_gather = 0;
SHOW random_page_cost;

\echo '===== Q24a sapuan dengan random_page_cost = 4 (bawaan)'
DO $$
DECLARE
  k int; j json; node text; biaya numeric; batas int;
BEGIN
  FOREACH k IN ARRAY ARRAY[20,30,34,36,38,40,50,60,70,80] LOOP
    batas := 60000 * k / 100;
    EXECUTE format('EXPLAIN (FORMAT JSON) SELECT sum(length(kota)) FROM lab6.event_log WHERE customer_id <= %s', batas) INTO j;
    node := j->0->'Plan'->'Plans'->0->>'Node Type';
    biaya := (j->0->'Plan'->>'Total Cost')::numeric;
    RAISE NOTICE 'customer_id <= % (sekitar % persen) -> node=% | total_cost=%',
      lpad(batas::text,5), lpad(k::text,2), rpad(node,18), biaya;
  END LOOP;
END $$;

SET random_page_cost = 1.1;
SHOW random_page_cost;

\echo '===== Q24b sapuan dengan random_page_cost = 1.1'
DO $$
DECLARE
  k int; j json; node text; biaya numeric; batas int;
BEGIN
  FOREACH k IN ARRAY ARRAY[20,30,34,36,38,40,50,60,70,80] LOOP
    batas := 60000 * k / 100;
    EXECUTE format('EXPLAIN (FORMAT JSON) SELECT sum(length(kota)) FROM lab6.event_log WHERE customer_id <= %s', batas) INTO j;
    node := j->0->'Plan'->'Plans'->0->>'Node Type';
    biaya := (j->0->'Plan'->>'Total Cost')::numeric;
    RAISE NOTICE 'customer_id <= % (sekitar % persen) -> node=% | total_cost=%',
      lpad(batas::text,5), lpad(k::text,2), rpad(node,18), biaya;
  END LOOP;
END $$;

-- Pengaruhnya pada query status SUKSES, tiga kali
\echo '===== Q24c status SUKSES dengan random_page_cost 1.1 · run 1'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'SUKSES';
\echo '===== Q24c status SUKSES dengan random_page_cost 1.1 · run 2'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'SUKSES';
\echo '===== Q24c status SUKSES dengan random_page_cost 1.1 · run 3'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM lab6.event_log WHERE status = 'SUKSES';

-- Kembalikan ke konfigurasi default
RESET random_page_cost;
SHOW random_page_cost;
