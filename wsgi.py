# Entrypoint khusus untuk Vercel's Python runtime (Vercel Functions).
# Vercel mencari instance Flask bernama `app` di file dengan nama baku
# seperti wsgi.py / app.py / main.py / index.py / server.py / asgi.py —
# run.py tidak termasuk daftar itu, jadi file ini dibuat sebagai jembatan.
#
# Deployment lain (Render via Procfile/render.yaml, Helipod via
# Dockerfile) tetap memakai run:app seperti biasa dan tidak terpengaruh
# oleh file ini.
from app import create_app

app = create_app()
