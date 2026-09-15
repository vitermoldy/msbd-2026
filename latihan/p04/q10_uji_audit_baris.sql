-- Kosongkan log audit dulu untuk pengujian
TRUNCATE TABLE lab4.audit_harga;

-- Uji 1: Mengubah harga
UPDATE lab4.film SET rental_rate = 9.99 WHERE film_id = 1;

-- Uji 2: Menulis ulang harga yang sama persis
UPDATE lab4.film SET rental_rate = 9.99 WHERE film_id = 1;

-- Uji 3: Mengubah title saja
UPDATE lab4.film SET title = 'NEW TITLE' WHERE film_id = 1;

-- Cek hasil audit
SELECT * FROM lab4.audit_harga;