# FastAPI + FastMCP Reference

## When to use this skill vs the FastMCP skill
Use THIS skill when:
- You need custom FastAPI middleware, routes, or dependency injection alongside MCP tools
- You're adding MCP to an existing FastAPI application
- You need more control over request handling than FastMCP's built-in ScalekitProvider offers

Use the [fastmcp-reference.md](fastmcp-reference.md) approach instead when:
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
   pip install -r assets/fastapi/requirements.txt
   ```

3. Create .env from assets/fastapi/env.example (fill real values from Scalekit dashboard).

4. Use assets/fastapi/main-minimal.py as starting point. Add your tools using assets/fastapi/tool-template.py.

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

    token = auth_header.split("Bearer ", 1)[1].strip()
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

---

# FastAPI + FastMCP OAuth Reference

## Core Concepts

### Architecture: FastMCP Mounted in FastAPI
Unlike standalone FastMCP servers, FastMCP is mounted as an ASGI app inside FastAPI:
```python
mcp = FastMCP("Server", stateless_http=True)
mcp_app = mcp.http_app(path="/")
app = FastAPI(lifespan=mcp_app.lifespan)
# ... middleware and routes ...
app.mount("/", mcp_app)  # Mount LAST
```

### Why Mount FastMCP in FastAPI?
- Use FastAPI's dependency injection alongside MCP tools
- Add custom HTTP middleware before MCP requests
- Mix non-MCP routes with MCP endpoints
- Leverage FastAPI's auto-documentation and validation
- Integrate with existing FastAPI applications

### Critical Order of Operations
The order of FastAPI setup is critical:

1. **Create FastMCP instance** (with tools)
2. **Generate mcp_app** via `mcp.http_app(path="/")`
3. **Create FastAPI** with `lifespan=mcp_app.lifespan`
4. **Add CORSMiddleware** (must be before auth)
5. **Add auth middleware** (`@app.middleware("http")`)
6. **Add public routes** (/.well-known, /health)
7. **Mount FastMCP LAST** (`app.mount("/", mcp_app)`)

### Why Mount Last?
FastMCP's mount at `/` is a catch-all route. Any routes added after the mount will never be reached.

## Token Validation

### Scalekit Client Configuration
```python
from scalekit import ScalekitClient
from scalekit.common.scalekit import TokenValidationOptions

scalekit_client = ScalekitClient(
    env_url=SK_ENV_URL,
    client_id=SK_CLIENT_ID,
    client_secret=SK_CLIENT_SECRET,
)
```

### Token Validation in Middleware
```python
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    token = extract_bearer_token(request)

    options = TokenValidationOptions(
        issuer=SK_ENV_URL,
        audience=[EXPECTED_AUDIENCE]
    )

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

### WWW-Authenticate Header
Required for MCP client OAuth discovery:
```python
WWW_HEADER = {
    "WWW-Authenticate": f'Bearer realm="OAuth", resource_metadata="{RESOURCE_METADATA_URL}"'
}
```

## Comparison: Three Auth Approaches

| Aspect | Standalone FastMCP | FastAPI + FastMCP | Express |
|--------|-------------------|------------------|---------|
| **Language** | Python | Python | TypeScript |
| **Auth Mechanism** | `ScalekitProvider` plugin | `@app.middleware("http")` | `app.use()` middleware |
| **`.well-known`** | Automatic | Manual FastAPI route | Manual Express route |
| **Token Validation** | Built-in provider | `validate_access_token()` | `validateToken()` |
| **Audience Env Var** | `SCALEKIT_RESOURCE_ID` + `MCP_URL` | `EXPECTED_AUDIENCE` | `EXPECTED_AUDIENCE` |
| **MCP Endpoint** | `/mcp` (auto) | `/` (mount path) | `/` (you define) |
| **Client Secret** | Not required | Required (`SK_CLIENT_SECRET`) | Required (`SK_CLIENT_SECRET`) |
| **Use When** | Simple standalone MCP | Existing FastAPI app | Node.js/TypeScript |

### Choosing the Right Approach

- **Standalone FastMCP**: Quick prototypes, minimal code, no existing FastAPI app
- **FastAPI + FastMCP**: Existing FastAPI app, custom middleware, mixed routes
- **Express**: Node.js ecosystem, existing Express app, TypeScript preference

## Scope Enforcement

### No Built-in Scope Checking
FastAPI + FastMCP does NOT automatically check scopes. You must implement scope validation:

```python
# Option 1: Manual scope check in tools
@mcp.tool(name="create_todo", description="Create a todo")
async def create_todo(text: str, ctx: Context | None = None) -> dict:
    token = ctx.request.state.token  # Extract from middleware
    if "todo:write" not in token.get("scopes", []):
        return {"error": "Insufficient scope: todo:write required"}
    # ... tool logic ...
```

