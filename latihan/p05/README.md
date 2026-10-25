# Latihan P05 — Dari Procedure sampai Endpoint

PL/pgSQL, tipe data, psycopg 3, connection pool, SQLAlchemy (N+1), dan FastAPI pada skema `lab5`.
Semua percobaan hanya mengubah skema `lab5`; skema `public` (data pagila) tidak diubah.

## Prasyarat

- Docker Desktop, dengan stack proyek aktif (`docker compose up -d`): service `postgres` (PostgreSQL 17), user `msbd`, database `pagila`
- Python 3.10 atau lebih baru (kelompok memakai 3.14)
- Git Bash (Windows); perintah dijalankan dari root repo `msbd-2026` kecuali disebut lain

## Lingkungan Python

```bash
python -m venv .venv
source .venv/Scripts/activate        # PowerShell: .venv\Scripts\Activate.ps1
pip install "psycopg[binary,pool]==3.2.*" "sqlalchemy==2.0.*" \
  "fastapi==0.115.*" "uvicorn==0.32.*" "pydantic==2.*"
```

## Variabel DSN

Semua program Python membaca koneksi dari variabel lingkungan `DSN`:

```
postgresql://msbd:<password>@localhost:5432/pagila
```

Agar password tidak diketik ulang (dan di-encode bila memuat karakter khusus), ambil dari kontainer:

```bash
PGPASS=$(docker compose exec -T postgres printenv POSTGRES_PASSWORD)
export DSN=$(python -c "import sys, urllib.parse as u; print('postgresql://msbd:' + u.quote(sys.argv[1], safe='') + '@localhost:5432/pagila')" "$PGPASS")
```

Variabel ini hilang saat terminal ditutup; ulangi di setiap terminal baru.

## Setup skema lab5

```bash
psqlf() { docker compose exec -T postgres psql -U msbd -d pagila -e < "$1"; }
psqlf latihan/p05/q00_setup.sql
for f in latihan/p05/q0[1-9]_*.sql; do psqlf "$f"; done
```

Urutan q01 → q09 penting: Q5 mengganti `lab5.process_rental`, Q7 menambah nilai enum `EXPIRED`.
Untuk mengulang dari awal, jalankan `q00_setup.sql` lagi.

## Menjalankan program Python

Dari folder `latihan/p05`, dengan venv aktif dan `DSN` sudah di-set:

```bash
python lab5_driver.py semua       # Q4, Q10-Q14
python q11_uji_injeksi.py         # Q11
python lab5_driver.py q15         # Q15: transaksi didiamkan 30 detik
python lab5_orm.py semua          # Q16-Q20: echo=True, jumlah SELECT dicetak di akhir tiap soal
uvicorn lab5_api:app --reload     # Q21-Q24: dokumentasi di http://localhost:8000/docs
```

Saat Q15 berjalan, amati dari terminal lain (di root repo):

```bash
docker compose exec -T postgres psql -U msbd -d pagila \
  -c "SELECT pid, state, xact_start, query FROM pg_stat_activity WHERE state LIKE 'idle in%';"
```

## Uji HTTP (Q22-Q24)

Jalankan di Git Bash saat `uvicorn` aktif.

```bash
# Q22: rental sah -> 201 {"rental_id": ...}
curl -s -X POST localhost:8000/rentals -H 'content-type: application/json' \
  -d '{"customer_id":1,"inventory_id":1,"staff_id":1,"amount":4.99}'

# Q23: amount negatif -> 422, tanpa SQL di respons
curl -s -i -X POST localhost:8000/rentals -H 'content-type: application/json' \
  -d '{"customer_id":1,"inventory_id":1,"staff_id":1,"amount":-4.99}'

# Q24: inventory tidak ada -> 409
curl -s -i -X POST localhost:8000/rentals -H 'content-type: application/json' \
  -d '{"customer_id":1,"inventory_id":999999,"staff_id":1,"amount":4.99}'
```

## Isi folder

| Berkas | Isi |
|---|---|
| `q00_setup.sql` | Skema `lab5`, enum `rental_status`, domain `positive_amount`, tabel `rental_tx` dan `payment_tx` |
| `q01_...sql` – `q09_...sql` | Q1–Q9: function, procedure, rollback, COMMIT dalam procedure, EXCEPTION, domain, enum, array, JSONB |
| `lab5_driver.py`, `q11_uji_injeksi.py` | Q4, Q10–Q15: parameter binding, injeksi, `sql.Identifier`, rollback dari aplikasi, pool, idle in transaction |
| `lab5_orm.py` | Q16–Q20: model deklaratif, N+1, `selectinload`, `joinedload`, ORM vs SQL mentah |
| `lab5_api.py` | Q21–Q24: dependency `get_conn`, `POST /rentals`, translasi galat 422/409 |
| `bukti/` | Keluaran asli setiap percobaan |
| `laporan.md` | Laporan kelompok, refleksi A–E, dan R1 |

## Troubleshooting

| Gejala | Tindakan |
|---|---|
| `password authentication failed for user "msbd"` | Set ulang `DSN` dengan dua baris di bagian Variabel DSN |
| `relation "public.customer" does not exist` | Database yang dipakai salah; harus `pagila`, bukan `latihan` |
| `procedure ... double precision does not exist` | Nilai uang dikirim sebagai float; pakai `Decimal("4.99")` |
| `bash: .venv/Scripts/activate: No such file` | Pembuatan venv terputus; `rm -rf .venv` lalu buat ulang dan tunggu sampai selesai |
| Path Windows (`C:\...`) tidak dikenali di Git Bash | Pakai garis miring biasa: `/c/msbd-2026/...` |
