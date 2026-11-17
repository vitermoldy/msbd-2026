-- Diminta: hitung kombinasi unik (kota, lahir), hitung ulang setelah lahir
--          digeneralisasi menjadi tahun, hitung penurunan persentase, dan
--          tunjukkan satu query agregat yang dapat menandai satu orang.
-- Dipilih: COUNT(DISTINCT (kota, lahir)) dibandingkan dengan pasangan kota+tahun.
-- Alternatif: menghitung keunikan hanya dari kota atau hanya dari tahun lahir.

\set ON_ERROR_STOP on

WITH hitung AS (
    SELECT
        count(DISTINCT (kota, lahir)) AS kombinasi_sebelum,
        count(DISTINCT (kota, date_trunc('year', lahir)::date)) AS kombinasi_sesudah
    FROM lab11.pelanggan
)
SELECT
    kombinasi_sebelum,
    kombinasi_sesudah,
    round(
        100.0 * (kombinasi_sebelum - kombinasi_sesudah)
        / NULLIF(kombinasi_sebelum, 0),
        2
    ) AS penurunan_persen
FROM hitung;

-- Kombinasi kota dan tanggal lahir yang hanya dimiliki satu baris.
-- Baris-baris ini berpotensi lebih mudah diidentifikasi ulang.
SELECT
    kota,
    lahir,
    count(*) AS jumlah_orang
FROM lab11.pelanggan
GROUP BY kota, lahir
HAVING count(*) = 1
ORDER BY kota, lahir;
