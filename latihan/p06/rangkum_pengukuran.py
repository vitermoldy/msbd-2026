#!/usr/bin/env python3
# Diminta: melaporkan waktu tercepat dan median dari tiga kali uji beserta Buffers untuk setiap query.
# Dipilih: angka diambil ulang dari berkas explain/*.txt, bukan dicatat tangan, supaya tabel laporan tidak bisa menyimpang dari bukti.
# Alternatif: menyalin angka manual dari layar; tidak dipilih karena rawan salah salin dan tidak bisa diulang.
"""Merangkum explain/*.txt menjadi tabel Markdown.

Pakai:  python rangkum_pengukuran.py explain > hasil_pengukuran_terisi.md
"""
import re
import statistics
import sys
from pathlib import Path

RE_LABEL = re.compile(r"^=====\s*(.+?)\s*$")
RE_TIME = re.compile(r"Execution Time:\s*([\d.]+) ms")
RE_BUF = re.compile(r"Buffers: shared ([^\n]*)")
RE_NODE = re.compile(
    r"(Seq Scan|Index Only Scan|Index Scan Backward|Index Scan|"
    r"Bitmap Heap Scan|Bitmap Index Scan|BitmapAnd|Sort|Gather)"
    r"(?: using (\S+))?(?: on (\S+))?"
)


def buffers_total(teks):
    """Menjumlahkan hit dan read pada satu baris Buffers."""
    total = 0
    for bagian in teks.replace(",", " ").split():
        if "=" in bagian:
            nama, _, nilai = bagian.partition("=")
            if nama in ("hit", "read") and nilai.isdigit():
                total += int(nilai)
    return total


def baca(berkas):
    """Mengembalikan daftar (label, node, waktu_ms, buffers) per satu rencana."""
    hasil = []
    label = berkas.stem
    plan, isi = None, []
    for baris in berkas.read_text(errors="replace").splitlines():
        cocok = RE_LABEL.match(baris)
        if cocok:
            label = cocok.group(1)
            continue
        if "QUERY PLAN" in baris:
            plan, isi = label, []
            continue
        if plan is not None:
            isi.append(baris)
            if RE_TIME.search(baris):
                blok = "\n".join(isi)
                nama_node = "-"
                for kandidat in RE_NODE.finditer(blok):
                    nama_node = " ".join(x for x in (kandidat.group(1), kandidat.group(2)) if x)
                    if "Scan" in kandidat.group(1):
                        break
                buf = RE_BUF.search(blok)
                hasil.append((plan, nama_node,
                              float(RE_TIME.search(blok).group(1)),
                              buffers_total(buf.group(1)) if buf else 0))
                plan = None
    return hasil


def kunci(label):
    """Menghilangkan penanda 'run N' agar tiga pengulangan masuk satu kelompok."""
    return re.sub(r",?\s*run\s*\d+\s*$", "", label, flags=re.I).strip()


def main(folder):
    semua = {}
    for berkas in sorted(Path(folder).glob("*.txt")):
        for label, node, waktu, buf in baca(berkas):
            semua.setdefault((berkas.stem, kunci(label), node), []).append((waktu, buf))

    print("| Berkas | Query / keadaan | Node | n | Tercepat (ms) | Median (ms) | Buffers (hit+read) |")
    print("|---|---|---|---:|---:|---:|---:|")
    for (berkas, label, node), data in semua.items():
        waktu = [w for w, _ in data]
        buf = [b for _, b in data]
        print(f"| `{berkas}` | {label} | {node} | {len(waktu)} | "
              f"{min(waktu):.3f} | {statistics.median(waktu):.3f} | {max(buf)} |")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "explain")
