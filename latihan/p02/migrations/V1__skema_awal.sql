-- =========================================================
-- KD-04: Klasifikasi masalah dan batas waktu penyelesaian (SLA)
-- =========================================================
CREATE TABLE kategori_masalah (
    id_kategori   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kode_kategori varchar(16)  NOT NULL UNIQUE,
    nama_kategori varchar(100) NOT NULL,
    sla_jam       integer      NOT NULL
        CONSTRAINT ck_kategori_sla_positif CHECK (sla_jam > 0)
);

-- =========================================================
-- KD-02: Pendataan lokasi (bagian dari lokasi & fasilitas)
-- =========================================================
CREATE TABLE lokasi (
    id_lokasi  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kode_ruang varchar(16)  NOT NULL UNIQUE,
    gedung     varchar(100) NOT NULL,
    lantai     smallint     NOT NULL,
    nama_ruang varchar(100) NOT NULL
);

-- =========================================================
-- KD-02: Pendataan unit fasilitas
-- =========================================================
CREATE TABLE fasilitas (
    id_fasilitas    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_lokasi       bigint       NOT NULL REFERENCES lokasi(id_lokasi),
    kode_inventaris varchar(32)  NOT NULL UNIQUE,
    nama_fasilitas  varchar(150) NOT NULL,
    status_fasilitas varchar(16) NOT NULL DEFAULT 'aktif'
        CONSTRAINT ck_fasilitas_status
        CHECK (status_fasilitas IN ('aktif', 'rusak', 'dihapus')),
    tgl_perolehan   date NOT NULL
);

-- =========================================================
-- KD-01: Pendataan pelapor dan perannya
-- =========================================================
CREATE TABLE peran (
    id_peran bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kode     varchar(8)  NOT NULL UNIQUE,
    nama     varchar(60) NOT NULL
);
CREATE TABLE pelapor (
    id_pelapor    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nomor_induk   varchar(20)  NOT NULL UNIQUE,
    nama          varchar(150) NOT NULL,
    email         varchar(150) NOT NULL UNIQUE,
    id_peran      bigint       NOT NULL REFERENCES peran(id_peran),
    status        varchar(16)  NOT NULL DEFAULT 'aktif'
        CONSTRAINT ck_pelapor_status
        CHECK (status IN ('aktif', 'nonaktif')),
    tgl_terdaftar date NOT NULL DEFAULT current_date
);

-- =========================================================
-- KD-03: Pembuatan tiket laporan kerusakan
-- =========================================================
CREATE TABLE tiket (
    id_tiket        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nomor_tiket     varchar(20)  NOT NULL UNIQUE,
    id_pelapor      bigint       NOT NULL REFERENCES pelapor(id_pelapor),
    id_fasilitas    bigint       NOT NULL REFERENCES fasilitas(id_fasilitas),
    id_kategori     bigint       NOT NULL REFERENCES kategori_masalah(id_kategori),
    judul           varchar(150) NOT NULL,
    deskripsi       text         NOT NULL,
    prioritas       varchar(16)  NOT NULL DEFAULT 'biasa'
        CONSTRAINT ck_tiket_prioritas
        CHECK (prioritas IN ('biasa', 'tinggi', 'darurat')),
    status varchar(16) NOT NULL DEFAULT 'baru'
    CONSTRAINT ck_tiket_status
    CHECK (status IN (
        'baru',
        'ditugaskan',
        'diproses',
        'selesai',
        'ditutup',
        'dibatalkan'
    )),
    dilaporkan_pada timestamp    NOT NULL DEFAULT now(),
    jatuh_tempo     timestamp    NOT NULL,
    CONSTRAINT ck_tiket_jatuh_tempo
        CHECK (jatuh_tempo > dilaporkan_pada)
);

