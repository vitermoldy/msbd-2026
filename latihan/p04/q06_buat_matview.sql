-- Diminta: menjadikan query Q5 materialized view lab4.ringkasan_akses dengan WITH NO DATA,
--          membaca sebelum refresh, menyalin galatnya, lalu refresh biasa dan catat waktunya.
-- Dipilih: WITH NO DATA agar pembuatan objek terpisah dari pengisian data, sehingga galat
--          "has not been populated" dapat dibuktikan dan biaya refresh terukur sendiri.
-- Alternatif: CREATE MATERIALIZED VIEW ... WITH DATA; tidak dipilih karena menggabungkan
--          pembuatan dan pengisian, sehingga kedua bukti yang diminta soal tidak terpisah.

\timing on
SET search_path = lab4, public;

DROP MATERIALIZED VIEW IF EXISTS lab4.ringkasan_akses;

CREATE MATERIALIZED VIEW lab4.ringkasan_akses AS
SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*)                     AS jumlah_akses,
       count(DISTINCT a.film_id)    AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
WITH NO DATA;

-- Membaca sebelum refresh. Harus GAGAL.
SELECT count(*) FROM lab4.ringkasan_akses;

-- Refresh biasa. Catat waktunya.
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;

SELECT count(*) AS baris_matview FROM lab4.ringkasan_akses;
SELECT * FROM lab4.ringkasan_akses ORDER BY bulan, kanal LIMIT 8;

-- Bukti status terisi pada katalog.
SELECT matviewname, ispopulated FROM pg_matviews WHERE schemaname = 'lab4';