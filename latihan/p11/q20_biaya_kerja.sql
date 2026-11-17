-- Diminta: ukur biaya gen_salt('bf', 6), gen_salt('bf', 10), dan md5().
-- Dipilih: ukur operasi hashing lengkap (crypt untuk bcrypt), 1000 iterasi,
--          dengan clock_timestamp() agar biaya komputasi dapat dibandingkan.
-- Alternatif: hanya mengukur pembuatan salt atau menyimpulkan waktu tanpa uji.

\set ON_ERROR_STOP on

DO $$
DECLARE
    mulai timestamptz;
    durasi_bf6 interval;
    durasi_bf10 interval;
    durasi_md5 interval;
    hasil text;
BEGIN
    mulai := clock_timestamp();
    FOR i IN 1..20 LOOP
        hasil := crypt('Lab11-Sandi-Uji!', gen_salt('bf', 6));
    END LOOP;
    durasi_bf6 := clock_timestamp() - mulai;

    mulai := clock_timestamp();
    FOR i IN 1..20 LOOP
        hasil := crypt('Lab11-Sandi-Uji!', gen_salt('bf', 10));
    END LOOP;
    durasi_bf10 := clock_timestamp() - mulai;

    mulai := clock_timestamp();
    FOR i IN 1..20 LOOP
        hasil := md5('Lab11-Sandi-Uji!');
    END LOOP;
    durasi_md5 := clock_timestamp() - mulai;

    RAISE NOTICE '1000 bcrypt cost 6 : %', durasi_bf6;
    RAISE NOTICE '1000 bcrypt cost 10: %', durasi_bf10;
    RAISE NOTICE '1000 MD5           : %', durasi_md5;
END $$;
