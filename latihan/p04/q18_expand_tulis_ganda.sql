-- Diminta: Buat struktur baru (harga_film) dan trigger tulis ganda agar perubahan rental_rate
--          di tabel film otomatis tersalin ke harga_film.
-- Dipilih: Membuat tabel harga_film dengan daterange, lalu membuat trigger AFTER UPDATE OF rental_rate
--          yang menyisipkan baris baru ke harga_film dengan periode [now(), NULL).
-- Alternatif: Menggunakan cron job atau aplikasi backend untuk sinkronisasi; tidak dipilih karena
--             berisiko data tidak konsisten (race condition) dan tidak real-time.

-- 1. Buat tabel struktur baru
CREATE TABLE IF NOT EXISTS lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film(film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    EXCLUDE USING gist (film_id WITH =, wilayah WITH =, berlaku WITH &&)
);

-- 2. Buat fungsi trigger tulis ganda
CREATE OR REPLACE FUNCTION lab4.sync_harga_film()
RETURNS TRIGGER AS $$
BEGIN
    -- Tutup periode harga lama
    UPDATE lab4.harga_film
    SET berlaku = daterange(lower(berlaku), now())
    WHERE film_id = NEW.film_id
      AND wilayah = 'ID'
      AND upper(berlaku) IS NULL;

    -- Sisipkan harga baru
    INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
    VALUES (NEW.film_id, 'ID', NEW.rental_rate, daterange(now(), NULL));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Pasang trigger
DROP TRIGGER IF EXISTS trg_sync_harga ON lab4.film;
CREATE TRIGGER trg_sync_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.sync_harga_film();
