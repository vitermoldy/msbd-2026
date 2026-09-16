-- Diminta: menjalankan query agregasi bulanan per kanal atas 500000 baris dan mencatat waktunya.
-- Dipilih: menjalankan query apa adanya dengan \timing on sebagai garis dasar, dan mengulang
--          tiga kali karena eksekusi pertama masih diganggu cache dingin.
-- Alternatif: langsung memakai EXPLAIN ANALYZE sebagai angka utama; tidak dipilih karena angka
--          itu tidak memasukkan waktu pengiriman hasil, sehingga tidak sebanding dengan waktu
--          REFRESH yang dibandingkan pada Q6 dan Q7.

\timing on
SET search_path = lab4, public;

SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*)                     AS jumlah_akses,
       count(DISTINCT a.film_id)    AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2;

-- Opsional, untuk penafsiran di laporan: rencana eksekusinya.
EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2;