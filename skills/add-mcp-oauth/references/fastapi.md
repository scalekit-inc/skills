# FastAPI + FastMCP

Use this file when the repo is FastAPI. Do not run the Express samples in `SKILL.md`.

Put OAuth 2.1 on the user's FastAPI MCP server. Then stop.

## Guardrails

- **MUST** keep `/.well-known/oauth-protected-resource` public.
- **MUST** return 401 with `WWW-Authenticate` and `resource_metadata` on a missing or invalid token.
- **MUST** mount the FastMCP app last.

## Gotchas

- Env names: `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`. Never `SCALEKIT_ENV_URL` or `SK_ENV_URL`.
- Constructor arg is `env_url`. Env name is still `SCALEKIT_ENVIRONMENT_URL`. Do not prepend `https://`.
- Audience must match the dashboard Server URL exactly, including a trailing slash when the dashboard has one.
- Paste the dashboard Metadata JSON. Do not build `authorization_servers` by adding a scheme onto the env URL.
- `validate_access_token` returns `False` on a bad token. It does not throw.

## Step 1 — Install

Install only what the repo is missing. Later steps import all of these:

```bash
pip install scalekit-sdk-python fastapi fastmcp uvicorn python-dotenv
```

**Done when:** those packages are installed.

## Step 2 — Register (user action)

Same dashboard checklist as `SKILL.md` Step 3. Local Server URL default is `http://localhost:3002/` (keep the trailing slash). Wait for Metadata JSON and the Server URL.

**Done when:** Metadata JSON is copied and the Server URL is recorded.

## Step 3 — Well-known, middleware, mount

Put imports at the top of the file.

```python
import os
from fastapi import FastAPI, Request, Response
from fastmcp import FastMCP
from scalekit import ScalekitClient
from scalekit.common.scalekit import TokenValidationOptions
from dotenv import load_dotenv

load_dotenv()

audience = "http://localhost:3002/"  # dashboard Server URL
metadata_url = f"{audience.rstrip('/')}/.well-known/oauth-protected-resource"
www_header = {
    "WWW-Authenticate": f'Bearer realm="OAuth", resource_metadata="{metadata_url}"'
}
metadata = {}  # paste dashboard Metadata JSON

scalekit_client = ScalekitClient(
    env_url=os.environ["SCALEKIT_ENVIRONMENT_URL"],
    client_id=os.environ["SCALEKIT_CLIENT_ID"],
    client_secret=os.environ["SCALEKIT_CLIENT_SECRET"],
)

mcp = FastMCP("mcp-server", stateless_http=True)
mcp_app = mcp.http_app(path="/")
app = FastAPI(lifespan=mcp_app.lifespan)

@app.get("/.well-known/oauth-protected-resource")
async def oauth_metadata():
    return metadata

@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    if request.url.path.startswith("/.well-known"):
        return await call_next(request)
    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        return Response(status_code=401, headers=www_header)
    token = auth_header.split("Bearer ", 1)[1].strip()
    options = TokenValidationOptions(
        issuer=os.environ["SCALEKIT_ENVIRONMENT_URL"],
        audience=[audience],
    )
    if not scalekit_client.validate_access_token(token, options=options):
        return Response(status_code=401, headers=www_header)
    return await call_next(request)

app.mount("/", mcp_app)
```

Keep the user's tools. Mount FastMCP last.

**Done when:** well-known is public, middleware calls `validate_access_token` with audience, and FastMCP is mounted last.

## Step 4 — Optional scopes

```python
options = TokenValidationOptions(
    issuer=os.environ["SCALEKIT_ENVIRONMENT_URL"],
    audience=[audience],
    required_scopes=["todo:write"],
)
if not scalekit_client.validate_access_token(token, options=options):
    return Response(
        '{"error":"insufficient_scope"}',
        status_code=403,
        media_type="application/json",
    )
```

**Done when:** scopes are skipped, or a tool checks `required_scopes`.

## Step 5 — Verify

```bash
curl -i http://localhost:3002/
curl -i http://localhost:3002/.well-known/oauth-protected-resource
```

Expect 401 + `WWW-Authenticate` with `resource_metadata` on the MCP route. Expect JSON with `resource`, `authorization_servers`, and `scopes_supported` on the well-known route.

**Done when:** both curls pass.

## Live lookups

- FastAPI: https://docs.scalekit.com/authenticate/mcp/fastapi-fastmcp-quickstart/
- Docs index: https://docs.scalekit.com/llms.txt
- Example: https://github.com/scalekit-inc/mcp-auth-demos/tree/main/greeting-mcp-python
