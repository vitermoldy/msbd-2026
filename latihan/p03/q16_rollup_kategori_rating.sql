SELECT
    CASE WHEN GROUPING(c.name) = 1 THEN 'SEMUA' ELSE c.name END AS kategori,
    CASE WHEN GROUPING(f.rating) = 1 THEN 'SEMUA' ELSE f.rating::text END AS rating,
    COUNT(*) AS jumlah_film,
    ROUND(AVG(f.rental_rate), 2) AS rata_tarif
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
GROUP BY ROLLUP(c.name, f.rating)
ORDER BY
    GROUPING(c.name), c.name,
    GROUPING(f.rating), f.rating;