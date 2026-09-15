-- 1. Buat tabel audit
CREATE TABLE IF NOT EXISTS lab4.audit_harga (
    audit_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    harga_lama numeric(5,2),
    harga_baru numeric(5,2),
    diubah_oleh text NOT NULL DEFAULT current_user,
    diubah_pada timestamptz NOT NULL DEFAULT now()
);

-- 2. Fungsi trigger
CREATE OR REPLACE FUNCTION lab4.catat_audit_harga()
RETURNS trigger AS $$
BEGIN
    INSERT INTO lab4.audit_harga (film_id, harga_lama, harga_baru)
    VALUES (OLD.film_id, OLD.rental_rate, NEW.rental_rate);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger per baris
DROP TRIGGER IF EXISTS trg_audit_harga_film ON lab4.film;

CREATE TRIGGER trg_audit_harga_film
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();