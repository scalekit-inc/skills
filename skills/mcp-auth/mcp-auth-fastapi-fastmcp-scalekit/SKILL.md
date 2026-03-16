---
name: mcp-auth-fastapi-fastmcp-scalekit
description: "Add Scalekit OAuth authentication to a FastAPI + FastMCP server (Python). Use when you need FastAPI-level middleware control over token validation alongside FastMCP tools. Implements /.well-known/oauth-protected-resource, a Starlette middleware that validates Authorization Bearer tokens via Scalekit SDK (issuer + audience), and mounts FastMCP via app.mount."
compatibility: Python 3.11+. FastAPI, FastMCP, Uvicorn, scalekit-sdk-python. Requires SK_ENV_URL, SK_CLIENT_ID, SK_CLIENT_SECRET, EXPECTED_AUDIENCE, and PROTECTED_RESOURCE_METADATA JSON.
metadata:
  owner: scalekit
  topic: mcp-auth
  framework: fastapi-fastmcp
  language: python
---

# Add OAuth auth to FastAPI + FastMCP (Scalekit)

## When to use this skill vs the FastMCP skill
Use THIS skill when:
- You need custom FastAPI middleware, routes, or dependency injection alongside MCP tools
- You're adding MCP to an existing FastAPI application
- You need more control over request handling than FastMCP's built-in ScalekitProvider offers

Use the `mcp-auth-fastmcp-scalekit` skill instead when:
- You're building a standalone MCP server and don't need FastAPI-specific features
- You want the simplest possible setup (5-line auth config)

## Critical wiring: how FastMCP mounts into FastAPI
FastMCP is NOT run standalone. It is mounted inside FastAPI:
```python
mcp_app = mcp.http_app(path="/")
app = FastAPI(lifespan=mcp_app.lifespan)  # lifespan MUST come from mcp_app
# ... add middleware and routes BEFORE mounting ...
app.mount("/", mcp_app)  # MUST be last
```
Order matters:
1. Create mcp_app from FastMCP
2. Create FastAPI with lifespan=mcp_app.lifespan
3. Add CORSMiddleware
4. Add @app.middleware("http") auth middleware
5. Add GET /.well-known/oauth-protected-resource (public)
6. Add GET /health (public)
7. app.mount("/", mcp_app) — ALWAYS last

