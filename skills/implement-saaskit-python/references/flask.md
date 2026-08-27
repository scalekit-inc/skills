# SaaSKit Flask

Use this file when the repo is Flask. Do not run the FastAPI samples in `SKILL.md`.

Add hosted login, an encrypted `sk_session` cookie, logout, and refresh with `scalekit.frameworks.flask.ScalekitAuth`. Then stop.

## Guardrails
- **MUST** keep `redirect_uri` identical to the dashboard Redirect URI.
- **MUST** pass the Flask `app` into `ScalekitAuth` (or call `init_app`) so `/login`, `/callback`, and `/logout` exist.
- **MUST** set `cookie_secure=False` on local HTTP. **MUST** set it `True` in production.
- **MUST** treat `returnTo` as a relative path only. The adapter already sanitizes it.

## Gotchas
- Install `"scalekit-sdk-python[flask]"` only. Do not add Django or FastAPI packages.
- Env names: `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, `SCALEKIT_REDIRECT_URI`, `COOKIE_ENCRYPTION_SECRET`. Never `SCALEKIT_ENV_URL`. Do not prepend `https://`.
- First constructor arg is `app`. Keyword args follow: `env_url=`, `client_id=`, `client_secret=`.
- Adapter defaults: GET `/login`, `/callback`, `/logout`. Cookie is `sk_session` (HttpOnly, SameSite=Lax). CSRF is `sk_oauth_state`.
- If `SCALEKIT_REDIRECT_URI` already ends in `/auth/callback`, pass `callback_path="/auth/callback"` or change both the env and the dashboard to `/callback`.
- `@auth.requires_auth` refreshes. Do not add `/auth/refresh`. Do not copy Express cookies from `manage-saaskit-sessions`.
- `auth.current_user` is access-token claims. `sub` is always present.
- Local defaults: callback `http://localhost:5001/callback`, Initiate Login `http://localhost:5001/login`, Post Logout `http://localhost:5001/`.

## Step 1 — Install

```bash
pip install "scalekit-sdk-python[flask]"
```

**Done when:** the Flask extra is installed.

## Step 2 — Init

```python
# app.py
import os
from flask import Flask
from scalekit.frameworks.flask import ScalekitAuth

app = Flask(__name__)
auth = ScalekitAuth(
    app,
    env_url=os.environ["SCALEKIT_ENVIRONMENT_URL"],
    client_id=os.environ["SCALEKIT_CLIENT_ID"],
    client_secret=os.environ["SCALEKIT_CLIENT_SECRET"],
    redirect_uri=os.environ["SCALEKIT_REDIRECT_URI"],
    cookie_encryption_secret=os.environ["COOKIE_ENCRYPTION_SECRET"],
    cookie_secure=False,  # set True behind HTTPS
)
```

Generate `COOKIE_ENCRYPTION_SECRET` with `openssl rand -base64 32`. Keep it identical on every server.

**Done when:** `ScalekitAuth` reads those env vars and the Flask app is passed in.

## Step 3 — Login, callback, logout

The constructor registers GET `/login`, GET `/callback`, and GET `/logout`. Do not write those routes by hand.

Link to `/login` and `/logout`. `/callback` compares `sk_oauth_state` to `state` before `authenticate_with_code`. `full_logout` defaults to True (`id_token_hint` + `post_logout_redirect_uri`).

**Done when:** `/login` redirects to Scalekit, `/callback` writes `sk_session`, and `/logout` clears it.

## Step 4 — Protect views

```python
@app.route("/account")
@auth.requires_auth
def account():
    return {"sub": auth.current_user["sub"]}
```

Decorator order: `@app.route` then `@auth.requires_auth` (the auth decorator is closest to the function). Verify with GET `/account`. Missing session → 302 `/login?returnTo=…`, never JSON 401.

**Done when:** a missing cookie on GET `/account` 302s to `/login`, and an expired-but-refreshable session stays signed in.

## Step 5 — Stop

**Done when:** login, callback, `sk_session`, logout, and refresh are in Flask, and this file has stopped.

## Live lookups
- Flask: https://docs.scalekit.com/saaskit/sdks/flask/
- Docs index: https://docs.scalekit.com/llms.txt
