# FastMCP OAuth Reference

## Core Concepts

### FastMCP HTTP Transport
FastMCP's HTTP transport (`stateless_http=True`) provides:
- Automatic SSE endpoint for server-to-client messages
- JSON-RPC over POST at `/mcp` path
- Built-in CORS handling
- Automatic `.well-known/oauth-protected-resource` endpoint when auth is configured

### ScalekitProvider Plugin
The `ScalekitProvider` handles all OAuth concerns:
- Token validation using Scalekit's public keys
- Automatic generation of `.well-known/oauth-protected-resource`
- `WWW-Authenticate` header on 401 responses
- Dynamic Client Registration (DCR) support
- Client ID Metadata Document (CIMD) support

### URL Structure
FastMCP automatically appends `/mcp` to your base URL:
- **Base URL (MCP_URL)**: `http://localhost:3002/` (with trailing slash)
- **Scalekit registration**: Register the BASE URL only
- **MCP endpoint**: `http://localhost:3002/mcp` (auto-appended)
- **Discovery endpoint**: `http://localhost:3002/.well-known/oauth-protected-resource` (auto-generated)

### Resource ID vs Audience
FastMCP uses `resource_id` instead of `aud`:
- `SCALEKIT_RESOURCE_ID`: Starts with `res_`, from Scalekit dashboard
- This is the identifier Scalekit uses to issue tokens
- Combined with `MCP_URL` to form the complete resource identifier

## Scope Enforcement Pattern

### Per-Tool Scope Checks
Unlike Express where scope checks can be in middleware, FastMCP requires checks inside each tool:

```python
def _require_scope(scope: str):
    token: AccessToken = get_access_token()
    if scope not in token.scopes:
        return f"Insufficient permissions: `{scope}` scope required."
    return None

@mcp.tool
def my_tool():
    error = _require_scope("my:scope")
    if error:
        return {"error": error}
    # tool logic here
```

### Why Inside Tools?
FastMCP's dependency injection system only has context at tool execution time
- Token is available via `get_access_token()` dependency
- Each tool can have different scope requirements
- Allows granular control: read-only vs write operations

## Comparison: FastMCP vs Express

| Aspect | FastMCP | Express |
|--------|---------|---------|
| Auth wiring | `ScalekitProvider` plugin | Custom middleware |
| `.well-known` | Automatic | Manual route |
| Token validation | Built-in provider | `scalekit.validateToken()` |
| Scope checks | Inside each tool | Middleware + optional tool checks |
| Audience config | `SCALEKIT_RESOURCE_ID` + `MCP_URL` | `EXPECTED_AUDIENCE` |
| MCP endpoint | `/mcp` (auto) | `/` (you define) |
| CORS | Automatic | Manual `cors()` |
| Code required | ~5 lines for auth | ~30+ lines for middleware |

## FastMCP Dependencies

### fastmcp.server.auth.providers.scalekit
```python
from fastmcp.server.auth.providers.scalekit import ScalekitProvider

mcp = FastMCP(
    "Server",
    stateless_http=True,
    auth=ScalekitProvider(
        environment_url=os.getenv("SCALEKIT_ENVIRONMENT_URL"),
        client_id=os.getenv("SCALEKIT_CLIENT_ID"),
        resource_id=os.getenv("SCALEKIT_RESOURCE_ID"),
        mcp_url=os.getenv("MCP_URL"),
    ),
)
```

### fastmcp.server.dependencies
```python
from fastmcp.server.dependencies import AccessToken, get_access_token

# Inside a tool function:
token: AccessToken = get_access_token()
# token.scopes = ["todo:read", "todo:write"]
# token.subject = "user-id"
```

## Scope Design Patterns

### Read/Write Split
```python
# Scalekit dashboard scopes:
# - todo:read
# - todo:write

@mcp.tool
def list_todos():
    _require_scope("todo:read")
    # returns list

@mcp.tool
def create_todo():
    _require_scope("todo:write")
    # creates item

@mcp.tool
def update_todo():
    _require_scope("todo:write")
    # updates item
```

### Resource Isolation
```python
# Scalekit dashboard scopes:
# - finance:read
# - finance:write
# - hr:read
# - hr:write

@mcp.tool
def get_payroll():
    _require_scope("finance:read")
    # sensitive finance data

@mcp.tool
def list_employees():
    _require_scope("hr:read")
    # employee directory
```

### Hierarchical Scopes
```python
# Scalekit dashboard scopes:
# - system:read
# - system:write
# - system:admin

@mcp.tool
def get_system_status():
    _require_scope("system:read")
    # status info

@mcp.tool
def restart_service():
    _require_scope("system:admin")
    # admin only
```

## Error Handling

### Scope-Error Response Format
```python
{
    "error": "Insufficient permissions: `todo:write` scope required."
}
```

This format is returned by the `_require_scope()` helper and is consistent across all tools.

### 401 vs 403
- **401**: No token or invalid token (handled by ScalekitProvider)
- **403**: Valid token but insufficient scope (handled by your scope check)

## Production Considerations

### HTTP Transport Requirements
FastMCP's `stateless_http=True` requires:
- ASGI server (Uvicorn, Hypercorn)
- Public URL for production (localhost won't work for remote clients)
- HTTPS in production (OAuth spec requirement)

### Server Deployment
```bash
# Development
python server.py

# Production with Uvicorn
uvicorn server:app --host 0.0.0.0 --port 3002
```

### Environment Variables
All required variables must be set:
- `SCALEKIT_ENVIRONMENT_URL`: Scalekit environment URL
- `SCALEKIT_CLIENT_ID`: MCP server client ID from dashboard
- `SCALEKIT_RESOURCE_ID`: Resource ID from dashboard (res_*)
- `MCP_URL`: Base URL with trailing slash
- `PORT`: Server port (default 3002)
