# Hasil Pengukuran P06

## Kondisi uji

| Hal | Nilai |
|---|---|
| Versi PostgreSQL | «SELECT version();» |
| Mesin | «CPU, RAM, jenis disk mesin yang mengukur» |
| `max_parallel_workers_per_gather` | 0 (disetel di setiap berkas ukur) |
| `shared_buffers` | «SHOW shared_buffers;» |
| `random_page_cost` | 4 (bawaan), diubah sementara menjadi 1.1 hanya pada Q24 |
| Jumlah pengulangan | 3 kali per query |
| Jumlah baris `lab6.event_log` | «SELECT count(*) FROM lab6.event_log;» |

## Waktu dan Buffers

Tabel di bawah ini dihasilkan ulang dari `explain/*.txt`, bukan dicatat tangan:

```bash
python latihan/p06/rangkum_pengukuran.py latihan/p06/explain
```

«tempel keluaran skrip di sini»

## Ukuran index

| Index | Definisi | Ukuran | Persen dari heap | Sumber angka |
|---|---|---:|---:|---|
| | | | | `explain/q30_rekomendasi_index.txt` |

## Harga tulis (Q27–Q28)

| Keadaan | Ulangan 1 | Ulangan 2 | Ulangan 3 | Ukuran total |
|---|---:|---:|---:|---:|
| Tanpa index | | | | |
| Lima index | | | | |
| Selisih (persen) | | | | |

## Tabel keputusan (Q29–Q30)

| Query/index | Tercepat | Median | Buffers | Ukuran | Keputusan |
|---|---:|---:|---:|---:|---|
| | | | | | |
