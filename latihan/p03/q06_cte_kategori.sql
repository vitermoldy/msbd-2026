-- Diminta: menulis ulang Q2 (kategori dengan jumlah film > 60) memakai CTE,
--          lalu menambahkan CTE kedua yang menghitung rata-rata tarif sewa
--          per kategori. Keluaran akhir: nama kategori, jumlah film, rata-rata tarif.
-- Dipilih: dua CTE berurutan. CTE pertama (kategori_film) menghasilkan daftar
--          kategori yang lolos syarat HAVING > 60, CTE kedua (rata_tarif)
--          merujuk CTE pertama untuk menghitung rata-rata tarif hanya pada
--          kategori yang sudah tersaring — ini mencegah rata-rata dihitung
--          dari kategori yang seharusnya sudah dibuang.
-- Alternatif: menghitung jumlah film dan rata-rata tarif dalam satu CTE saja
--          (GROUP BY + HAVING sekaligus AVG). Tidak dipilih karena soal
--          eksplisit meminta dua CTE berurutan untuk melatih pola CTE
--          yang saling merujuk, bukan karena satu CTE tidak bisa menjawabnya.

WITH kategori_film AS (
    SELECT
        c.category_id,
        c.name AS kategori,
        count(*) AS jumlah_film
    FROM category c
    JOIN film_category fc ON fc.category_id = c.category_id
    GROUP BY c.category_id, c.name
    HAVING count(*) > 60
),
rata_tarif AS (
    SELECT
        kf.category_id,
        kf.kategori,
        kf.jumlah_film,
        avg(f.rental_rate) AS rata_tarif
    FROM kategori_film kf
    JOIN film_category fc ON fc.category_id = kf.category_id
    JOIN film f ON f.film_id = fc.film_id
    GROUP BY kf.category_id, kf.kategori, kf.jumlah_film
)
SELECT
    kategori,
    jumlah_film,
    round(rata_tarif, 2) AS rata_tarif
FROM rata_tarif
ORDER BY jumlah_film DESC;
