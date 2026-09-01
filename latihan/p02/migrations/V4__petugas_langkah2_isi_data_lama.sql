UPDATE peminjaman
SET petugas = 'tidak tercatat'
WHERE petugas IS NULL;
