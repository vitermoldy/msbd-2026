CREATE OR REPLACE FUNCTION lab11.urutkan_pelanggan_aman(p_kolom text, p_arah text)
RETURNS TABLE(id int, nama text, kota text)
LANGUAGE plpgsql
AS $$
DECLARE
    v_kolom text;
    v_arah  text;
BEGIN
    v_kolom := CASE p_kolom
        WHEN 'nama'    THEN 'nama'
        WHEN 'kota'    THEN 'kota'
        WHEN 'terbaru' THEN 'dibuat_pada'
        ELSE NULL
    END;

    v_arah := CASE lower(p_arah)
        WHEN 'naik'  THEN 'ASC'
        WHEN 'turun' THEN 'DESC'
        ELSE NULL
    END;

    IF v_kolom IS NULL OR v_arah IS NULL THEN
        RAISE EXCEPTION 'parameter pengurutan tidak dikenal: kolom=%, arah=%', p_kolom, p_arah
            USING ERRCODE = '22023';
    END IF;

    RETURN QUERY EXECUTE format(
        'SELECT id, nama, kota FROM lab11.pelanggan ORDER BY %I %s LIMIT 5',
        v_kolom, v_arah
    );
END;
$$;

SELECT * FROM lab11.urutkan_pelanggan_aman('nama', 'naik');

SELECT * FROM lab11.urutkan_pelanggan_aman('nama; SELECT 1--', 'naik');
