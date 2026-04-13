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
