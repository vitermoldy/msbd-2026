# Laporan - Latihan Pertemuan 1 (MSBD) Kelompok 5

## Anggota Kelompok 5

```text
1. Viter Moldy Kesuma (251402079) - PM
2. Gideon Finsus Siburian (251402038)
3. Nadine Tantiara Hutagaol (251402050)
4. Rizky Cristian Fero Sihombing (251402056)
5. Siti Naifah Batubara (251402067)
```

---

## 1. Memasang dan Memverifikasi Docker

### 1.1 Keluaran `docker --version`

**Perintah:** `docker --version`

**Hasil:** `Docker version 29.7.2, build a7dcaa6`

### 1.2 Keluaran `docker compose version`

**Perintah:** `docker compose version`

**Hasil:** `Docker Compose version v5.4.0`

### 1.3 Keluaran `docker run --rm hello world`

**Perintah:** `docker run --rm hello world`

**Hasil:**

```text
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker client created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

### 1.4 Pertanyaan Pemahaman

#### 1. Apa yang dimaksud dengan Docker Image?

Docker Image merupakan blueprint atau template yang digunakan untuk membuat sebuah container yang berisi kode program, library, pengaturan dan berbagai komponen yang diperlukan agar aplikasi bisa berjalan atau dijalankan.

#### 2. Apa yang dimaksud dengan Container?

Container adalah tempat dijalankannya suatu aplikasi berdasarkan Docker Image.

#### 3. Apa fungsi Volume?

Volume berfungsi tempat penyimpanan data diluar Container secara permanen sekalipun Container dihentikan atau dibuat ulang.

---

## 2. Menyusun dan Menjalankan Docker Compose

### 2.1 Menjalankan Container

Sebelum environment dijalankan, buat folder dump dengan perintah : `mkdir -p dump`

Jalankan layanan dengan perintah : `docker compose up -d`

**Hasil perintah :**

```text
[+] up 3/3
 ✔️ Container msbd-mongo Started                                                                                                                                                                                                 0.6s
 ✔️ Container msbd-pg    Started                                                                                                                                                                                                 0.6s
 ✔️ Container msbd-redis Started
