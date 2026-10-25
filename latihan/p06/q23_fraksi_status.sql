-- Q23: Hitung fraksi tiap status, lalu cari pada fraksi berapa optimizer
-- berpindah dari Index Scan ke Seq Scan.
\timing on
SET max_parallel_workers_per_gather = 0;

-- 1. Fraksi tiap status
SELECT
    status,
    COUNT(*) AS jumlah,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS persentase
FROM lab6.event_log
GROUP BY status
ORDER BY jumlah;

-- 2. Tiga status hanya memberi tiga titik (2%, 14%, 84%), terlalu jarang untuk
--    menemukan titik peralihan. Rentang waktu dipakai sebagai keran selektivitas:
--    kolom customer_id dipakai sebagai keran selektivitas: ia sudah terindeks
--    (ev_benar_idx dari Q9) dan sebarannya acak terhadap urutan fisik, sehingga
--    pergantian rencana benar-benar bergantung pada fraksi baris, bukan korelasi.
--    Agregatnya memakai kolom kota yang tidak ada di index mana pun, supaya heap
--    tetap harus dibaca dan index-only scan tidak menyamarkan titik peralihan.
\echo '===== Q23 sapuan fraksi dengan random_page_cost bawaan'
SELECT current_setting('random_page_cost') AS random_page_cost,
       current_setting('seq_page_cost') AS seq_page_cost;

DO $$
DECLARE
  k int; j json; node text; est bigint; nyata bigint; batas int;
BEGIN
  FOREACH k IN ARRAY ARRAY[1,2,5,10,20,30,32,34,36,38,40,50,70] LOOP
    batas := 60000 * k / 100;
    EXECUTE format('EXPLAIN (FORMAT JSON) SELECT sum(length(kota)) FROM lab6.event_log WHERE customer_id <= %s', batas) INTO j;
    node := j->0->'Plan'->'Plans'->0->>'Node Type';
    est  := (j->0->'Plan'->'Plans'->0->>'Plan Rows')::bigint;
    EXECUTE format('SELECT count(*) FROM lab6.event_log WHERE customer_id <= %s', batas) INTO nyata;
    RAISE NOTICE 'customer_id <= % -> node=% | estimasi=% | nyata=% (% persen)',
      lpad(batas::text,5), rpad(node,18), est, nyata, round(100.0*nyata/2000000, 1);
  END LOOP;
END $$;

-- 3. Pengukuran di dua sisi titik peralihan
\echo '===== Q23 pengukuran di bawah titik peralihan · run 1'
EXPLAIN (ANALYZE, BUFFERS) SELECT sum(length(kota)) FROM lab6.event_log WHERE customer_id <= 18000;
\echo '===== Q23 pengukuran di bawah titik peralihan · run 2'
EXPLAIN (ANALYZE, BUFFERS) SELECT sum(length(kota)) FROM lab6.event_log WHERE customer_id <= 18000;
\echo '===== Q23 pengukuran di atas titik peralihan · run 1'
EXPLAIN (ANALYZE, BUFFERS) SELECT sum(length(kota)) FROM lab6.event_log WHERE customer_id <= 30000;
\echo '===== Q23 pengukuran di atas titik peralihan · run 2'
EXPLAIN (ANALYZE, BUFFERS) SELECT sum(length(kota)) FROM lab6.event_log WHERE customer_id <= 30000;
