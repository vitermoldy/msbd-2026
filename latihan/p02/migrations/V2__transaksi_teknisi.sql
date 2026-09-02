-- =========================================================
-- V2__transaksi_teknisi.sql
-- Melanjutkan V1. Menambahkan entitas transaksional dan kedua
-- entitas asosiatif M:N: KEAHLIAN dan PENUGASAN.
-- =========================================================

-- =========================================================
-- KD-05: Data teknisi beserta kuota tiket aktifnya
-- =========================================================
CREATE TABLE teknisi (
    id_teknisi        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nomor_pegawai     varchar(20)  NOT NULL UNIQUE,
    nama              varchar(150) NOT NULL,
    kuota_tiket_aktif smallint     NOT NULL DEFAULT 5
        CONSTRAINT ck_teknisi_kuota CHECK (kuota_tiket_aktif BETWEEN 1 AND 20),
    status            varchar(16)  NOT NULL DEFAULT 'aktif'
        CONSTRAINT ck_teknisi_status
        CHECK (status IN ('aktif', 'cuti', 'nonaktif'))
);

-- =========================================================
-- KD-06: Entitas asosiatif M:N antara TEKNISI dan KATEGORI_MASALAH
-- =========================================================
CREATE TABLE keahlian (
    id_teknisi       bigint   NOT NULL REFERENCES teknisi(id_teknisi) ON DELETE CASCADE,
    id_kategori      bigint   NOT NULL REFERENCES kategori_masalah(id_kategori),
    level_kompetensi smallint NOT NULL DEFAULT 1
        CONSTRAINT ck_keahlian_level CHECK (level_kompetensi BETWEEN 1 AND 3),
    CONSTRAINT pk_keahlian PRIMARY KEY (id_teknisi, id_kategori)
);

-- =========================================================
-- KD-05: Entitas asosiatif M:N antara TIKET dan TEKNISI
-- =========================================================
CREATE TABLE penugasan (
    id_penugasan     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tiket         bigint      NOT NULL REFERENCES tiket(id_tiket) ON DELETE CASCADE,
    id_teknisi       bigint      NOT NULL REFERENCES teknisi(id_teknisi),
    peran_penugasan  varchar(12) NOT NULL DEFAULT 'utama'
        CONSTRAINT ck_penugasan_peran
        CHECK (peran_penugasan IN ('utama', 'pendukung')),
    ditugaskan_pada  timestamp   NOT NULL DEFAULT now(),
    selesai_pada     timestamp,
    catatan_tindakan text,
    CONSTRAINT uq_penugasan_tiket_teknisi UNIQUE (id_tiket, id_teknisi),
    CONSTRAINT ck_penugasan_selesai
        CHECK (selesai_pada IS NULL OR selesai_pada >= ditugaskan_pada)
);

-- KD-05: satu tiket hanya boleh memiliki satu teknisi berperan 'utama'.
-- Aturan ini tidak bisa ditulis sebagai CHECK biasa karena melibatkan
-- lebih dari satu baris, jadi ditegakkan lewat unique partial index.
CREATE UNIQUE INDEX uq_penugasan_satu_utama
    ON penugasan (id_tiket)
    WHERE peran_penugasan = 'utama';

-- =========================================================
-- KD-08: Jejak audit perubahan status tiket (append-only)
-- =========================================================
CREATE TABLE riwayat_status (
    id_riwayat  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tiket    bigint       NOT NULL REFERENCES tiket(id_tiket) ON DELETE CASCADE,
    status_lama varchar(16),
    status_baru varchar(16)  NOT NULL,
    diubah_oleh varchar(150) NOT NULL,
    diubah_pada timestamp    NOT NULL DEFAULT now()
);

-- =========================================================
-- Index pada kolom kunci asing.
-- PostgreSQL membuat index otomatis untuk PRIMARY KEY dan UNIQUE,
-- tetapi TIDAK untuk kolom FOREIGN KEY.
-- =========================================================
CREATE INDEX idx_pelapor_peran     ON pelapor (id_peran);
CREATE INDEX idx_fasilitas_lokasi  ON fasilitas (id_lokasi);
CREATE INDEX idx_tiket_pelapor     ON tiket (id_pelapor);
CREATE INDEX idx_tiket_fasilitas   ON tiket (id_fasilitas);
CREATE INDEX idx_tiket_kategori    ON tiket (id_kategori);
CREATE INDEX idx_tiket_status      ON tiket (status);
CREATE INDEX idx_penugasan_teknisi ON penugasan (id_teknisi);
CREATE INDEX idx_riwayat_tiket     ON riwayat_status (id_tiket, diubah_pada);
