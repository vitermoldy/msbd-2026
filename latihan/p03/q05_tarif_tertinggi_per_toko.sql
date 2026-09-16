-- Diminta: untuk setiap toko, judul film dengan tarif sewa tertinggi di toko
--          tersebut, diselesaikan tanpa window function.
-- Dipilih: subquery berkorelasi dengan max(), karena nilai pembandingnya
--          berbeda untuk tiap toko sehingga harus dihitung ulang untuk baris
--          toko yang sedang diperiksa.
-- Alternatif: >= ALL terhadap seluruh daftar tarif di toko itu; sah, tetapi
--          membandingkan ke banyak nilai alih-alih satu nilai maksimum,
--          sehingga maksudnya lebih sulit dibaca.

SELECT DISTINCT i.store_id,
       f.title,
       f.rental_rate
FROM inventory i
JOIN film f ON f.film_id = i.film_id
WHERE f.rental_rate = (
    SELECT max(f2.rental_rate)
    FROM inventory i2
    JOIN film f2 ON f2.film_id = i2.film_id
    WHERE i2.store_id = i.store_id
)
ORDER BY i.store_id, f.title;

-- Hasil: 500 baris