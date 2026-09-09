WITH ranked_films AS (
    SELECT
        f.title,
        c.name AS kategori,
        f.rental_rate,
        RANK() OVER (PARTITION BY c.name ORDER BY f.rental_rate DESC) as rnk
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
)
SELECT title, kategori, rental_rate
FROM ranked_films
WHERE rnk <= 3
ORDER BY kategori, rnk;
