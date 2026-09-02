INSERT INTO peran (kode, nama) VALUES
('ADM', 'Administrator'),
('PTG', 'Petugas'),
('AGT', 'Anggota')
ON CONFLICT (kode)
DO UPDATE SET nama = EXCLUDED.nama;