---
name: implementing-saaskit-python
description: Implements Scalekit SaaSKit authentication in Python web frameworks (Django, FastAPI, or Flask) using scalekit-sdk-python. Use when adding auth to a Django, FastAPI, or Flask project, or when the user mentions Python web authentication with Scalekit.
---

# SaaSKit Auth — Python

Implements Scalekit authentication in Django, FastAPI, or Flask using `scalekit-sdk-python`.

## Framework detection

Before generating code, detect which framework is in use:

1. Check for `django` in `requirements.txt` / `pyproject.toml` → Django
2. Check for `fastapi` → FastAPI
3. Check for `flask` → Flask
4. If unclear, ask the user.

## Quick setup

```bash
pip install scalekit-sdk-python python-dotenv
```

```python
import os
from dotenv import load_dotenv
from scalekit import ScalekitClient

load_dotenv()

sc = ScalekitClient(
    env_url=os.getenv("SCALEKIT_ENV_URL"),
    client_id=os.getenv("SCALEKIT_CLIENT_ID"),
    client_secret=os.getenv("SCALEKIT_CLIENT_SECRET"),
)
```

## Framework routing

Each framework has different patterns for routes, middleware, and session storage:

| Framework | Auth middleware | Session store | Reference |
|---|---|---|---|
| Django | Custom middleware class | Django sessions (DB/cache) | [django-reference.md](django-reference.md) |
| FastAPI | Dependency injection | Server-side or JWT | [fastapi-reference.md](fastapi-reference.md) |
| Flask | `@login_required` decorator | Flask-Session | [flask-reference.md](flask-reference.md) |

## Default workflow (FastAPI example)

```python
import os, secrets
from fastapi import FastAPI, Request, Response
from fastapi.responses import RedirectResponse
from dotenv import load_dotenv
from scalekit import ScalekitClient

load_dotenv()

app = FastAPI()
REDIRECT_URI = os.getenv("SCALEKIT_REDIRECT_URI", "http://localhost:8000/auth/callback")

sc = ScalekitClient(
    env_url=os.getenv("SCALEKIT_ENV_URL"),
    client_id=os.getenv("SCALEKIT_CLIENT_ID"),
    client_secret=os.getenv("SCALEKIT_CLIENT_SECRET"),
)

@app.get("/auth/login")
def login(response: Response):
    state = secrets.token_urlsafe(32)
    response = RedirectResponse(sc.get_authorization_url(REDIRECT_URI, {"state": state}))
    response.set_cookie("oauth_state", state, httponly=True, samesite="lax", secure=True)
    return response

@app.get("/auth/callback")
def callback(request: Request, code: str, state: str):
    stored = request.cookies.get("oauth_state")
    if not stored or stored != state:
        return Response("CSRF mismatch", status_code=403)
    result = sc.authenticate_with_code(code, REDIRECT_URI)
    # Store result.user and tokens in your session mechanism
    response = RedirectResponse("/dashboard")
    response.delete_cookie("oauth_state")
    return response

@app.get("/auth/logout")
def logout(request: Request):
    logout_url = sc.get_logout_url({"post_logout_redirect_uri": "http://localhost:8000"})
    # Clear your session here
    return RedirectResponse(logout_url)
```

If `authenticate_with_code` raises an exception, verify the redirect URI matches the dashboard exactly.

For Django and Flask patterns, see the framework-specific references linked in the table above.

## Deep reference

- Auth flows: [docs.scalekit.com/authenticate/fsa/quickstart](https://docs.scalekit.com/authenticate/fsa/quickstart/)
- Sessions: [docs.scalekit.com/authenticate/fsa/sessions](https://docs.scalekit.com/authenticate/fsa/sessions/)

## When to switch skills

- Use `implementing-saaskit` for the general (non-Python-specific) integration guide.
- Use `managing-saaskit-sessions` for advanced session handling.
- Use `implementing-access-control` for RBAC after auth is working.
