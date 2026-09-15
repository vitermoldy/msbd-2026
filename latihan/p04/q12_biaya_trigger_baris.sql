\timing on

UPDATE lab4.film SET rental_rate = rental_rate + 0.01;
ALTER TABLE lab4.film DISABLE TRIGGER trg_audit_harga_film;
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;
ALTER TABLE lab4.film ENABLE TRIGGER trg_audit_harga_film;

\timing off