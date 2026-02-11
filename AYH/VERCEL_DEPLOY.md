# Deploying to Vercel

## Required: Set Root Directory

In your Vercel project settings:

1. Go to **Settings** → **General** → **Root Directory**.
2. Set it to **`AYH`** (the Django project folder).
3. Save and redeploy.

This ensures `vercel.json` and `AYH/wsgi.py` are resolved correctly.

## Environment variables

In Vercel → **Settings** → **Environment Variables**, add:

- `DJANGO_SECRET_KEY` – a long random string (e.g. from [djecrety.ir](https://djecrety.ir/)).
- `DJANGO_DEBUG` – set to `False` for production.

## After deploy

Your app will be at `https://<your-project>.vercel.app`.  
Log in at `/accounts/login/` or `/home/`.

**Note:** SQLite (`db.sqlite3`) is not persistent on Vercel. For real data, use an external database (e.g. PostgreSQL on Supabase/Railway) and set `DATABASES` in `settings.py` from env vars.