```python
# Option 2: Add token to request state in middleware
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    # ... validate token ...
    # After validation, decode token and attach to request state
    request.state.token = decode_jwt(token)
    return await call_next(request)
```

## Lifespan Management

### FastMCP Lifespan
FastMCP's http_app provides a lifespan for managing startup/shutdown:
```python
mcp_app = mcp.http_app(path="/")
app = FastAPI(lifespan=mcp_app.lifespan)
```

This handles:
- MCP server startup
- Tool registration
- Connection management

### Merging Lifespans
If your app already has a lifespan:
```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def combined_lifespan(app: FastAPI):
    # Startup
    await mcp_app.router.startup()
    await your_startup_logic()
    yield
    # Shutdown
    await your_shutdown_logic()
    await mcp_app.router.shutdown()

app = FastAPI(lifespan=combined_lifespan)
```

## Route Structure

### Public Routes (No Auth)
```python
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/.well-known/oauth-protected-resource")
async def oauth_metadata():
    return Response(
        json.dumps(json.loads(PROTECTED_RESOURCE_METADATA), indent=2),
        media_type="application/json"
    )
```

### Protected Routes (Require Auth)
All routes under the FastMCP mount (`/`) are protected by middleware. Tools are automatically protected.

## CORS Configuration

### CORSMiddleware Setup
```python
from starlette.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"]
)
```

### Important: CORS Before Auth
CORSMiddleware must be added BEFORE auth middleware:
1. CORSMiddleware (handles preflight)
2. Auth middleware (validates tokens)
3. Public routes (/.well-known, /health)
4. Mount FastMCP

## Error Handling

### OAuth-Compliant Errors
```python
# 401: No token or invalid token
return Response(
    '{"error": "Token validation failed"}',
    status_code=401,
    headers=WWW_HEADER,
    media_type="application/json"
)

# 403: Insufficient scope (if implementing scope checks)
return Response(
    '{"error": "insufficient_scope", "error_description": "todo:write required"}',
    status_code=403,
    media_type="application/json"
)

# 500: Configuration error
return Response(
    '{"error": "config missing"}',
    status_code=500,
    media_type="application/json"
)
```

## Production Considerations

### HTTPS Required
OAuth 2.1 requires HTTPS in production. Configure Uvicorn with:
```python
import uvicorn

uvicorn.run(
    app,
    host="0.0.0.0",
    port=PORT,
    ssl_keyfile="key.pem",
    ssl_certfile="cert.pem"
)
```

### Secret Management
Never commit credentials:
```bash
# .gitignore
.env
*.pem
```

```python
# Load from environment only
SK_CLIENT_SECRET = os.getenv("SK_CLIENT_SECRET")
if not SK_CLIENT_SECRET:
    raise ValueError("SK_CLIENT_SECRET environment variable is required")
```

### Logging
```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    # ... token validation ...
    logger.info(f"Authenticated request: {request.url.path}")
    return await call_next(request)
```

### Rate Limiting
Consider adding rate limiting to auth endpoints:
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.get("/.well-known/oauth-protected-resource")
@limiter.limit("10/minute")
async def oauth_metadata(request: Request):
    ...
```

---

# FastAPI + FastMCP OAuth Troubleshooting

## Common Issues

### FastMCP Tools Not Registered
**Symptom**: MCP Inspector connects but shows no tools or `tools/list` returns empty array.

**Cause 1**: FastMCP created but no tools added before mounting
```python
# Wrong order
mcp = FastMCP("Server")
mcp_app = mcp.http_app(path="/")
app = FastAPI(lifespan=mcp_app.lifespan)
# ... mount app ...
@mcp.tool  # Too late - already mounted
def my_tool():
    ...
```

**Solution**: Add all tools BEFORE creating mcp_app:
```python
mcp = FastMCP("Server")

@mcp.tool  # Add BEFORE http_app()
def my_tool():
    ...

mcp_app = mcp.http_app(path="/")
app = FastAPI(lifespan=mcp_app.lifespan)
```

**Cause 2**: Mount path mismatch
- You mounted at `/mcp` but Inspector connects to `/`

**Solution**: Use consistent mount path:
```python
# Option 1: Mount at /
mcp_app = mcp.http_app(path="/")
app.mount("/", mcp_app)
# Connect to: http://localhost:3002/

