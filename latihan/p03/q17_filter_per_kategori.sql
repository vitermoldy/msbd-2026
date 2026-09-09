-- Versi Agregat Filter
SELECT
    c.name AS kategori,
    COUNT(*) AS total_film,
    COUNT(*) FILTER (WHERE f.rating = 'G') AS film_g,
    COUNT(*) FILTER (WHERE f.rating = 'PG-13') AS film_pg13,
    ROUND(AVG(f.length) FILTER (WHERE f.length > 90), 2) AS avg_durasi_gt90
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
GROUP BY c.name
ORDER BY kategori;

-- Versi Case When
SELECT
    c.name AS kategori,
    COUNT(*) AS total_film,
    COUNT(CASE WHEN f.rating = 'G' THEN 1 END) AS film_g,
    COUNT(CASE WHEN f.rating = 'PG-13' THEN 1 END) AS film_pg13,
    ROUND(AVG(CASE WHEN f.length > 90 THEN f.length END), 2) AS avg_durasi_gt90
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
GROUP BY c.name
ORDER BY kategori;