-- Diminta: hash kata sandi akun dengan crypt(..., gen_salt('bf', 8)),
--          tunjukkan dua hash berbeda dari kata sandi yang sama, dan jelaskan
--          serangan yang diperlambat/dicegah.
-- Dipilih: bcrypt melalui pgcrypto; setiap pemanggilan gen_salt membuat salt acak.
-- Alternatif: MD5 atau enkripsi reversibel tidak dipakai untuk menyimpan kata sandi.

\set ON_ERROR_STOP on

-- Untuk demonstrasi lab, keempat akun memakai kata sandi uji yang sama.
-- crypt() menyimpan hash bcrypt, bukan kata sandi asli.
UPDATE lab11.akun
SET kata_sandi = crypt('Lab11-Sandi-Uji!', gen_salt('bf', 8));

-- Dua hash untuk plaintext yang sama akan berbeda karena salt acak.
SELECT
    crypt('Lab11-Sandi-Uji!', gen_salt('bf', 8)) AS hash_1,
    crypt('Lab11-Sandi-Uji!', gen_salt('bf', 8)) AS hash_2;

-- Verifikasi: hash tersimpan dapat dipakai untuk memeriksa kata sandi.
SELECT
    akun_id,
    pengguna,
    crypt('Lab11-Sandi-Uji!', kata_sandi) = kata_sandi AS kata_sandi_cocok
FROM lab11.akun
ORDER BY akun_id;

-- Periksa bahwa hash yang disimpan bukan plaintext.
SELECT
    count(*) AS jumlah_akun,
    count(DISTINCT kata_sandi) AS hash_unik
FROM lab11.akun;