# Option 2: Mount at /mcp
mcp_app = mcp.http_app(path="/mcp")
app.mount("/mcp", mcp_app)
# Connect to: http://localhost:3002/mcp
```

### Lifespan Errors
**Symptom**: `AttributeError: 'lifespan' attribute not found` or startup/shutdown errors.

**Cause 1**: FastAPI created without lifespan from mcp_app
```python
# Wrong
app = FastAPI()  # Missing lifespan
app.mount("/", mcp_app)
```

**Solution**: Use mcp_app's lifespan:
```python
mcp_app = mcp.http_app(path="/")
app = FastAPI(lifespan=mcp_app.lifespan)  # Use mcp_app lifespan
app.mount("/", mcp_app)
```

**Cause 2**: Merging lifespans incorrectly
- Existing app has lifespan but you replaced it

**Solution**: Use async context manager to merge:
```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def combined_lifespan(app: FastAPI):
    await existing_startup()
    await mcp_app.router.startup()
    yield
    await existing_shutdown()
    await mcp_app.router.shutdown()

app = FastAPI(lifespan=combined_lifespan)
```

### Routes After Mount Never Reached
**Symptom**: Routes added after `app.mount("/", mcp_app)` return 404.

**Cause**: FastMCP's mount at `/` catches all requests
- Order matters: mount MUST be last

**Solution**: Reorder code:
```python
# Wrong order
app.mount("/", mcp_app)  # Mount first (WRONG)
@app.get("/custom")
async def custom_route():
    return {"custom": True}

# Correct order
@app.get("/custom")
async def custom_route():
    return {"custom": True}
app.mount("/", mcp_app)  # Mount last (CORRECT)
```

### CORS Preflight Fails
**Symptom**: Browser OPTIONS requests fail or CORS errors in console.

**Cause**: CORSMiddleware missing or order wrong

**Solution**: Add CORS before auth middleware:
```python
# Wrong order
@app.middleware("http")
async def auth_middleware(...):
    ...
app.add_middleware(CORSMiddleware, ...)  # After auth (WRONG)

# Correct order
app.add_middleware(CORSMiddleware, ...)  # First
@app.middleware("http")
async def auth_middleware(...):
    ...
```

### Auth Middleware Blocks Public Routes
**Symptom**: GET /.well-known/oauth-protected-resource returns 401.

**Cause**: Public paths not exempted from auth middleware

**Solution**: Exempt public paths:
```python
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    PUBLIC_PATHS = {"/health", "/.well-known/oauth-protected-resource"}
    if request.url.path in PUBLIC_PATHS:
        return await call_next(request)  # Skip auth

    # ... continue with auth logic ...
```

### Token Validation Always Fails
**Symptom**: All requests return 401 even with valid tokens.

**Cause 1**: Wrong audience (`EXPECTED_AUDIENCE`)
- Doesn't match Scalekit dashboard "Server URL"

**Solution**:
```bash
# Copy Server URL from Scalekit dashboard exactly
EXPECTED_AUDIENCE=http://localhost:3002/  # Note trailing slash
```

**Cause 2**: Missing `SK_CLIENT_SECRET`
- FastAPI + FastMCP requires client secret (unlike standalone FastMCP)

**Solution**:
```env
SK_CLIENT_SECRET=your-secret-from-scalekit-dashboard
```

**Cause 3**: Wrong issuer (`SK_ENV_URL`)

**Solution**:
```env
# Must match Scalekit environment URL
SK_ENV_URL=https://your-env.scalekit.com
```

### WWW-Authenticate Header Missing
**Symptom**: 401 response but no `WWW-Authenticate` header.

**Cause**: WWW-Authenticate not included in 401 response

**Solution**:
```python
return Response(
    '{"error": "Token validation failed"}',
    status_code=401,
    headers=WWW_HEADER,  # ← Include WWW-Authenticate
    media_type="application/json"
)
```

### Discovery Endpoint Returns 500
**Symptom**: `/.well-known/oauth-protected-resource` returns 500 error.

**Cause**: `PROTECTED_RESOURCE_METADATA` not set or invalid JSON

**Solution**:
```python
@app.get("/.well-known/oauth-protected-resource")
async def oauth_metadata():
    if not PROTECTED_RESOURCE_METADATA:
        return Response(
            '{"error": "config missing"}',
            status_code=500,
            media_type="application/json"
        )
    try:
        metadata = json.loads(PROTECTED_RESOURCE_METADATA)
        return Response(
            json.dumps(metadata, indent=2),
            media_type="application/json"
        )
    except json.JSONDecodeError:
        return Response(
            '{"error": "Invalid JSON in PROTECTED_RESOURCE_METADATA"}',
            status_code=500,
            media_type="application/json"
        )
