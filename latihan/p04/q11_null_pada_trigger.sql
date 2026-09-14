-- Ubah trigger memakai operator <> menggantikan IS DISTINCT FROM
CREATE OR REPLACE TRIGGER trg_audit_harga_film
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate <> NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();

-- Ubah harga dari nilai biasa ke NULL
UPDATE lab4.film SET rental_rate = NULL WHERE film_id = 2;

-- Ubah harga dari NULL ke nilai biasa
UPDATE lab4.film SET rental_rate = 4.99 WHERE film_id = 2;

-- Cek hasil audit
SELECT * FROM lab4.audit_harga WHERE film_id = 2;
