CREATE OR REPLACE FUNCTION lab4.sync_harga_film()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE lab4.harga_film
    SET berlaku = daterange(lower(berlaku), now())
    WHERE film_id = NEW.film_id AND wilayah = 'ID' AND upper(berlaku) IS NULL;

    INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
    VALUES (NEW.film_id, 'ID', NEW.rental_rate, daterange(now(), NULL));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.sync_harga_film();
