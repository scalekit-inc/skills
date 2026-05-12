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

## Default workflow

1. Set `SCALEKIT_ENV_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET` in `.env`.
2. Initialize `ScalekitClient` at module level.
3. Create a login route that redirects to `sc.get_authorization_url(redirect_uri, options)`.
4. Create a callback route that calls `sc.authenticate_with_code(code, redirect_uri)`.
5. Store tokens in the framework's session mechanism.
6. Create a logout route that clears the session and redirects to `sc.get_logout_url(options)`.

## Deep reference

- Auth flows: [docs.scalekit.com/authenticate/fsa/quickstart](https://docs.scalekit.com/authenticate/fsa/quickstart/)
- Sessions: [docs.scalekit.com/authenticate/fsa/sessions](https://docs.scalekit.com/authenticate/fsa/sessions/)

## When to switch skills

- Use `implementing-saaskit` for the general (non-Python-specific) integration guide.
- Use `managing-saaskit-sessions` for advanced session handling.
- Use `implementing-access-control` for RBAC after auth is working.