```

Mengecek status masing-masing container dengan perintah : `docker compose ps`

**Hasil perintah :**

```text
NAME         IMAGE            COMMAND                  SERVICE    CREATED       STATUS                   PORTS
msbd-mongo   mongo:8          "docker-entrypoint.s…"   mongo      9 hours ago   Up 2 minutes             0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
msbd-pg      postgres:17      "docker-entrypoint.s…"   postgres   9 hours ago   Up 2 minutes (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
msbd-redis   redis:7-alpine   "docker-entrypoint.s…"   redis      9 hours ago   Up 2 minutes             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
```

Ketiga Container berhasil dijalankan dengan PostgreSQL menunjukkan status `healthy`.

### 2.2 Mengecek Log PostgreSQL

**Perintah :** `docker compose logs postgres | tail -20`

**Hasil :**

```text
msbd-pg  | 2026-08-25 15:36:35.435 UTC [27] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.007 s, sync=0.003 s, total=0.026 s; sync files=2, longest=0.002 s, average=0.002 s; distance=0 kB, estimate=0 kB; lsn=0/195D3E8, redo lsn=0/195D3E8
msbd-pg  | 2026-08-25 15:36:35.442 UTC [1] LOG:  database system is ready to accept connections
msbd-pg  | 2026-08-25 15:36:44.421 UTC [40] FATAL:  database "msbd" does not exist
msbd-pg  | 2026-08-25 15:36:54.507 UTC [48] FATAL:  database "msbd" does not exist
msbd-pg  | 2026-08-25 15:37:04.648 UTC [56] FATAL:  database "msbd" does not exist
msbd-pg  | 2026-08-25 15:37:14.768 UTC [64] FATAL:  database "msbd" does not exist
msbd-pg  | 2026-08-25 15:37:24.870 UTC [72] FATAL:  database "msbd" does not exist
msbd-pg  | 2026-08-25 15:37:34.955 UTC [80] FATAL:  database "msbd" does not exist
msbd-pg  | 2026-08-25 15:37:45.082 UTC [88] FATAL:  database "msbd" does not exist
msbd-pg  | 2026-08-25 15:37:55.202 UTC [96] FATAL:  database "msbd" does not exist
msbd-pg  | 2026-08-25 15:38:05.989 UTC [152] FATAL:  database "msbd" does not exist
msbd-pg  | 2026-08-25 15:39:16.118 UTC [176] FATAL:  database "msbd" does not exist
```

FATAL: database "msbd" does not exist terjadi karena healthcheck postgres default mencoba terhubung dengan database msbd dan database yang dibuat dengan nama lain, tapi ini tidak berarti PostgreSQL gagal dijalankan.

### 2.3 Pertanyaan Wajib

#### 1. Apa yang terjadi jika bagian `volumes:` pada layanan PostgreSQL dihapus, kemudian container dihentikan menggunakan `docker compose down -v`?

```text
Jika menggunakan `docker compose down -v`, volume yang digunakan oleh PostgreSQL juga akan dihapus. Maka data yang sebelumnya telah tersimpan akan hilang. Saat Container dibuat lagi, PostgreSQL akan menggunakan kondisi penyimpanan yang baru.
```

#### 2. Mengapa pemetaan port ditulis `"5432:5432"` dan bukan cukup satu angka? Apa yang harus diubah apabila komputer Anda sudah memiliki PostgreSQL lain yang menggunakan port 5432?

```text
Angka pertama menunjukkan port pada laptop atau host dan angka kedua menunjukkan port PostgreSQL yang digunakan di dalam container.

Jika port 5432 pada laptop udah digunakan PostgreSQL lokal, maka port host akan diganti sehingga PostgreSQL dalam Container tetap menggunakan port 5432, tetapi dari laptop diakses dengan port lain.
```

#### 3. Apa fungsi blok `healthcheck`? Mengapa healthcheck penting ketika terdapat layanan lain yang bergantung pada basis data?

```text
`healthcheck` digunakan untuk mengecek apakah sebuah layanan atau aplikasi sudah siap digunakan. Hal ini sangat penting terutama saat layanan lain membutuhkan PostgreSQL, karena container yang sudah berjalan belum tentu database di dalamnya siap menerima koneksi.
```

#### 4. Menyimpan password langsung di dalam `docker-compose.yml` merupakan praktik yang kurang baik. Sebutkan satu cara yang lebih aman dan jelaskan mengapa hal tersebut penting ketika berkas masuk ke repositori Git.

```text
Jika menyimpan di dalam docker-compose.yml password yang ditulis langsung di dalam file dapat ikut tersimpan ketika file tersebut dipush ke repository Git. Sehingga cara yang lebih aman adalah menggunakan file .env untuk menyimpan informasi tersebut dan memasukkannya ke .gitignore agar tidak ikut dikirim ke repository.
```

---

## 3. Mengakses PostgreSQL melalui psql dan DBeaver

### 3.1 Mengakses PostgreSQL Menggunakan psql

PostgreSQL dijalankan melalui Container menggunakan perintah :

`docker compose exec postgres psql -U msbd -d latihan`

Setelah masuk dengan psql, coba gunakan beberapa perintah untuk melihat informasi database.

### 3.2 Mengecek Versi PostgreSQL

**Perintah :** `SELECT version();`

**Hasil :**

```text
                                                       version                                                        
----------------------------------------------------------------------------------------------------------------------
 PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(1 row)
```

### 3.3 Melihat Database, Tabel, Schema, User dan Mengecek Konfigurasi PostgreSQL

**Untuk melihat Database :**

```text
latihan=# \l
                                                 List of databases
   Name    | Owner | Encoding | Locale Provider |  Collate   |   Ctype    | Locale | ICU Rules | Access privileges 
-----------+-------+----------+-----------------+------------+------------+--------+-----------+-------------------
 latihan   | msbd  | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | 
 postgres  | msbd  | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | 
 template0 | msbd  | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/msbd          +
           |       |          |                 |            |            |        |           | msbd=CTc/msbd
 template1 | msbd  | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/msbd          +
           |       |          |                 |            |            |        |           | msbd=CTc/msbd
(4 rows)
```

**Untuk melihat Tabel :**

```text
latihan=# \dt
Did not find any relations.
```

**Untuk melihat Schema :**

```text
latihan=# \dn
      List of schemas
  Name  |       Owner       
--------+-------------------
 public | pg_database_owner
(1 row)
```

**Untuk melihat User atau Role :**

```text
latihan=# \du
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 msbd      | Superuser, Create role, Create DB, Replication, Bypass RLS
```

**Untuk melihat lokasi data PostgreSQL :**

```text
latihan=# SHOW data_directory;
      data_directory      
--------------------------
 /var/lib/postgresql/data
(1 row)
```

**Untuk melihat nilai `shared_buffers`:**

```text
latihan=# SHOW shared_buffers;
 shared_buffers 
----------------
 128MB
(1 row)
```

**Untuk mengaktifkan pengukuran waktu query :**

```text
latihan=# \timing on
Timing is on.
```

### 3.4 Menggunakan DBeaver

PostgreSQL juga dapat diakses menggunakan DBeaver. Konfigurasi koneksi yang digunakan yaitu dengan parameter `Host, Port, Database, dan Username`.

DBeaver lebih mudah digunakan ketika ingin melihat struktur database secara visual, sedangkan psql lebih praktis untuk menjalankan perintah langsung melalui terminal.

### 3.5 Perbandingan psql dan DBeaver

```text
lebih cepat dengan menggunakan psql dalam menjalankan query atau mengecek informasi database karena perintah bisa langsung diketik pada terminal.

DBeaver lebih nyaman digunakan untuk melihat struktur database, tabel, relasi dan ER Diagram karena tampilannya menggunakan antarmuka grafis.
```

---

## 4. Restore Database Pagila

### 4.1 Membuat Database Pagila

Database `pagila` dibuat menggunakan perintah :

`docker compose exec postgres createdb -U msbd pagila`

**Hasilnya :**

```text
                   List of relations
 Schema |       Name       |       Type        | Owner 
--------+------------------+-------------------+-------
 public | actor            | table             | msbd
 public | address          | table             | msbd
 public | category         | table             | msbd
 public | city             | table             | msbd
 public | country          | table             | msbd
 public | customer         | table             | msbd
 public | film             | table             | msbd
 public | film_actor       | table             | msbd
 public | film_category    | table             | msbd
 public | inventory        | table             | msbd
 public | language         | table             | msbd
 public | payment          | partitioned table | msbd
 public | payment_p2017_01 | table             | msbd
 public | payment_p2017_02 | table             | msbd
 public | payment_p2017_03 | table             | msbd
 public | payment_p2017_04 | table             | msbd
 public | payment_p2017_05 | table             | msbd
 public | payment_p2017_06 | table             | msbd
 public | rental           | table             | msbd
 public | staff            | table             | msbd
 public | store            | table             | msbd
(21 rows)
```

### 4.2 Melakukan Restore

File `pagila.dump` digunakan untuk mengisis database `pagila`.

**Perintah yang digunakan :**

`docker compose exec postgres pg_restore -U msbd -d pagila --no-owner /dump/pagila.dump`

### 4.3 Mengecek Tabel

Setelah proses restore selesai, tabel pada database diperiksa dengan :

`docker compose exec postgres psql -U msbd -d pagila -c "\dt"`

**Hasil :**

---

## 5. Query Verifikasi

### 5.1 V1 - Menghitung Jum

**Menggunakan Query :**

```batch
ELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';
```

Dari hasil query dapat diketahui bahwa terdapat[JUMLAH] tabel pada schema public.

### 5.2 V2 - Sepuluh Tabel Besar

**Query yang digunakan :**

```batch
SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS ukuran
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;
```

Query ini untuk melihat tabel yang menggunakan ruang penyimpanan paling besar. Hasilnya diurutkan dari tabel dengan ukuran terbesar sampai terkecil.

### 5.3 V3 - Lima Film dengan jumlah penyewaan terbanyak

**Query yang digunakan :**

```sql
SELECT f.title, count(*) AS total_sewa
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title
ORDER BY total_sewa DESC
LIMIT 5;
```

**Hasil :**

### 5.4 V4 - Melihat Rencana Eksekusi Query

**Query yang digunakan :**

```sql
EXPLAIN ANALYZE
SELECT f.title, count(*)
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title;
```

`Explain Analyze` digunakan untuk melihat bagaimana PostgreSQL menjalankan query, dari hasilnya dapat dilihat tahapan yang dilakukan PostgreSQL beserta waktu yang dibutuhkan dalam proses tersebut.

**Yang paling membingungkan dari keluaran ini adalah:**