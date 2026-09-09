-- ada di inventory tetapi tidak pernah muncul melalui rental
(
    SELECT 
        film_id, 
        'Di inventory, tidak pernah disewa' AS penanda_arah
    FROM (
        SELECT film_id FROM inventory
        EXCEPT
        SELECT i.film_id 
        FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
    ) AS inventory_only
)

UNION ALL

-- Ada di Rental tetapi tidak ada di Inventory (sebaliknya)
(
    SELECT 
        film_id, 
        'Di rental, tidak ada di inventory' AS penanda_arah
    FROM (
        SELECT i.film_id 
        FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        EXCEPT
        SELECT film_id FROM inventory
    ) AS rental_only
)
ORDER BY film_id, penanda_arah;



