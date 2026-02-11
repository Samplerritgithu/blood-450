"""
WSGI config for AYH project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'AYH.settings')

application = get_wsgi_application()

# Vercel's Python runtime expects a module-level variable named `app`
# that is a WSGI callable. Alias `application` to `app` for that.
app = application
