# lab5_api.py
# Diminta: endpoint POST /rentals yang memanggil procedure lab5.process_rental,
#          menolak amount negatif dengan 422 (bukan 500), dan menerjemahkan
#          pelanggaran foreign key (inventory_id tidak ada) menjadi 409 tanpa
#          membocorkan pesan SQL mentah ke klien.
# Dipilih: FastAPI dependency `get_conn` bergaya with-yield yang meminjam
#          koneksi dari ConnectionPool (pola sama seperti Q14), validasi
#          `amount` lewat Pydantic Field(gt=0) supaya nilai negatif ditolak
#          SEBELUM menyentuh basis data sama sekali (menghasilkan 422 otomatis
#          dari FastAPI), dan blok except yang menangkap
#          psycopg.errors.ForeignKeyViolation secara spesifik untuk 409.
# Alternatif: mengandalkan domain lab5.positive_amount di basis data sebagai
#          satu-satunya penjaga nilai amount, tanpa Field(gt=0) di Pydantic.
#          Tidak dipilih karena soal eksplisit minta 422 (galat validasi
#          klien) untuk amount negatif — pelanggaran CHECK/domain di database
#          adalah kelas galat yang berbeda dan baru diketahui setelah round-trip
#          ke database, sehingga lebih lambat dan secara semantik bukan 422.
#
# Catatan implementasi (berdasarkan isi q02/q05 yang sebenarnya):
# - lab5.process_rental punya parameter INOUT p_rental_id -- saat dipanggil
#   lewat CALL, PostgreSQL langsung mengembalikan satu baris berisi nilai
#   INOUT tersebut, diambil dengan cur.fetchone() setelah execute().
# - Validasi p_amount <= 0 di dalam process_rental memakai
#   RAISE EXCEPTION ... USING ERRCODE = '22003' (numeric_value_out_of_range),
#   BUKAN pelanggaran domain (CheckViolation/23514) -- karena pengecekan itu
#   terjadi sebelum INSERT ke payment_tx, domain lab5.positive_amount tidak
#   pernah sempat dievaluasi lewat jalur ini. Exception class yang ditangkap
#   di Python harus NumericValueOutOfRange, bukan CheckViolation.
# - Endpoint ini SENGAJA memanggil process_rental (versi polos dari Q2),
#   bukan process_rental_fk (versi Q5). process_rental_fk menangkap
#   foreign_key_violation lalu RAISE EXCEPTION ulang tanpa
#   USING ERRCODE = 'foreign_key_violation', sehingga SQLSTATE aslinya
#   (23503) berubah jadi P0001 generik -- endpoint jadi tidak bisa lagi
#   membedakan galat FK dari galat lain. Ini justru jawaban dari
#   Reflektif Q5: menangkap galat terlalu dini (di dalam procedure)
#   menghilangkan informasi yang dibutuhkan lapisan di atasnya.

import os
from contextlib import asynccontextmanager
from decimal import Decimal

import psycopg
from psycopg_pool import ConnectionPool
from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field

# Sesuaikan dengan DSN yang dipakai di lab5_driver.py / lab5_orm.py kalian.
# Kredensial ini mengikuti environment yang sudah dipakai sejak Latihan 1
# (user msbd, bukan postgres) — bukan tebakan baru.
DSN = os.environ.get(
    "DSN", "postgresql://msbd:msbd2026@localhost:5432/pagila"
)

pool: ConnectionPool | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool
    pool = ConnectionPool(DSN, min_size=1, max_size=5, open=True)
    yield
    pool.close()


app = FastAPI(lifespan=lifespan)


# ---------------------------------------------------------------------------
# Q21 — Dependency koneksi bergaya with-yield, meminjam dari ConnectionPool
# ---------------------------------------------------------------------------
def get_conn():
    with pool.connection() as conn:
        yield conn


# ---------------------------------------------------------------------------
# Skema request/response
# ---------------------------------------------------------------------------
class RentalRequest(BaseModel):
    customer_id: int
    inventory_id: int
    staff_id: int
    amount: Decimal = Field(gt=0)


class RentalResponse(BaseModel):
    rental_id: int


# ---------------------------------------------------------------------------
# Q22, Q23, Q24 — POST /rentals dan translasi galat
# ---------------------------------------------------------------------------
@app.post("/rentals", response_model=RentalResponse, status_code=201)
def create_rental(
    payload: RentalRequest,
    conn: psycopg.Connection = Depends(get_conn),
):
    try:
        with conn.cursor() as cur:
            # process_rental punya INOUT p_rental_id -- CALL dengan
            # procedure ber-OUT/INOUT parameter mengembalikan satu baris
            # berisi nilai parameter tersebut, sama seperti hasil SELECT.
            cur.execute(
                "CALL lab5.process_rental(%s, %s, %s, %s)",
                (
                    payload.customer_id,
                    payload.inventory_id,
                    payload.staff_id,
                    payload.amount,
                ),
            )
            rental_id = cur.fetchone()[0]
        conn.commit()
        return RentalResponse(rental_id=rental_id)

    except psycopg.errors.ForeignKeyViolation:
        # Q24: inventory_id (atau customer_id/staff_id) tidak ada.
        # 409 Conflict: permintaan valid secara bentuk, tapi bertentangan
        # dengan keadaan data saat ini. Pesan ke klien TIDAK menyertakan
        # nama tabel, nama constraint, atau teks SQL apa pun.
        conn.rollback()
        raise HTTPException(
            status_code=409,
            detail="Referensi customer, inventory, atau staff tidak ditemukan.",
        )

    except psycopg.errors.NumericValueOutOfRange:
        # Jalur nyata untuk amount <= 0 di process_rental (RAISE EXCEPTION
        # ... USING ERRCODE = '22003'). Seharusnya sudah dicegat
        # Field(gt=0) di Pydantic sebelum sampai sini -- ini jaring
        # pengaman kedua, bukan jalur utama.
        conn.rollback()
        raise HTTPException(
            status_code=422,
            detail="Nilai amount tidak memenuhi aturan basis data.",
        )

    except psycopg.errors.CheckViolation:
        # Jaring pengaman ketiga: kalau suatu saat pengecekan manual di
        # process_rental dihapus, domain lab5.positive_amount pada
        # payment_tx.amount tetap menolak nilai tidak sah.
        conn.rollback()
        raise HTTPException(
            status_code=422,
            detail="Nilai amount tidak memenuhi aturan basis data.",
        )

    except psycopg.Error:
        # Fallback umum: SATU-SATUNYA tempat error database "tidak dikenal"
        # ditangani. Klien tidak pernah melihat pesan asli psycopg/Postgres.
        conn.rollback()
        raise HTTPException(
            status_code=500,
            detail="Terjadi kesalahan pada server.",
        )
