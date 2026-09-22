-- Diminta: menambahkan EXCEPTION WHEN foreign_key_violation dengan pesan yang lebih ramah.
-- Dipilih: error FK ditangkap dan diganti dengan pesan yang mudah dipahami.
-- Alternatif: membiarkan pesan PostgreSQL asli; tidak dipilih karena pesan asli berisi detail teknis yang tidak perlu ditampilkan ke pengguna.

CREATE OR REPLACE PROCEDURE lab5.process_rental_fk(
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

EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'customer, inventory, atau staff tidak dikenal';
END;
$$;

-- Uji dengan customer_id yang tidak ada
CALL lab5.process_rental_fk(999999, 1, 1, 4.99);