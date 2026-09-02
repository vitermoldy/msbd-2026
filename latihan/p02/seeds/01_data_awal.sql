-- kategori_masalah
INSERT INTO kategori_masalah (
    kode_kategori,
    nama_kategori,
    sla_jam
) VALUES
    ('LIS', 'Masalah Listrik', 24),
    ('JAR', 'Masalah Jaringan', 12),
    ('FAS', 'Kerusakan Fasilitas', 48)
ON CONFLICT (kode_kategori) DO UPDATE SET
    nama_kategori = EXCLUDED.nama_kategori,
    sla_jam = EXCLUDED.sla_jam;


-- lokasi
INSERT INTO lokasi (
    kode_ruang,
    gedung,
    lantai,
    nama_ruang
) VALUES
    ('R101', 'Gedung A', 1, 'Ruang Kelas 101'),
    ('R201', 'Gedung A', 2, 'Laboratorium Komputer'),
    ('R301', 'Gedung B', 3, 'Ruang Dosen')
ON CONFLICT (kode_ruang) DO UPDATE SET
    gedung = EXCLUDED.gedung,
    lantai = EXCLUDED.lantai,
    nama_ruang = EXCLUDED.nama_ruang;


-- peran
INSERT INTO peran (
    kode,
    nama
) VALUES
    ('MHS', 'Mahasiswa'),
    ('DSN', 'Dosen'),
    ('STF', 'Staf')
ON CONFLICT (kode) DO UPDATE SET
    nama = EXCLUDED.nama;


-- fasilitas
INSERT INTO fasilitas (
    id_lokasi,
    kode_inventaris,
    nama_fasilitas,
    status_fasilitas,
    tgl_perolehan
)
SELECT
    l.id_lokasi,
    data.kode_inventaris,
    data.nama_fasilitas,
    data.status_fasilitas,
    data.tgl_perolehan
FROM (
    VALUES
        ('R101', 'INV-001', 'Proyektor', 'aktif', DATE '2024-01-15'),
        ('R201', 'INV-002', 'Komputer', 'rusak', DATE '2023-08-10'),
        ('R301', 'INV-003', 'AC Ruangan', 'aktif', DATE '2024-03-20')
) AS data(
    kode_ruang,
    kode_inventaris,
    nama_fasilitas,
    status_fasilitas,
    tgl_perolehan
)
JOIN lokasi l
    ON l.kode_ruang = data.kode_ruang
ON CONFLICT (kode_inventaris) DO UPDATE SET
    id_lokasi = EXCLUDED.id_lokasi,
    nama_fasilitas = EXCLUDED.nama_fasilitas,
    status_fasilitas = EXCLUDED.status_fasilitas,
    tgl_perolehan = EXCLUDED.tgl_perolehan;


-- pelapor
INSERT INTO pelapor (
    nomor_induk,
    nama,
    email,
    id_peran,
    status,
    nomor_telepon
)
SELECT
    data.nomor_induk,
    data.nama,
    data.email,
    p.id_peran,
    data.status,
    data.nomor_telepon
FROM (
    VALUES
        ('MHS-001', 'Mahasiswa Helpdesk', 'mahasiswa@kampus.ac.id',
         'MHS', 'aktif', '081234567890'),
        ('DSN-001', 'Dosen Helpdesk', 'dosen@kampus.ac.id',
         'DSN', 'aktif', '081298765432'),
        ('STF-001', 'Staf Helpdesk', 'staf@kampus.ac.id',
         'STF', 'aktif', '082112345678')
) AS data(
    nomor_induk,
    nama,
    email,
    kode_peran,
    status,
    nomor_telepon
)
JOIN peran p
    ON p.kode = data.kode_peran
ON CONFLICT (nomor_induk) DO UPDATE SET
    nama = EXCLUDED.nama,
    email = EXCLUDED.email,
    id_peran = EXCLUDED.id_peran,
    status = EXCLUDED.status,
    nomor_telepon = EXCLUDED.nomor_telepon;


-- tiket
INSERT INTO tiket (
    nomor_tiket,
    id_pelapor,
    id_fasilitas,
    id_kategori,
    judul,
    deskripsi,
    prioritas,
    status,
    dilaporkan_pada,
    jatuh_tempo
)
SELECT
    data.nomor_tiket,
    p.id_pelapor,
    f.id_fasilitas,
    k.id_kategori,
    data.judul,
    data.deskripsi,
    data.prioritas,
    data.status,
    data.dilaporkan_pada,
    data.jatuh_tempo
FROM (
    VALUES
        (
            'TKT-001',
            'MHS-001',
            'INV-001',
            'LIS',
            'Proyektor tidak menyala',
            'Proyektor di ruang kelas tidak dapat digunakan.',
            'tinggi',
            'baru',
            TIMESTAMP '2026-08-25 09:00:00',
            TIMESTAMP '2026-08-26 09:00:00'
        ),
        (
            'TKT-002',
            'DSN-001',
            'INV-002',
            'JAR',
            'Komputer tidak terhubung jaringan',
            'Komputer laboratorium tidak dapat mengakses jaringan kampus.',
            'biasa',
            'diproses',
            TIMESTAMP '2026-08-25 10:00:00',
            TIMESTAMP '2026-08-25 22:00:00'
        ),
        (
            'TKT-003',
            'STF-001',
            'INV-003',
            'FAS',
            'AC tidak dingin',
            'AC pada ruang dosen tidak menghasilkan udara dingin.',
            'biasa',
            'selesai',
            TIMESTAMP '2026-08-24 08:00:00',
            TIMESTAMP '2026-08-26 08:00:00'
        )
) AS data(
    nomor_tiket,
    nomor_induk,
    kode_inventaris,
    kode_kategori,
    judul,
    deskripsi,
    prioritas,
    status,
    dilaporkan_pada,
    jatuh_tempo
)
JOIN pelapor p
    ON p.nomor_induk = data.nomor_induk
JOIN fasilitas f
    ON f.kode_inventaris = data.kode_inventaris
JOIN kategori_masalah k
    ON k.kode_kategori = data.kode_kategori
ON CONFLICT (nomor_tiket) DO UPDATE SET
    id_pelapor = EXCLUDED.id_pelapor,
    id_fasilitas = EXCLUDED.id_fasilitas,
    id_kategori = EXCLUDED.id_kategori,
    judul = EXCLUDED.judul,
    deskripsi = EXCLUDED.deskripsi,
    prioritas = EXCLUDED.prioritas,
    status = EXCLUDED.status,
    dilaporkan_pada = EXCLUDED.dilaporkan_pada,
    jatuh_tempo = EXCLUDED.jatuh_tempo;