CREATE OR REPLACE VIEW lab4.film_lama AS
SELECT
    f.film_id, f.title, f.rating,
    (SELECT h.harga FROM lab4.harga_film h
     WHERE h.film_id = f.film_id AND h.wilayah = 'ID' AND upper(h.berlaku) IS NULL
     LIMIT 1) AS rental_rate
FROM lab4.film f;
