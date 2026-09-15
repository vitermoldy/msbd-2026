-- Diminta: membuktikan refresh concurrent tidak memblokir pembaca, lalu mengulang dengan refresh
--          biasa dan mencatat perbedaan perilakunya.
-- Dipilih: dua sesi psql terpisah, sesi 2 memakai SELECT count(*) berulang disertai \timing
--          dan pemeriksaan pg_stat_activity, agar "terblokir" dibuktikan sebagai fakta kunci,
--          bukan kesan.
-- Alternatif: satu sesi dengan pg_sleep di dalam transaksi; tidak dipilih karena satu sesi tidak
--          pernah memblokir dirinya sendiri, sehingga tidak membuktikan apa pun tentang penguncian.

-- ==== SESI 1 (penulis) ====
\timing on
SET search_path = lab4, public;

INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1, now(), 'web'
FROM generate_series(1, 200000);

REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

-- ==== SESI 2 (pembaca): jalankan SEGERA setelah refresh di sesi 1 dimulai ====
\timing on
SELECT count(*) FROM lab4.ringkasan_akses;
SELECT sum(jumlah_akses) FROM lab4.ringkasan_akses;

SELECT pid, wait_event_type, wait_event, state, left(query, 60) AS query
FROM pg_stat_activity
WHERE datname = current_database() AND state <> 'idle';

-- ==== ULANGI DENGAN REFRESH BIASA ====
-- SESI 1:
INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1, now(), 'web'
FROM generate_series(1, 200000);

REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;

-- SESI 2, segera:
SELECT count(*) FROM lab4.ringkasan_akses;