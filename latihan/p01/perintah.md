# Perintah — Latihan Pertemuan 1 (MSBD)

## Langkah 1 — Verifikasi Docker

```bash
docker --version
docker compose version
docker run --rm hello-world
```

Output:

```
PS C:\Users\USER> docker --version
Docker version 29.7.2, build a7dcaa6

PS C:\Users\USER> docker compose version
Docker Compose version v5.4.0

PS C:\Users\USER> docker run --rm hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
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

## Langkah 2 — Docker Compose

Berkas `docker-compose.yml` dibuat sesuai konfigurasi pada modul (postgres:17, mongo:8, redis:7-alpine).

```bash
mkdir -p dump
docker compose up -d
docker compose ps
docker compose logs postgres | tail -20
```

Output `docker compose ps`:

```
PS C:\Users\USER> docker compose ps
NAME         IMAGE            COMMAND                  SERVICE    CREATED       STATUS                 PORTS
msbd-mongo   mongo:8          "docker-entrypoint.s…"   mongo      9 hours ago   Up 9 hours             0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
msbd-pg      postgres:17      "docker-entrypoint.s…"   postgres   9 hours ago   Up 9 hours (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
msbd-redis   redis:7-alpine   "docker-entrypoint.s…"   redis      9 hours ago   Up 9 hours             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
```

Output `docker compose logs postgres | tail -20`:

```
PS C:\Users\USER> docker compose logs postgres | Select-Object -Last 20
msbd-pg  |
msbd-pg  | PostgreSQL Database directory appears to contain a database; Skipping initialization
msbd-pg  |
msbd-pg  | 2026-08-25 04:04:29.565 UTC [1] LOG:  starting PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
msbd-pg  | 2026-08-25 04:04:29.566 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
msbd-pg  | 2026-08-25 04:04:29.566 UTC [1] LOG:  listening on IPv6 address "::", port 5432
msbd-pg  | 2026-08-25 04:04:29.573 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
msbd-pg  | 2026-08-25 04:04:29.582 UTC [29] LOG:  database system was shut down at 2026-08-25 04:03:19 UTC
msbd-pg  | 2026-08-25 04:04:29.591 UTC [1] LOG:  database system is ready to accept connections
```

## Langkah 3 — Akses PostgreSQL via psql

```bash
docker compose exec postgres psql -U msbd -d latihan
```

Perintah yang dijalankan di dalam psql:

```sql
SELECT version();
\l
\dt
\dn
\du
SHOW data_directory;
SHOW shared_buffers;
\timing on
\q
```

Output `SELECT version();`:

```
PS C:\Users\USER> docker compose exec postgres psql -U msbd -d latihan
psql (17.11 (Debian 17.11-1.pgdg13+2))
Type "help" for help.

latihan=# SELECT version();
\l
                                                       version
----------------------------------------------------------------------------------------------------------------------
 PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(1 row)

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

latihan=# \dt
Did not find any relations.
latihan=# \dn
      List of schemas
  Name  |       Owner
--------+-------------------
 public | pg_database_owner
(1 row)

latihan=# \du
                             List of roles
 Role name |                         Attributes
-----------+------------------------------------------------------------
 msbd      | Superuser, Create role, Create DB, Replication, Bypass RLS

latihan=# SHOW data_directory;
      data_directory
--------------------------
 /var/lib/postgresql/data
(1 row)

latihan=# SHOW shared_buffers;
 shared_buffers
----------------
 128MB
(1 row)

latihan=# \timing on
Timing is on.
latihan=# \q
```

## Langkah 3 — Akses PostgreSQL via DBeaver

Koneksi dibuat dengan:

- Host: localhost
- Port: 5432
- Database: latihan
- Username: msbd

## Langkah 4 — Restore Pagila

```bash
docker compose exec postgres createdb -U msbd pagila
docker compose exec postgres pg_restore -U msbd -d pagila --no-owner /dump/pagila.dump
docker compose exec postgres psql -U msbd -d pagila -c "\dt"
```

Output `\dt` (ringkas — jumlah tabel):

```
PS C:\Users\USER> docker compose exec postgres psql -U msbd -d pagila -c "\dt"
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

## Langkah 5 — Inisialisasi Repositori Git

```bash
git init
printf 'dump/\n*.dump\n.env\n.DS_Store\n' > .gitignore
git add .
git commit -m "chore: menyiapkan lingkungan MSBD"
git branch -M main
git remote add origin <URL repositori tim>
git push -u origin main
```

Output `git log --oneline`:

```

```

URL repositori tim: `https://github.com/vitermoldy/msbd-2026/tree/main/latihan/p01`
