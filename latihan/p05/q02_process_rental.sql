-- Diminta: menyalin procedure lab5.process_rental dari materi kuliah, membuktikan satu pemanggilan menghasilkan baris di rental_tx dan payment_tx.
-- Dipilih: menggunakan procedure dengan parameter INOUT p_rental_id sesuai materi kuliah.
-- Alternatif: melakukan INSERT langsung ke kedua tabel; tidak dipilih karena soal meminta penggunaan procedure.

CREATE OR REPLACE PROCEDURE lab5.process_rental(
  IN p_customer_id  integer,
  IN p_inventory_id integer,
  IN p_staff_id     integer,
  IN p_amount       numeric(10,2),
  IN p_metadata     jsonb DEFAULT '{}'::jsonb,
  INOUT p_rental_id bigint DEFAULT NULL
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'nilai pembayaran harus positif, diterima %', p_amount
      USING ERRCODE = '22003';
  END IF;

  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id, metadata)
  VALUES (p_customer_id, p_inventory_id, p_staff_id,
          coalesce(p_metadata, '{}'::jsonb))
  RETURNING rental_id INTO p_rental_id;

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (p_rental_id, p_amount);

END;
$$;

CALL lab5.process_rental(1, 1, 1, 4.99);

SELECT * FROM lab5.rental_tx;
SELECT * FROM lab5.payment_tx;