# Deploy Django AYH to Vercel

This guide covers deploying the AYH Django app to Vercel (production) and how to run things like migrations and creating dummy donors.

---

## 1. Prerequisites

- **GitHub repo** with your code (e.g. `blood-450-main` with an `AYH` folder inside).
- **PostgreSQL database** for production (Vercel serverless does not use SQLite). Use one of:
  - [Supabase](https://supabase.com) (free tier) → Database → Connection string (URI)
  - [Neon](https://neon.tech) (free tier) → Connection string
  - Any other PostgreSQL host

The connection string looks like:
`postgres://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=require`

---

## 2. Vercel project setup

1. Go to [vercel.com](https://vercel.com) and sign in (GitHub).
2. **Add New** → **Project** → Import your Git repository.
3. **Root Directory**: set to **`AYH`** (so Vercel uses the folder that contains `manage.py`, `vercel.json`, and `requirements.txt`).
4. **Framework Preset**: leave as “Other” (no framework).
5. **Build and Output Settings** (optional; override if needed):
   - **Build Command:** `python manage.py collectstatic --noinput`
   - **Output Directory:** leave empty (Python serverless does not use it).
   - **Install Command:** `pip install -r requirements.txt` (often auto-detected).

---

## 3. Environment variables

In the Vercel project: **Settings → Environment Variables**. Add:

| Name | Value | Notes |
|------|--------|--------|
| `DATABASE_URL` | `postgres://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=require` | **Required** on Vercel (see settings.py). |
| `DJANGO_SECRET_KEY` | A long random string | Use a new secret for production. |
| `DJANGO_ENV` | `production` | So `IS_PRODUCTION` is True. |

Optional:

- `DJANGO_DEBUG` = `0` or leave unset (defaults to False in production).
- Any other keys your app reads (e.g. Twilio, etc.).

Then **Save** and **Redeploy** so the new env vars are used.

---

## 4. Deploy

- Push to your connected branch (e.g. `main`); Vercel will build and deploy.
- Or trigger a redeploy from the Vercel dashboard.

Your app will be at: `https://<your-project>.vercel.app`.

---

## 5. Run migrations (first time and after model changes)

Vercel runs your app as serverless; it does not run `manage.py` for you. Run migrations **once per deployment** (or when you change models) using one of these:

### Option A: Local with production DB (recommended)

Use the same `DATABASE_URL` as in Vercel and run from your machine (from the **AYH** folder):

```bash
cd AYH
set DATABASE_URL=postgres://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=require
python manage.py migrate
```

(On macOS/Linux use `export DATABASE_URL=...`.)

### Option B: Vercel CLI one-off

If you use Vercel CLI and have a way to run a one-off command (e.g. “Run command” in dashboard or a script that invokes `vercel env pull` and then `migrate`), you can run:

```bash
vercel env pull .env.local
python manage.py migrate
```

from the **AYH** directory after pulling env.

---

## 6. Create dummy donors in production

`create_dummy_donors.py` is meant to be run **locally** with the **production** `DATABASE_URL`:

1. In Vercel: **Settings → Environment Variables** → copy `DATABASE_URL` (or use **Vercel CLI**: `vercel env pull .env.local`).
2. From the **AYH** folder:

```bash
cd AYH
set DATABASE_URL=postgres://...   # same as in Vercel
python create_dummy_donors.py
```

Then enter the number of donors (1–500) when prompted. They will be created in the same PostgreSQL database that the deployed app uses.

Do **not** run this script on Vercel’s serverless runtime; run it on your machine (or a one-off job elsewhere) with `DATABASE_URL` set.

---

## 7. After deployment checklist

- [ ] **Root Directory** is `AYH`.
- [ ] **DATABASE_URL** is set and points to PostgreSQL.
- [ ] **DJANGO_SECRET_KEY** and **DJANGO_ENV=production** are set.
- [ ] Migrations have been run at least once against the production DB.
- [ ] If you use a custom domain, add it in Vercel and add that origin to `CSRF_TRUSTED_ORIGINS` and `ALLOWED_HOSTS` in `AYH/settings.py` (or via env if you add support for it).

---

## 8. Troubleshooting

- **“DATABASE_URL is missing”**  
  Add `DATABASE_URL` in Vercel Environment Variables and redeploy.

- **Static files 404**  
  Ensure Build Command runs `python manage.py collectstatic --noinput` and that WhiteNoise is in `MIDDLEWARE` (already in your settings).

- **CSRF / cookie errors**  
  Add your Vercel URL (e.g. `https://your-app.vercel.app`) to `CSRF_TRUSTED_ORIGINS` in `AYH/settings.py` (you already have `https://blood-450-96iv.vercel.app`).

- **Migrations not applied**  
  Run `python manage.py migrate` locally with `DATABASE_URL` set to your production DB.
