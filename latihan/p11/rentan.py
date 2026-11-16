#!/usr/bin/env python3
# Diminta: skrip pencarian pelanggan yang rentan injection, sebagai bahan
#          percobaan Q12-Q16, beserta versi yang sudah diperbaiki.
# Dipilih: satu berkas memuat tiga jalur sekaligus -- cari_rentan (merangkai
#          SQL dari string), cari_aman (nilai lewat parameter), dan daftar
#          putih untuk pengurutan -- supaya ketiganya dibandingkan pada data
#          dan peran yang sama persis.
# Alternatif: tiga berkas terpisah; tidak dipilih karena perbedaan kecil pada
#             koneksi atau penyewa akan membuat perbandingannya tidak sah.
"""
Pemakaian di dalam kontainer lab11-web:

    python rentan.py "Pelanggan 12"              # jalur rentan (Q12, Q13)
    python rentan.py --aman "zz' OR '1'='1' --"  # jalur berparameter (Q15)
    python rentan.py --urut kota --arah turun "Pelanggan 12"   # Q16
    python rentan.py --urut nik  --arah turun "Pelanggan 12"   # Q16, ditolak

Peran dan penyewa diatur lewat environment, supaya Q14 hanya mengganti peran
tanpa mengubah satu baris kode:

    LAB11_USER=app_laporan LAB11_PASSWORD=lab11-laporan python rentan.py "..."
"""
import os
import sys

import psycopg

# ---------------------------------------------------------------------
# Daftar putih tertutup untuk bagian query yang TIDAK BISA diparameterkan.
# Nama kolom dan arah urut bukan nilai, melainkan bagian dari kalimat SQL,
# jadi satu-satunya pengaman adalah memetakan masukan ke nilai yang sudah
# kita tulis sendiri. Lihat Q16.
# ---------------------------------------------------------------------
KOLOM = {"nama": "nama", "kota": "kota", "terbaru": "dibuat_pada"}
ARAH = {"naik": "ASC", "turun": "DESC"}


def sambung():
    """Satu koneksi, penyewa disetel per transaksi dan bukan per koneksi."""
    return psycopg.connect(
        host=os.environ.get("PGHOST", "lab11-db"),
        dbname=os.environ.get("PGDATABASE", "msbd"),
        user=os.environ.get("LAB11_USER", "app_portal"),
        password=os.environ.get("LAB11_PASSWORD", "lab11-portal"),
    )


def pasang_penyewa(cur, tenant):
    """
    set_config(..., true) -- parameter ketiga true berarti is_local: nilainya
    hilang begitu transaksi berakhir. Inilah pola yang mencegah konteks
    penyewa tertinggal di kolam koneksi (Q10).
    """
    cur.execute("SELECT set_config('app.tenant', %s, true)", (str(tenant),))


def cari_rentan(kata, tenant, kolom="nama", arah="naik"):
    """
    SALAH, dan memang disengaja. Masukan pengguna disambung menjadi bagian
    kalimat SQL, sehingga ia ikut menyusun kodenya, bukan hanya mengisi nilai.
    """
    sql = (
        "SELECT id, nama, kota FROM lab11.pelanggan "
        f"WHERE tenant_id = {tenant} AND nama ILIKE '%{kata}%' "
        f"ORDER BY {KOLOM[kolom]} {ARAH[arah]}"
    )
    print("--- SQL yang benar-benar dikirim ke server ---")
    print(sql)
    print("--- bagian dari masukan pengguna: " + repr(kata) + " ---")
    with sambung() as conn, conn.cursor() as cur:
        pasang_penyewa(cur, tenant)
        cur.execute(sql)
        return cur.fetchall()


def cari_aman(kata, tenant, kolom="nama", arah="naik"):
    """
    BENAR. Nilai dikirim lewat saluran yang berbeda dari teks query, jadi
    isinya tidak pernah menjadi kode. Nama kolom dan arah urut tidak bisa
    diparameterkan, sehingga keduanya lewat daftar putih di atas.
    """
    if kolom not in KOLOM or arah not in ARAH:
        raise ValueError("parameter pengurutan tidak dikenal")
    sql = (
        "SELECT id, nama, kota FROM lab11.pelanggan "
        "WHERE tenant_id = %s AND nama ILIKE %s "
        f"ORDER BY {KOLOM[kolom]} {ARAH[arah]}"
    )
    print("--- SQL yang benar-benar dikirim ke server ---")
    print(sql)
    print("--- nilai dikirim terpisah: " + repr((tenant, f"%{kata}%")) + " ---")
    with sambung() as conn, conn.cursor() as cur:
        pasang_penyewa(cur, tenant)
        cur.execute(sql, (tenant, f"%{kata}%"))
        return cur.fetchall()


def main(argv):
    aman = False
    kolom, arah = "nama", "naik"
    kata = None

    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--aman":
            aman = True
        elif a == "--urut":
            i += 1
            kolom = argv[i]
        elif a == "--arah":
            i += 1
            arah = argv[i]
        else:
            kata = a
        i += 1

    if kata is None:
        print(__doc__)
        return 2

    tenant = int(os.environ.get("LAB11_TENANT", "1"))
    peran = os.environ.get("LAB11_USER", "app_portal")
    print(f"peran koneksi: {peran} | penyewa: {tenant} | jalur: "
          f"{'cari_aman (berparameter)' if aman else 'cari_rentan (sambung string)'}")

    fungsi = cari_aman if aman else cari_rentan
    try:
        baris = fungsi(kata, tenant, kolom, arah)
    except ValueError as e:
        print(f"DITOLAK DAFTAR PUTIH: {e}")
        return 1
    except KeyError as e:
        print(f"DITOLAK DAFTAR PUTIH (jalur rentan): kolom/arah {e} tidak ada")
        return 1
    except psycopg.Error as e:
        print(f"GALAT SQL {e.sqlstate}: {e}")
        return 1

    print(f"=== jumlah baris: {len(baris)} ===")
    for b in baris[:5]:
        print("   ", b)
    if len(baris) > 5:
        print(f"    ... dan {len(baris) - 5} baris lain")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
