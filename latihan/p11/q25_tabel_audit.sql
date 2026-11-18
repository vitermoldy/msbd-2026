-- Diminta: membuat jejak audit untuk perubahan pelanggan dan membatasi penulisannya.
-- Dipilih: trigger SECURITY DEFINER yang menulis dengan hak pemilik fungsi; pelaku dicatat memakai session_user.
-- Alternatif: GRANT INSERT kepada aplikasi; tidak dipilih karena aplikasi dapat memalsukan atau mengubah jejak audit.

\set ON_ERROR_STOP on

-- Jalankan sebagai postgres pada database msbd.
CREATE TABLE IF NOT EXISTS lab11.jejak_audit (
    audit_id    bigserial PRIMARY KEY,
    waktu       timestamptz NOT NULL DEFAULT clock_timestamp(),
    pelaku      text NOT NULL,
    aksi        text NOT NULL CHECK (aksi IN ('INSERT', 'UPDATE', 'DELETE')),
    nama_tabel  text NOT NULL,
    kunci       text NOT NULL,
    nilai_lama  jsonb,
    nilai_baru  jsonb
);

CREATE OR REPLACE FUNCTION lab11.rekam_audit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, lab11
AS $$
DECLARE
    v_lama jsonb;
    v_baru jsonb;
    v_kunci text;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_baru := to_jsonb(NEW);
        v_kunci := v_baru ->> 'id';
    ELSIF TG_OP = 'UPDATE' THEN
        v_lama := to_jsonb(OLD);
        v_baru := to_jsonb(NEW);
        v_kunci := v_baru ->> 'id';
    ELSE
        v_lama := to_jsonb(OLD);
        v_kunci := v_lama ->> 'id';
    END IF;

    INSERT INTO lab11.jejak_audit
        (pelaku, aksi, nama_tabel, kunci, nilai_lama, nilai_baru)
    VALUES
        (session_user, TG_OP, TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
         v_kunci, v_lama, v_baru);

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_pelanggan ON lab11.pelanggan;
CREATE TRIGGER trg_audit_pelanggan
AFTER INSERT OR UPDATE OR DELETE ON lab11.pelanggan
FOR EACH ROW EXECUTE FUNCTION lab11.rekam_audit();

-- Tidak ada peran aplikasi yang boleh menulis atau membaca tabel audit.
REVOKE ALL ON lab11.jejak_audit FROM PUBLIC;
REVOKE ALL ON lab11.jejak_audit FROM app_read, app_write, app_laporan,
    app_portal, app_analitik, app_audit;
REVOKE ALL ON SEQUENCE lab11.jejak_audit_audit_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE lab11.jejak_audit_audit_id_seq FROM app_read, app_write,
    app_laporan, app_portal, app_analitik, app_audit;
REVOKE ALL ON FUNCTION lab11.rekam_audit() FROM PUBLIC;
GRANT SELECT ON lab11.jejak_audit TO app_audit;

-- Pemeriksaan konfigurasi: trigger aktif dan hanya app_audit punya SELECT.
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgrelid = 'lab11.pelanggan'::regclass
  AND tgname = 'trg_audit_pelanggan';

SELECT
  has_table_privilege('app_portal', 'lab11.jejak_audit', 'INSERT') AS portal_insert,
  has_table_privilege('app_portal', 'lab11.jejak_audit', 'SELECT') AS portal_select,
  has_table_privilege('app_audit', 'lab11.jejak_audit', 'SELECT')  AS audit_select;
