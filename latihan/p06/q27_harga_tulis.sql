-- Diminta: membandingkan INSERT 200000 baris pada tabel tanpa index dan pada tabel dengan lima index, lalu menyatakan selisihnya dalam persen.
-- Dipilih: dua tabel dengan struktur kolom identik dan data sumber yang sama, diukur dengan clock_timestamp di dalam satu blok agar angkanya ikut tercetak pada keluaran berkas.
-- Alternatif: mengandalkan \timing saja; tidak dipilih karena angkanya tidak ikut tersimpan sebagai baris hasil dan sulit dimasukkan ke tabel laporan.
\timing on
DROP TABLE IF EXISTS lab6.tulis_tanpa_index, lab6.tulis_lima_index;
CREATE TABLE lab6.tulis_tanpa_index (LIKE lab6.event_log EXCLUDING ALL);
CREATE TABLE lab6.tulis_lima_index  (LIKE lab6.event_log EXCLUDING ALL);

-- Lima index yang mewakili kelima jenis yang diuji latihan ini
CREATE INDEX tulis_btree_idx  ON lab6.tulis_lima_index (customer_id, terjadi_pada DESC);
CREATE INDEX tulis_partial_idx ON lab6.tulis_lima_index (terjadi_pada DESC) WHERE status='GAGAL';
CREATE INDEX tulis_ekspresi_idx ON lab6.tulis_lima_index (lower(email));
CREATE INDEX tulis_gin_idx     ON lab6.tulis_lima_index USING gin (payload jsonb_path_ops);
CREATE INDEX tulis_brin_idx    ON lab6.tulis_lima_index USING brin (terjadi_pada) WITH (pages_per_range=128);

DO $$
DECLARE t0 timestamptz; tanpa_ms numeric; lima_ms numeric;
BEGIN
  t0 := clock_timestamp();
  INSERT INTO lab6.tulis_tanpa_index
  SELECT * FROM lab6.event_log WHERE event_id <= 200000;
  tanpa_ms := round(extract(epoch FROM clock_timestamp()-t0)*1000, 1);

  t0 := clock_timestamp();
  INSERT INTO lab6.tulis_lima_index
  SELECT * FROM lab6.event_log WHERE event_id <= 200000;
  lima_ms := round(extract(epoch FROM clock_timestamp()-t0)*1000, 1);

  RAISE NOTICE 'INSERT 200000 baris tanpa index      : % ms', tanpa_ms;
  RAISE NOTICE 'INSERT 200000 baris dengan 5 index   : % ms', lima_ms;
  RAISE NOTICE 'selisih                              : % ms (% persen lebih lambat)',
        round(lima_ms-tanpa_ms,1), round(100.0*(lima_ms-tanpa_ms)/tanpa_ms, 1);
END $$;

-- Pengulangan kedua dan ketiga, sesuai aturan tiga kali uji
DO $$
DECLARE i int; t0 timestamptz; tanpa_ms numeric; lima_ms numeric;
BEGIN
  FOR i IN 2..3 LOOP
    TRUNCATE lab6.tulis_tanpa_index; TRUNCATE lab6.tulis_lima_index;  -- TRUNCATE, bukan DELETE, agar ruang kembali dan ukuran Q28 tetap adil
    t0 := clock_timestamp();
    INSERT INTO lab6.tulis_tanpa_index SELECT * FROM lab6.event_log WHERE event_id <= 200000;
    tanpa_ms := round(extract(epoch FROM clock_timestamp()-t0)*1000, 1);
    t0 := clock_timestamp();
    INSERT INTO lab6.tulis_lima_index SELECT * FROM lab6.event_log WHERE event_id <= 200000;
    lima_ms := round(extract(epoch FROM clock_timestamp()-t0)*1000, 1);
    RAISE NOTICE 'ulangan %: tanpa index % ms | lima index % ms | % persen lebih lambat',
          i, tanpa_ms, lima_ms, round(100.0*(lima_ms-tanpa_ms)/tanpa_ms, 1);
  END LOOP;
END $$;
