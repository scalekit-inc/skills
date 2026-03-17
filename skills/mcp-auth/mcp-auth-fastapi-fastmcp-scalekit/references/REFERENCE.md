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
