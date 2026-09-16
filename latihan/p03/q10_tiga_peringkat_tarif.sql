SELECT
    f.title AS judul,
    c.name AS kategori,
    f.rental_rate AS tarif_sewa,
    ROW_NUMBER() OVER w AS row_num,
    RANK() OVER w AS rank_num,
    DENSE_RANK() OVER w AS dense_rank_num
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WINDOW w AS (PARTITION BY c.name ORDER BY f.rental_rate DESC);
