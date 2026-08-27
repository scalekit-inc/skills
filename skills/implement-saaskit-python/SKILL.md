---
name: implement-saaskit-python
description: >
  Implements SaaSKit login in Django, FastAPI, or Flask
  so an agent can add login, callback, session cookies,
  and logout.
  Use when the user wants SaaSKit Django, FastAPI, or Flask
  auth.
  It does not write Node or Next.js login
  (that's `implement-saaskit` or `implement-saaskit-nextjs`).
---

# Implement SaaSKit Python
Add login, callback, an encrypted `sk_session` cookie, logout, and refresh in FastAPI. Then stop.

## Guardrails
- **MUST** keep `SCALEKIT_REDIRECT_URI`, the dashboard Redirect URI, and the process host:port the same string.
- **MUST** call `auth.install(app)`. `app.include_router(auth.router)` alone skips the 302 handler.
- **MUST** set `cookie_secure=False` on local HTTP. **MUST** set it `True` in production.
- **MUST** treat `returnTo` as a relative path only (`/...`, not `//…`). The adapter already sanitizes it.

## Gotchas
- `setup-saaskit` already wrote env and registered the redirect. Start there.
- Read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, and `SCALEKIT_REDIRECT_URI`. Never `SCALEKIT_ENV_URL`. Do not prepend `https://`.
- Also need `COOKIE_ENCRYPTION_SECRET` (`openssl rand -base64 32`). Keep it identical on every server.
- Default path is FastAPI `ScalekitAuth`. Do not hand-roll `ScalekitClient` routes. Do not copy Express cookies from `manage-saaskit-sessions`.
- Adapter defaults: GET `/login`, `/callback`, `/logout`. Cookie is `sk_session` (HttpOnly, SameSite=lax). CSRF cookie is `sk_oauth_state`.
- If `SCALEKIT_REDIRECT_URI` already ends in `/auth/callback`, pass `callback_path="/auth/callback"` or change both the env and the dashboard to `/callback`. Keep that URI's host and port. Run the app on that port. Do not keep port 3000 in env and run FastAPI on 5001.
- `user` from `requires_auth` is access-token claims. `sub` is always present.
- `requires_auth` refreshes. Do not add `/auth/refresh`. Do not return a `Response` from a protected endpoint — that drops the refreshed cookie.
- Register the Initiate Login URL and the Post Logout Redirect URI too.

## Step 1 — Pick the path

- FastAPI → stay here.
- Django → open [references/django.md](references/django.md). Stop reading this file.
- Flask → open [references/flask.md](references/flask.md). Stop reading this file.
- Node or Express → name `implement-saaskit`. Stop.
- Next.js App Router → name `implement-saaskit-nextjs`. Stop.

If env is missing, collect the four Scalekit values from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Register `SCALEKIT_REDIRECT_URI` under Authentication → Redirect URLs → Allowed callback URLs. Use one origin for that URI, the dashboard, and the process. Do not mix setup's `localhost:3000` with adapter samples on `localhost:5001`. Also register that origin's `/login` as Initiate Login URL and `/` as Post Logout Redirect URI. Generate `COOKIE_ENCRYPTION_SECRET`. Do not invent credential values.

**Done when:** this skill is the right path, the four Scalekit env names exist, and `COOKIE_ENCRYPTION_SECRET` exists.

## Step 2 — Install and init

Install `"scalekit-sdk-python[fastapi]"` only when the repo has no Scalekit FastAPI extra yet. Do not add Django or Flask packages.

```python
# app.py
import os
from fastapi import Depends, FastAPI
from scalekit.frameworks.fastapi import ScalekitAuth

app = FastAPI()
auth = ScalekitAuth(
    env_url=os.environ["SCALEKIT_ENVIRONMENT_URL"],
    client_id=os.environ["SCALEKIT_CLIENT_ID"],
    client_secret=os.environ["SCALEKIT_CLIENT_SECRET"],
    redirect_uri=os.environ["SCALEKIT_REDIRECT_URI"],
    cookie_encryption_secret=os.environ["COOKIE_ENCRYPTION_SECRET"],
    cookie_secure=False,  # set True behind HTTPS
)
auth.install(app)
```

`cookie_secure` defaults to `True` in the SDK. Browsers drop a Secure cookie on plain `http://localhost`.

**Done when:** the extra is installed, `ScalekitAuth` reads those env vars, and `auth.install(app)` has run.

## Step 3 — Login, callback, session

`auth.install` registers GET `/login`, GET `/callback`, and GET `/logout`. Do not write those routes by hand.

- `/login` sets `sk_oauth_state`, requests `openid profile email offline_access`, and redirects to Scalekit.
- `/callback` compares `sk_oauth_state` to `state` before `authenticate_with_code`. Mismatch → 302 `/login`. Success writes encrypted `sk_session` and deletes the state cookie.
- `returnTo` is a relative path only.

Link to `/login`. Do not send the browser to Scalekit yourself.

**Done when:** `/login` redirects to Scalekit, `/callback` writes `sk_session`, and the browser leaves `/callback`.

## Step 4 — Logout

GET `/logout`. Link to `/logout`. `full_logout` defaults to True: `get_logout_url` with `id_token_hint` and `post_logout_redirect_uri`, then delete `sk_session`.

Register that same origin as a Post Logout Redirect URI.

**Done when:** `sk_session` is gone and the browser hits the logout URL.

## Step 5 — Protect routes

`requires_auth` is the caller for refresh. It checks `sk_session`, refreshes when `expires_at` is near, and 302s to `/login?returnTo=…` when the session is missing. Never a JSON 401.

```python
@app.get("/account")
async def account(user: dict = Depends(auth.requires_auth)):
    return {"sub": user["sub"]}
```

Return a plain value, not a `Response`. Verify with GET `/account`.

**Done when:** a missing cookie on GET `/account` 302s to `/login`, and an expired-but-refreshable session stays signed in.

## Step 6 — Stop

Do not write Express `cookie-parser` middleware or Next.js App Router auth.

**Done when:** login, callback, `sk_session`, logout, and refresh are in FastAPI, and this skill has stopped.

## Reach for
- `setup-saaskit` if env or the redirect URI is missing
- `implement-saaskit` for Node or Express
- `implement-saaskit-nextjs` for Next.js App Router
- [references/django.md](references/django.md) for Django
- [references/flask.md](references/flask.md) for Flask

## Live lookups
- Docs index: https://docs.scalekit.com/llms.txt
- FastAPI: https://docs.scalekit.com/saaskit/sdks/fastapi/
- Auth flow: https://docs.scalekit.com/authenticate/fsa/quickstart/
- MCP: https://mcp.scalekit.com
