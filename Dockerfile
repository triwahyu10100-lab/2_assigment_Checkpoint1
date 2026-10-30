# Image dasar Python yang ringan — cocok untuk aplikasi Flask tanpa
# kebutuhan OS-level khusus.
FROM python:3.13-slim

WORKDIR /app

# Supaya log langsung muncul (tidak dibuffer) dan tidak ada file .pyc
# yang ditulis ke image — tidak perlu untuk container sekali pakai.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_APP=run.py

# Copy requirements duluan supaya layer ini di-cache selama
# requirements.txt tidak berubah (build ulang jadi lebih cepat).
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy sisa source code aplikasi.
COPY . .

# Port yang didengarkan gunicorn di dalam container. Samakan dengan
# port yang diisi di dashboard Helipod saat membuat service ini.
EXPOSE 8000

# Jalankan migrasi Alembic (idempotent — aman dijalankan ulang setiap
# start/restart/scale karena Flask-Migrate skip migrasi yang sudah
# diterapkan) sebelum menyalakan server gunicorn yang sesungguhnya.
CMD ["sh", "-c", "flask db upgrade && gunicorn run:app --bind 0.0.0.0:8000"]
