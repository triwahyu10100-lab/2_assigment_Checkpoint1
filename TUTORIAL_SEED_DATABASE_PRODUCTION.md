# Tutorial: Membuat Tabel & Mengisi Data Awal di Database Production

Dokumen ini menjelaskan cara menjalankan `schema.sql` dan `seed.sql`
(dari `1_checkpoint_revoshop_sql/`) langsung ke database production
(Neon, Render, Helipod, atau provider Postgres apa pun), tanpa perlu
masuk ke terminal/shell platform hosting-nya.

## Kenapa perlu langkah manual ini?

Migrasi Alembic di `migrations/versions/` **tidak membuat tabel dari
nol** — isinya cuma `ALTER TABLE` untuk kolom-kolom tambahan
(`username`, `role`, `slug`, dll). Tabel dasarnya (`users`,
`categories`, `products`, `orders`, `order_items`) didefinisikan di
`1_checkpoint_revoshop_sql/schema.sql` dari Checkpoint 1.

Jadi urutan setup database baru yang kosong total **wajib**:

1. Jalankan `schema.sql` → membuat 5 tabel + index
2. Jalankan `flask db upgrade` → menambahkan kolom-kolom dari migrasi
   (`username`, `role`, `slug`, `images`, dll)
3. (Opsional) Jalankan `seed.sql` → mengisi data contoh

Kalau langkah 1 dilewati, `flask db upgrade` di langkah 2 akan gagal
dengan error `relation "users" does not exist`, karena migrasi pertama
mencoba `ALTER TABLE users` padahal tabelnya belum ada.

## Prasyarat

- **`psql`** terinstall di komputer kamu (client PostgreSQL). Cek
  dengan:
  ```powershell
  psql --version
  ```
  Kalau belum ada, install lewat [postgresql.org/download](https://www.postgresql.org/download/)
  (pilih "Command Line Tools" saja kalau tidak perlu server penuh).
- **Connection string** database production kamu, formatnya:
  ```
  postgresql://<user>:<password>@<host>/<database>?sslmode=require
  ```
  Didapat dari dashboard provider database kamu (Neon, Render, Helipod,
  dll — biasanya ada tombol "Connect" yang menampilkan string ini).

> ⚠️ **Jangan commit atau share connection string ini ke tempat
> publik** — isinya password asli ke database kamu.

## Langkah 1 — Jalankan `schema.sql`

Dari folder `backend/`, jalankan:

```powershell
psql "postgresql://<user>:<password>@<host>/<database>?sslmode=require" -f "1_checkpoint_revoshop_sql\schema.sql"
```

Ganti connection string sesuai punya kamu. Output yang diharapkan:

```
DROP TABLE   (atau NOTICE: ... does not exist, skipping — wajar kalau tabelnya belum ada)
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
```

> ⚠️ **Perhatian:** `schema.sql` punya `DROP TABLE ... CASCADE` di
> bagian atas. Kalau dijalankan ulang di database yang **sudah ada
> datanya**, semua data lama akan **terhapus permanen**. Hanya
> jalankan ini di database yang benar-benar baru/kosong, atau kalau
> memang sengaja mau reset total.

## Langkah 2 — Jalankan migrasi Alembic

Ini dilakukan otomatis oleh `Dockerfile` (`flask db upgrade` jalan
duluan sebelum `gunicorn` start) kalau kamu deploy pakai Docker/Render
/Helipod. Kalau mau jalankan manual dari komputer sendiri (misal
`DATABASE_URL` di `.env` sudah diarahkan ke production sementara):

```powershell
$env:FLASK_APP = 'run.py'
flask db upgrade
```

Ini menambahkan kolom `username`, `role`, `slug`, `images`,
`updated_at`, `deleted_at`, `address` ke tabel yang sudah dibuat di
Langkah 1.

## Langkah 3 — Jalankan `seed.sql` (data contoh)

```powershell
psql "postgresql://<user>:<password>@<host>/<database>?sslmode=require" -f "1_checkpoint_revoshop_sql\seed.sql"
```

Output yang diharapkan:

```
INSERT 0 6     -- 6 users
INSERT 0 5     -- 5 categories
INSERT 0 10    -- 10 products
INSERT 0 6     -- 6 orders
INSERT 0 12    -- 12 order_items
```

`seed.sql` cuma berisi `INSERT`, aman dijalankan ke tabel yang sudah
ada isinya — tapi kalau dijalankan dua kali, bisa gagal karena
melanggar constraint UNIQUE (misal `email` atau `sku` yang sudah
dipakai baris sebelumnya).

## Langkah 4 — Verifikasi

Buka URL backend production kamu di browser atau lewat PowerShell:

```powershell
Invoke-WebRequest -Uri "https://<url-backend-kamu>/products" -UseBasicParsing | Select-Object -ExpandProperty Content
```

Harus muncul JSON berisi `items` dengan 10 produk dan field
`pagination.total_items: 10`.

## Troubleshooting

| Error | Sebab | Solusi |
|---|---|---|
| `relation "users" does not exist` saat `flask db upgrade` | `schema.sql` belum dijalankan | Jalankan Langkah 1 dulu |
| `duplicate key value violates unique constraint` saat `seed.sql` | `seed.sql` sudah pernah dijalankan sebelumnya | Jangan jalankan dua kali, atau kosongkan tabel dulu (`schema.sql` ulang — akan hapus semua data) |
| `invalid connection option "channel_binding"` | Driver Postgres lama tidak kenal parameter ini (umum di Neon) | Hapus `&channel_binding=require` dari connection string, sisakan `?sslmode=require` saja |
| `psql: command not found` | `psql` belum terinstall | Install PostgreSQL command line tools |
