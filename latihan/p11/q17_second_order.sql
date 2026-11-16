CREATE OR REPLACE FUNCTION lab11.laporan_kota_rentan(p_kota text)
RETURNS TABLE(kota text, jumlah bigint)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT kota::text, count(*)::bigint FROM lab11.pelanggan WHERE kota = ''' || p_kota || ''' GROUP BY kota';
END;
$$;

CREATE OR REPLACE FUNCTION lab11.laporan_kota_aman(p_kota text)
RETURNS TABLE(kota text, jumlah bigint)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT kota::text, count(*)::bigint FROM lab11.pelanggan WHERE kota = $1 GROUP BY kota'
        USING p_kota;
END;
$$;

BEGIN;
INSERT INTO lab11.pelanggan (id, tenant_id, nama, nik, surel, lahir, kota, saldo)
VALUES (
    99999,
    1,
    'Uji Second Order',
    '1234567890123456',
    'uji@contoh.ac.id',
    '2000-01-01',
    'Medan'' UNION SELECT surel, 1 FROM lab11.pelanggan WHERE id <= 3 --',
    100000
);

SELECT * FROM lab11.laporan_kota_rentan(
    (SELECT kota FROM lab11.pelanggan W
        -- 5. Panggil fungsi AMAN: payload yang sama diperlakukan murni sebagai string pencarian kotaHERE id = 99999)
);

SELECT * FROM lab11.laporan_kota_aman(
    (SELECT kota FROM lab11.pelanggan WHERE id = 99999)
);

ROLLBACK;
