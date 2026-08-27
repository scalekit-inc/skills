# SaaSKit Django

Use this file when the repo is Django. Do not run the FastAPI samples in `SKILL.md`.

Add hosted login, an encrypted `sk_session` cookie, logout, and refresh with `scalekit.frameworks.django`. Then stop.

## Guardrails
- **MUST** keep `SCALEKIT_REDIRECT_URI` identical to the dashboard Redirect URI.
- **MUST** add `ScalekitAuthMiddleware` before any view that uses `request.scalekit_user`.
- **MUST** decorate protected views with `@login_required` from `scalekit.frameworks.django`. Middleware does not redirect.
- **MUST** set `SCALEKIT_COOKIE_SECURE = False` on local HTTP. **MUST** set it `True` in production.

## Gotchas
- Install `"scalekit-sdk-python[django]"` only. Do not add FastAPI or Flask packages.
- Env names: `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, `SCALEKIT_REDIRECT_URI`, `COOKIE_ENCRYPTION_SECRET`. Never `SCALEKIT_ENV_URL` as an env name. Do not prepend `https://`.
- Django setting `SCALEKIT_ENV_URL` reads the env `SCALEKIT_ENVIRONMENT_URL`. That setting name is required by the adapter.
- There is no `ScalekitAuth` instance. Settings plus `include("scalekit.frameworks.django")` register GET `/login`, `/callback`, `/logout` with **no trailing slash**.
- Cookie is `sk_session` (HttpOnly, SameSite=Lax). CSRF is `sk_oauth_state`. `returnTo` is a relative path only.
- `request.scalekit_user` is access-token claims, or `None`. `sub` is always present when signed in.
- Middleware refreshes. Do not add `/auth/refresh`. Do not copy Express cookies from `manage-saaskit-sessions`.
- Import `login_required` from `scalekit.frameworks.django`, not `django.contrib.auth`.
- Local defaults: callback `http://localhost:8000/callback`, Initiate Login `http://localhost:8000/login`, Post Logout `http://localhost:8000/`. The include hard-codes those three paths. If `SCALEKIT_REDIRECT_URI` already ends in `/auth/callback`, change the env and the dashboard to `/callback`.

## Step 1 — Install

```bash
pip install "scalekit-sdk-python[django]"
```

**Done when:** the Django extra is installed.

## Step 2 — Settings

```python
# settings.py
import os

MIDDLEWARE = [
    # ... Django defaults ...
    "scalekit.frameworks.django.ScalekitAuthMiddleware",
]

SCALEKIT_ENV_URL = os.environ["SCALEKIT_ENVIRONMENT_URL"]
SCALEKIT_CLIENT_ID = os.environ["SCALEKIT_CLIENT_ID"]
SCALEKIT_CLIENT_SECRET = os.environ["SCALEKIT_CLIENT_SECRET"]
SCALEKIT_REDIRECT_URI = os.environ["SCALEKIT_REDIRECT_URI"]
SCALEKIT_COOKIE_ENCRYPTION_SECRET = os.environ["COOKIE_ENCRYPTION_SECRET"]
SCALEKIT_COOKIE_SECURE = False  # set True behind HTTPS
```

Generate `COOKIE_ENCRYPTION_SECRET` with `openssl rand -base64 32`. Keep it identical on every server.

**Done when:** those settings exist and `ScalekitAuthMiddleware` is in `MIDDLEWARE`.

## Step 3 — URLs, login, callback, logout

```python
# urls.py
from django.urls import include, path
from . import views

urlpatterns = [
    path("", include("scalekit.frameworks.django")),
    path("account", views.account),
]
```

Paths have no trailing slash. Link to `/login` and `/logout`. Do not write those views by hand.

**Done when:** GET `/login` redirects to Scalekit, GET `/callback` writes `sk_session`, and GET `/logout` clears it.

## Step 4 — Protect views

```python
# views.py
from django.http import JsonResponse
from scalekit.frameworks.django import login_required

@login_required
def account(request):
    return JsonResponse({"sub": request.scalekit_user["sub"]})
```

Verify with GET `/account`. Missing session → 302 `/login?returnTo=…`, never JSON 401.

**Done when:** a missing cookie on GET `/account` 302s to `/login`, and an expired-but-refreshable session stays signed in.

## Step 5 — Stop

**Done when:** login, callback, `sk_session`, logout, and refresh are in Django, and this file has stopped.

## Live lookups
- Django: https://docs.scalekit.com/saaskit/sdks/django/
- Docs index: https://docs.scalekit.com/llms.txt
