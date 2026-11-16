# Diminta: tempat menjalankan rentan.py di dalam jaringan tertutup.
# Dipilih: psycopg dipasang pada tahap build, karena jaringan labnet bertanda
#          internal sehingga pip tidak punya jalan keluar saat kontainer jalan.
# Alternatif: pip install saat kontainer start; tidak dipilih karena pasti gagal
#             pada jaringan internal dan menyesatkan saat ditiru anggota lain.
FROM python:3.12-slim
RUN pip install --no-cache-dir "psycopg[binary]==3.2.3"
WORKDIR /app
CMD ["sleep", "infinity"]