```

### MCP Inspector Connection Timeout
**Symptom**: Inspector shows "Failed to connect" or timeout.

**Cause 1**: Wrong URL
- Connecting to `/mcp` when mounted at `/`
- Or connecting to `/` when mounted at `/mcp`

**Solution**: Check mount path:
```python
# If mounted at /
mcp_app = mcp.http_app(path="/")
app.mount("/", mcp_app)
# Inspector URL: http://localhost:3002/

# If mounted at /mcp
mcp_app = mcp.http_app(path="/mcp")
app.mount("/mcp", mcp_app)
# Inspector URL: http://localhost:3002/mcp
```

**Cause 2**: Server not running or wrong port

**Solution**:
```bash
# Check server is running
curl http://localhost:3002/health

# Should return: {"status": "healthy"}
```

### Port Already in Use
**Symptom**: `OSError: [Errno 48] Address already in use`

**Solution**:
```bash
# Change PORT in .env
PORT=3003

# Or kill existing process
lsof -ti:3002 | xargs kill -9  # Linux/Mac
```

### Import Errors
**Symptom**: `ModuleNotFoundError: No module named 'fastmcp'` or similar.

**Cause**: Dependencies not installed or virtual environment not activated

**Solution**:
```bash
# Activate virtual environment
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## Debugging Tips

### Enable Debug Logging
```python
import logging

logging.basicConfig(level=logging.DEBUG)
```

This shows:
- Request/response details
- Token validation steps
- Middleware execution order

### Test Public Routes
```bash
# Test health endpoint (should work without auth)
curl http://localhost:3002/health

# Test discovery endpoint (should work without auth)
curl http://localhost:3002/.well-known/oauth-protected-resource
```

### Test Protected Endpoint Without Token
```bash
# Should return 401 with WWW-Authenticate header
curl -i -X POST http://localhost:3002/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

Check response headers for:
```
WWW-Authenticate: Bearer realm="OAuth", resource_metadata="http://localhost:3002/.well-known/oauth-protected-resource"
```

### Inspect Token Contents
Use JWT decoder to verify token claims:
```bash
echo "<your-access-token>" | jq -R 'split(".") | .[1] | @base64d | fromjson'
```

Check:
- `aud`: Should match `EXPECTED_AUDIENCE`
- `iss`: Should match `SK_ENV_URL`
- `exp`: Should not be expired
- `scope`: Should include required scopes (if using scope checks)

### Check Middleware Order
Add logging to verify middleware execution order:
```python
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    logger.info(f"Auth middleware: {request.url.path}")
    # ... auth logic ...
    return await call_next(request)

@app.get("/health")
async def health():
    logger.info("Health endpoint")
    return {"status": "healthy"}
```

Order should be:
1. CORSMiddleware (no log)
2. Auth middleware (logs "Auth middleware")
3. Health endpoint (logs "Health endpoint")

## Common Environment Variable Mistakes

| Variable | Common Mistake | Correct Value |
|----------|----------------|---------------|
| `SK_ENV_URL` | Missing protocol | `https://your-env.scalekit.com` |
| `SK_CLIENT_ID` | Wrong client ID | Copy from MCP Server page |
| `SK_CLIENT_SECRET` | Missing (unlike FastMCP-standalone) | Copy from dashboard |
| `EXPECTED_AUDIENCE` | Missing trailing slash | `http://localhost:3002/` |
| `PROTECTED_RESOURCE_METADATA` | Not JSON-escaped | `'{"key":"value"}'` (quotes around JSON) |
| `PORT` | Already in use | Choose unused port |

## FastAPI + FastMCP vs Standalone FastMCP

### Confusing the Two Approaches
**Symptom**: Using `SCALEKIT_RESOURCE_ID` and `MCP_URL` (FastMCP-standalone) instead of `EXPECTED_AUDIENCE` (FastAPI).

**Solution**: Remember:
- **FastAPI + FastMCP**: Uses Express-style env vars (`EXPECTED_AUDIENCE`, `SK_CLIENT_SECRET`)
- **Standalone FastMCP**: Uses different env vars (`SCALEKIT_RESOURCE_ID`, `MCP_URL`, no `SK_CLIENT_SECRET`)

Don't mix the approaches!

## Getting Help

If issues persist:
1. Check Scalekit dashboard for server status
2. Review Scalekit logs for authentication attempts
3. Enable DEBUG logging and capture full output
4. Verify all 5 environment variables are set correctly
5. Test with MCP Inspector to isolate client vs server issues
6. Verify middleware order: CORS → Auth → Routes → Mount
7. Confirm FastAPI uses `lifespan=mcp_app.lifespan`
8. Ensure FastMCP mount is LAST in the code
9. Check that tools are registered BEFORE calling `http_app()`
