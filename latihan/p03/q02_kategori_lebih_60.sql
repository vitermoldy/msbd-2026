-- Diminta: nama kategori beserta jumlah filmnya, hanya untuk kategori yang
--          memiliki lebih dari 60 film.
-- Dipilih: derived table pada klausa FROM, karena syarat penyaringnya dapat
--          menyebut alias jumlah_film sehingga maksudnya langsung terbaca.
-- Alternatif: HAVING dalam satu blok; sah dan lebih ringkas, tetapi wajib
--          mengulang count(*) karena alias belum ada saat HAVING dievaluasi.

-- Versi A: HAVING
SELECT c.name AS kategori,
       count(*) AS jumlah_film
FROM category c
JOIN film_category fc ON fc.category_id = c.category_id
GROUP BY c.name
HAVING count(*) > 60
ORDER BY jumlah_film DESC, kategori;

-- Versi B: derived table
SELECT *
FROM (
    SELECT c.name AS kategori,
           count(*) AS jumlah_film
    FROM category c
    JOIN film_category fc ON fc.category_id = c.category_id
    GROUP BY c.name
) AS per_kategori
WHERE jumlah_film > 60
ORDER BY jumlah_film DESC, kategori;

-- Hasil: 10 baris (sama untuk kedua versi)
