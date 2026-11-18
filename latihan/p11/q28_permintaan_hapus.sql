-- Diminta: membuat tabel untuk mencatat permintaan penghapusan dan tenggat 72 jam.
-- Dipilih: DEFAULT now() + interval '72 hours' pada kolom timestamptz, sesuai PostgreSQL 17.
-- Alternatif: GENERATED ALWAYS; tidak dipilih karena ekspresi timestamptz tersebut tidak immutable.

\set ON_ERROR_STOP on

CREATE TABLE IF NOT EXISTS lab11.permintaan_hapus (
    permintaan_id bigserial PRIMARY KEY,
    subjek_ids    int[] NOT NULL,
    alasan        text NOT NULL,
    status        text NOT NULL DEFAULT 'diterima'
                  CHECK (status IN ('diterima', 'diproses', 'selesai', 'ditolak')),
    diterima_pada timestamptz NOT NULL DEFAULT now(),
    tenggat       timestamptz NOT NULL DEFAULT now() + interval '72 hours',
    selesai_pada  timestamptz
);

REVOKE ALL ON lab11.permintaan_hapus FROM PUBLIC;
REVOKE ALL ON lab11.permintaan_hapus FROM app_read, app_write, app_laporan,
    app_portal, app_analitik, app_audit;

-- Pemeriksaan default tenggat.
SELECT column_name, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'lab11'
  AND table_name = 'permintaan_hapus'
  AND column_name IN ('diterima_pada', 'tenggat')
ORDER BY ordinal_position;
