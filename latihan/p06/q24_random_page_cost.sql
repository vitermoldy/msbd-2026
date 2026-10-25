-- 1. Ubah parameter random_page_cost
SET random_page_cost = 1.1;

-- 2. Uji ulang query status SUKSES
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log WHERE status = 'SUKSES';

-- 3. Kembalikan ke konfigurasi default
RESET random_page_cost;