## Inputs to collect (ask if missing)
- PORT (default 3002)
- SK_ENV_URL, SK_CLIENT_ID, SK_CLIENT_SECRET
- EXPECTED_AUDIENCE — must match the Server URL registered in Scalekit (with trailing slash, e.g. http://localhost:3002/)
- PROTECTED_RESOURCE_METADATA JSON — copied from Scalekit dashboard MCP server page

## Required outcomes
1. GET /.well-known/oauth-protected-resource → returns PROTECTED_RESOURCE_METADATA JSON (no auth required)
2. GET /health → {"status": "healthy"} (no auth required)
3. @app.middleware("http") auth_middleware:
   - Exempts /.well-known/oauth-protected-resource and /health
   - Extracts Authorization: Bearer <token>
   - On missing token → 401 + WWW-Authenticate header
   - Validates via scalekit_client.validate_access_token(token, options=TokenValidationOptions(issuer=SK_ENV_URL, audience=[EXPECTED_AUDIENCE]))
   - On invalid → 401 + WWW-Authenticate
4. FastMCP mounted at / with lifespan=mcp_app.lifespan
5. At least one @mcp.tool registered

---

# Mode A — New project scaffold

## Steps
1. Create directory and virtual environment:
   ```bash
   mkdir -p <project-name>
   cd <project-name>
   python3 -m venv .venv
   source .venv/bin/activate
   ```

2. Install dependencies:
   ```bash
   pip install -r assets/requirements.txt
   ```

3. Create .env from assets/env.example (fill real values from Scalekit dashboard).

4. Use assets/main-minimal.py as starting point. Add your tools using assets/tool-template.py.

5. Run:
   ```bash
   python main.py
   ```

6. Test with MCP Inspector (point to http://localhost:3002/ — NOT /mcp):
   ```bash
   npx @modelcontextprotocol/inspector@latest
   ```

---

# Mode B — Retrofit an existing FastAPI app

## Identify insertion points
Ask for the existing server entrypoint. Look for:
- Where `app = FastAPI(...)` is instantiated
- Whether `app.mount(...)` is already used
- Existing middleware definitions and their order
- Whether POST / is already taken (if so, mount MCP at /mcp instead and update RESOURCE_METADATA_URL)

## Patch plan (minimal diffs)

### 1. Add env vars
```env
SK_ENV_URL=...
SK_CLIENT_ID=...
SK_CLIENT_SECRET=...
EXPECTED_AUDIENCE=http://localhost:3002/
PROTECTED_RESOURCE_METADATA='...'
```

### 2. Add imports
```python
from fastmcp import FastMCP, Context
from scalekit import ScalekitClient
from scalekit.common.scalekit import TokenValidationOptions
from starlette.middleware.cors import CORSMiddleware
from fastapi import Request, Response
```

### 3. Add Scalekit client + constants
```python
RESOURCE_METADATA_URL = f"http://localhost:{PORT}/.well-known/oauth-protected-resource"
WWW_HEADER = {
    "WWW-Authenticate": f'Bearer realm="OAuth", resource_metadata="{RESOURCE_METADATA_URL}"'
}
scalekit_client = ScalekitClient(
    env_url=SK_ENV_URL,
    client_id=SK_CLIENT_ID,
    client_secret=SK_CLIENT_SECRET,
)
```

### 4. Create FastMCP instance + tools BEFORE patching FastAPI
```python
mcp = FastMCP("Your Server Name", stateless_http=True)

@mcp.tool(name="your_tool", description="...")
async def your_tool(...) -> dict:
    ...
```

### 5. Patch FastAPI instantiation
Before:
```python
app = FastAPI()
```
After:
```python
mcp_app = mcp.http_app(path="/")
app = FastAPI(lifespan=mcp_app.lifespan)
```
WARNING: If the existing app already sets lifespan, merge the lifespans using an async context manager.

### 6. Add CORSMiddleware (before auth middleware)
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"]
)
```

### 7. Add auth middleware
```python
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    PUBLIC_PATHS = {"/health", "/.well-known/oauth-protected-resource"}
    if request.url.path in PUBLIC_PATHS:
        return await call_next(request)

    auth_header = request.headers.get("authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return Response(
            '{"error": "Missing Bearer token"}',
            status_code=401,
            headers=WWW_HEADER,
            media_type="application/json"
        )

    token = auth_header.split("Bearer ", 1)[0].strip()
    options = TokenValidationOptions(issuer=SK_ENV_URL, audience=[EXPECTED_AUDIENCE])

    try:
        is_valid = scalekit_client.validate_access_token(token, options=options)
        if not is_valid:
            raise ValueError("Invalid token")
    except Exception:
        return Response(
            '{"error": "Token validation failed"}',
            status_code=401,
            headers=WWW_HEADER,
            media_type="application/json"
        )

    return await call_next(request)
```

### 8. Add public routes
```python
@app.get("/.well-known/oauth-protected-resource")
async def oauth_metadata():
    if not PROTECTED_RESOURCE_METADATA:
        return Response('{"error": "config missing"}', status_code=500, media_type="application/json")
    return Response(json.dumps(json.loads(PROTECTED_RESOURCE_METADATA), indent=2), media_type="application/json")

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

### 9. Mount FastMCP LAST
```python
app.mount("/", mcp_app)
```

---

## Verification checklist
- GET /.well-known/oauth-protected-resource returns JSON without auth
- GET /health returns {"status": "healthy"}
- POST to MCP endpoint without token → 401 + WWW-Authenticate
- POST to MCP endpoint with valid token → tool response
- Wrong-audience token → 401
- Tool call works end-to-end in MCP Inspector (connect to http://localhost:PORT/)

See references/TROUBLESHOOTING.md for common issues.
