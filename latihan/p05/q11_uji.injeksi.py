import psycopg

DSN = "dbname=postgres user=postgres password=postgres host=localhost port=5432"

def main():
    payload = "SMITH' OR '1'='1"

    # 1. Cetak hasil query f-string (HANYA DICETAK, JANGAN DIEKSEKUSI)
    f_string_sql = f"SELECT * FROM public.customer WHERE last_name = '{payload}'"
    print("SQL hasil f-string (rentan injeksi):")
    print(f_string_sql)
    print("-" * 50)

    # 2. Jalankan versi berparameter dengan payload yang sama
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM public.customer WHERE last_name = %s", (payload,))
            results = cur.fetchall()
            print("Hasil eksekusi versi berparameter:")
            print(results)  # Hasilnya akan [] (kosong) karena payload dianggap sebagai string biasa

if __name__ == "__main__":
    main()
