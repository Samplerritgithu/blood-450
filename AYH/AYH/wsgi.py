"""
WSGI config for AYH project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/
"""

import os
import sys

# Ensure Django project root is on Python path (needed when running on Vercel serverless)
_wsgi_dir = os.path.dirname(os.path.abspath(__file__))
_project_root = os.path.dirname(_wsgi_dir)  # parent of AYH package = project root
if _project_root not in sys.path:
    sys.path.insert(0, _project_root)

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'AYH.settings')

application = get_wsgi_application()

# On Vercel (Postgres or SQLite /tmp), run migrations on cold start (idempotent).
if os.environ.get('DATABASE_URL') or os.environ.get('SQLITE_DB_PATH') == '/tmp/db.sqlite3' or os.environ.get('VERCEL'):
    from django.core.management import call_command
    call_command('migrate', '--noinput')

# Vercel's Python runtime expects a module-level variable named `app`
# that is a WSGI callable. Alias `application` to `app` for that.
app = application
