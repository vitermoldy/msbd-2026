-- Diminta: membuat function untuk menghitung total pembayaran satu penyewaan.
-- Dipilih: menggunakan SUM(amount) dan COALESCE agar hasil tanpa pembayaran menjadi 0.
-- Alternatif: menghitung langsung dengan SELECT SUM; tidak dipilih karena tugas meminta function.

CREATE OR REPLACE FUNCTION lab5.total_dibayar(p_rental_id bigint)
RETURNS numeric
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(SUM(amount), 0)
    FROM lab5.payment_tx
    WHERE rental_id = p_rental_id;
$$;

SELECT lab5.total_dibayar(1);