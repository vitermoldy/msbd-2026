-- Diminta: enkripsi kolom rekening untuk 1000 baris dengan pgp_sym_encrypt;
--          kunci disuntikkan per session, satu baris didekripsi, dan dua
--          enkripsi plaintext+kunci yang sama dibuktikan menghasilkan ciphertext berbeda.
-- Dipilih: custom setting app.kunci_kolom dan pgp_sym_encrypt dari pgcrypto.
-- Alternatif: menyimpan rekening plaintext atau menaruh kunci permanen di tabel.

\set ON_ERROR_STOP on

-- Jalankan pada session yang sama dengan seluruh perintah di bawah.
SET app.kunci_kolom = 'kunci-lab11-jangan-dipakai-di-produksi';

ALTER TABLE lab11.pelanggan
    ADD COLUMN IF NOT EXISTS rekening_enc bytea;

UPDATE lab11.pelanggan
SET rekening_enc = pgp_sym_encrypt(
    rekening,
    current_setting('app.kunci_kolom')
)
WHERE id <= 1000;

-- Bukti satu baris ciphertext dapat dikembalikan menjadi rekening asli.
SELECT
    id,
    rekening,
    pgp_sym_decrypt(
        rekening_enc,
        current_setting('app.kunci_kolom')
    ) AS rekening_hasil_dekripsi
FROM lab11.pelanggan
WHERE id = 1;

-- Bukti enkripsi bersifat probabilistik: plaintext dan kunci sama,
-- tetapi ciphertext umumnya berbeda karena komponen acak PGP.
SELECT
    pgp_sym_encrypt('rekening-uji', 'kunci-uji') =
    pgp_sym_encrypt('rekening-uji', 'kunci-uji') AS ciphertext_sama;

-- Harapan: ciphertext_sama = false.
