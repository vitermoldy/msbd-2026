DO $$
DECLARE
    batch_size INTEGER := 1000;
    max_id INTEGER;
    current_start INTEGER := 1;
BEGIN
    SELECT COALESCE(MAX(film_id), 0) INTO max_id FROM lab4.film;

    WHILE current_start <= max_id LOOP
        INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
        SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
        FROM lab4.film f
        WHERE f.film_id >= current_start
          AND f.film_id < current_start + batch_size
          AND NOT EXISTS (
              SELECT 1 FROM lab4.harga_film h
              WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
          );

        current_start := current_start + batch_size;
    END LOOP;
END $$;
