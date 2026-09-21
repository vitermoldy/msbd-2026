# Diminta: memetakan Customer-Rental dengan SQLAlchemy 2.0, membuktikan N+1, lalu memperbaikinya (Q16-Q20).
# Dipilih: gaya deklaratif Mapped/mapped_column, echo=True + penghitung statement via event, selectinload & joinedload.
# Alternatif: lazy loading default tanpa pengukuran; tidak dipilih karena N+1 tidak terlihat sampai data membesar.
"""Cara pakai:  python lab5_orm.py q17   (atau q18, q19, q20, semua)"""
import os
import statistics
import sys
import time
from contextlib import contextmanager
from datetime import datetime

from sqlalchemy import ForeignKey, create_engine, desc, event, func, select, text
from sqlalchemy.orm import (DeclarativeBase, Mapped, Session, joinedload,
                            mapped_column, relationship, selectinload)

DSN = os.environ.get("DSN", "postgresql://postgres:postgres@localhost:5432/dvdrental")
URL = DSN.replace("postgresql://", "postgresql+psycopg://", 1)  # pakai driver psycopg 3

engine = create_engine(URL, echo=True)


# ---------------------------------------------------------------- Q16 model deklaratif
class Base(DeclarativeBase):
    pass


class Customer(Base):
    __tablename__ = "customer"
    __table_args__ = {"schema": "public"}

    customer_id: Mapped[int] = mapped_column(primary_key=True)
    first_name: Mapped[str]
    last_name: Mapped[str]
    email: Mapped[str | None]

    rentals: Mapped[list["Rental"]] = relationship(back_populates="customer")


class Film(Base):
    __tablename__ = "film"
    __table_args__ = {"schema": "public"}

    film_id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str]


class Inventory(Base):
    __tablename__ = "inventory"
    __table_args__ = {"schema": "public"}

    inventory_id: Mapped[int] = mapped_column(primary_key=True)
    film_id: Mapped[int] = mapped_column(ForeignKey("public.film.film_id"))

    film: Mapped[Film] = relationship()


class Rental(Base):
    __tablename__ = "rental"
    __table_args__ = {"schema": "public"}

    rental_id: Mapped[int] = mapped_column(primary_key=True)
    rental_date: Mapped[datetime]
    return_date: Mapped[datetime | None]
    customer_id: Mapped[int] = mapped_column(ForeignKey("public.customer.customer_id"))
    inventory_id: Mapped[int] = mapped_column(ForeignKey("public.inventory.inventory_id"))

    customer: Mapped[Customer] = relationship(back_populates="rentals")
    inventory: Mapped[Inventory] = relationship()


# ---------------------------------------------------------------- penghitung statement
_jumlah = {"n": 0}


@event.listens_for(engine, "before_cursor_execute")
def _hitung(conn, cursor, statement, parameters, context, executemany):
    if statement.lstrip().upper().startswith("SELECT"):
        _jumlah["n"] += 1


@contextmanager
def hitung_select(label):
    _jumlah["n"] = 0
    yield
    print(f"\n>>> {label}: {_jumlah['n']} statement SELECT\n")


def judul(t):
    print(f"\n{'=' * 20} {t} {'=' * 20}")


# ---------------------------------------------------------------- Q17 N+1
def q17():
    judul("Q17 - lazy loading (N+1)")
    with Session(engine) as session, hitung_select("Q17"):
        rows = session.scalars(select(Customer).order_by(Customer.customer_id).limit(10)).all()
        print([(c.customer_id, len(c.rentals)) for c in rows])  # tiap c.rentals memicu 1 SELECT


# ---------------------------------------------------------------- Q18 selectinload
def q18():
    judul("Q18 - selectinload")
    with Session(engine) as session, hitung_select("Q18"):
        rows = session.scalars(
            select(Customer).options(selectinload(Customer.rentals))
            .order_by(Customer.customer_id).limit(10)
        ).all()
        print([(c.customer_id, len(c.rentals)) for c in rows])


# ---------------------------------------------------------------- Q19 joinedload
def q19():
    judul("Q19 - joinedload")
    with Session(engine) as session, hitung_select("Q19"):
        rows = session.scalars(
            select(Customer).options(joinedload(Customer.rentals))
            .order_by(Customer.customer_id).limit(10)
        ).unique().all()  # unique() wajib: JOIN menggandakan baris customer
        print([(c.customer_id, len(c.rentals)) for c in rows])


# ---------------------------------------------------------------- Q20 ORM vs SQL mentah
SQL_MENTAH = text("""
    SELECT f.title, count(r.rental_id) AS jumlah_sewa
    FROM public.rental r
    JOIN public.inventory i ON i.inventory_id = r.inventory_id
    JOIN public.film f      ON f.film_id = i.film_id
    GROUP BY f.film_id, f.title
    ORDER BY jumlah_sewa DESC, f.title
    LIMIT 5
""")


def top5_orm(session):
    jumlah = func.count(Rental.rental_id).label("jumlah_sewa")
    stmt = (
        select(Film.title, jumlah)
        .join(Inventory, Inventory.film_id == Film.film_id)
        .join(Rental, Rental.inventory_id == Inventory.inventory_id)
        .group_by(Film.film_id, Film.title)
        .order_by(desc(jumlah), Film.title)
        .limit(5)
    )
    return session.execute(stmt).all()


def top5_mentah(session):
    return session.execute(SQL_MENTAH).all()


def ukur(fungsi, ulang=30):
    waktu = []
    with Session(engine) as session:
        fungsi(session)  # pemanasan
        for _ in range(ulang):
            t0 = time.perf_counter()
            fungsi(session)
            waktu.append((time.perf_counter() - t0) * 1000)
    return statistics.median(waktu), min(waktu), max(waktu)


def q20():
    judul("Q20 - lima film tersewa terbanyak")
    with Session(engine) as session:
        hasil_orm = top5_orm(session)
        hasil_mentah = top5_mentah(session)
    print("ORM   :", hasil_orm)
    print("Mentah:", hasil_mentah)
    print("Hasil sama:", [tuple(r) for r in hasil_orm] == [tuple(r) for r in hasil_mentah])

    engine.echo = False  # log dimatikan saat mengukur waktu
    for nama, fn in [("ORM", top5_orm), ("SQL mentah", top5_mentah)]:
        med, mn, mx = ukur(fn)
        print(f"{nama:<10}: median {med:.2f} ms (min {mn:.2f}, maks {mx:.2f}) dari 30 kali")
    engine.echo = True


SOAL = {"q17": q17, "q18": q18, "q19": q19, "q20": q20}

if __name__ == "__main__":
    pilihan = sys.argv[1:] or ["semua"]
    if pilihan == ["semua"]:
        pilihan = list(SOAL)
    for p in pilihan:
        SOAL[p]()
