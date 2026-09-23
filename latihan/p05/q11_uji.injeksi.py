import psycopg

DSN = "dbname=postgres user=postgres password=postgres host=localhost port=5432"

def main():
    payload = "SMITH' OR '1'='1"

    f_string_sql = f"SELECT * FROM public.customer WHERE last_name = '{payload}'"
    print("SQL hasil f-string (rentan injeksi):")
    print(f_string_sql)
    print("-" * 50)


    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM public.customer WHERE last_name = %s", (payload,))
            results = cur.fetchall()
            print("Hasil eksekusi versi berparameter:")
            print(results)

if __name__ == "__main__":
    main()
