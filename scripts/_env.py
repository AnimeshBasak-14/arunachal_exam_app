"""Loads the project's gitignored .env so scripts never hardcode keys."""
import json
import os
import urllib.error
import urllib.request

_ENV_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')


def load_env(path=_ENV_PATH):
    if not os.path.exists(path):
        return
    with open(path, encoding='utf-8-sig') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            key, value = line.split('=', 1)
            os.environ.setdefault(key.strip(), value.strip())


_admin_token = None


def supabase_apikey():
    """Value for the `apikey` header: service-role key if set, else the publishable key."""
    load_env()
    key = os.environ.get('SUPABASE_SERVICE_KEY') or os.environ.get('SUPABASE_KEY')
    if not key:
        raise SystemExit('Set SUPABASE_KEY in .env')
    return key


def supabase_key():
    """
    Token for the `Authorization: Bearer` header.

    1. SUPABASE_SERVICE_KEY, if set (bypasses RLS).
    2. Otherwise signs in as SUPABASE_ADMIN_EMAIL / SUPABASE_ADMIN_PASSWORD and
       uses that admin session (writes allowed by RLS via public.admin_users).
       Sessions last about an hour; rerun the script for longer imports.
    3. Otherwise the publishable key (read-only).
    """
    global _admin_token
    load_env()
    if os.environ.get('SUPABASE_SERVICE_KEY'):
        return os.environ['SUPABASE_SERVICE_KEY']
    email = os.environ.get('SUPABASE_ADMIN_EMAIL')
    password = os.environ.get('SUPABASE_ADMIN_PASSWORD')
    if email and password:
        if _admin_token is None:
            req = urllib.request.Request(
                f"{os.environ['SUPABASE_URL']}/auth/v1/token?grant_type=password",
                data=json.dumps({'email': email, 'password': password}).encode(),
                headers={'apikey': supabase_apikey(), 'Content-Type': 'application/json'})
            try:
                with urllib.request.urlopen(req, timeout=20) as res:
                    _admin_token = json.loads(res.read())['access_token']
            except urllib.error.HTTPError as e:
                raise SystemExit(f'Admin sign-in failed (HTTP {e.code}). Check SUPABASE_ADMIN_* in .env')
            print(f'[auth] Signed in to Supabase as admin {email}')
        return _admin_token
    print('[auth] No SUPABASE_SERVICE_KEY or SUPABASE_ADMIN_* in .env: read-only mode')
    return supabase_apikey()
