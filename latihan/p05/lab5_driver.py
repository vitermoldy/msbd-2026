import time
from psycopg import sql, connect
from psycopg_pool import ConnectionPool

DSN = "dbname=postgres user=postgres password=postgres host=localhost port=5432"

def main():
    print("=== Q10: SELECT Berparameter ===")
    with connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT customer_id, first_name, last_name FROM public.customer WHERE customer_id = %s;",
                (1,)
            )
            print("Hasil Q10:", cur.fetchone())

    print("\n=== Q12: Identifier dan Allow-List ===")
    input_column = "first_name"
    ALLOWED_COLUMNS = {"first_name", "last_name", "customer_id"}

    if input_column not in ALLOWED_COLUMNS:
        raise ValueError("Kolom tidak diizinkan!")

    query = sql.SQL("SELECT customer_id, first_name FROM public.customer ORDER BY {} LIMIT 3").format(
        sql.Identifier(input_column)
    )

    with connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            print("Hasil Q12:", cur.fetchall())

    print("\n=== Q13: Rollback dari Aplikasi ===")
    with connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM lab5.rental_tx;")
            print(f"Jumlah baris sebelum: {cur.fetchone()[0]}")

    try:
        with connect(DSN) as conn:
            conn.execute("CALL lab5.process_rental(%s, %s, %s, %s)", (1, 1, 1, 4.99))
            raise RuntimeError("gagal di tengah alur")
    except RuntimeError as e:
        print("Exception tertangkap:", e)

    with connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM lab5.rental_tx;")
            print(f"Jumlah baris sesudah: {cur.fetchone()[0]}")

    print("\n=== Q14: ConnectionPool ===")
    pool = ConnectionPool(conninfo=DSN, min_size=2, max_size=2)
    pool.wait()

    for i in range(5):
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1;")

    print("Keluaran pool.get_stats():", pool.get_stats())
    pool.close()

    print("\n=== Q15: Idle in Transaction ===")
    print("Membuka transaksi dan diam selama 10 detik...")

    conn_idle = connect(DSN)
    cur_idle = conn_idle.cursor()
    cur_idle.execute("SELECT 1;")

    time.sleep(10)

    conn_idle.close()
    print("Transaksi Selesai.")

if __name__ == "__main__":
    main()
