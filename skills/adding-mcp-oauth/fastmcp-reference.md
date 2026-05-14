# FastMCP + ScalekitProvider Reference

## What this skill builds
- A FastMCP server with `stateless_http=True` that boots an HTTP transport on a configured port.
- OAuth protection via `ScalekitProvider` — handles token validation, .well-known discovery, and WWW-Authenticate on 401 automatically.
- Per-tool scope enforcement using `get_access_token()` from `fastmcp.server.dependencies`.
- Scopes are pre-configured in the Scalekit dashboard; tools check them at runtime.

## Key difference from Express skill
- No manual middleware, no manual .well-known route.
- Auth is injected at the `FastMCP(auth=...)` constructor.
- `ScalekitProvider` uses `resource_id` (starts with `res_`) and `mcp_url` (base URL + trailing slash).
- FastMCP appends `/mcp` to the base URL automatically — always register the BASE URL with trailing slash in Scalekit, not the /mcp path.

## Inputs to collect (ask if missing)
- SCALEKIT_ENVIRONMENT_URL (your Scalekit env URL, e.g. https://your-env.scalekit.com)
- SCALEKIT_CLIENT_ID
- SCALEKIT_RESOURCE_ID (starts with res_, from Dashboard > MCP Servers)
- MCP_URL: base URL with trailing slash (e.g. http://localhost:3002/)
- PORT (default 3002)
- Scopes to configure (e.g. todo:read, todo:write); these must also be created in the Scalekit dashboard

## Mode detection
Ask: "Are we scaffolding a new FastMCP server, or adding auth to an existing FastMCP server?"
- Mode A: New server → use assets/fastmcp/server.py or assets/fastmcp/server-minimal.py as the base
- Mode B: Existing server → apply the patch plan below

---

# Mode A — New server scaffold

## Steps
1. Create a directory and virtual environment:
   ```
   mkdir -p <project-name>
   cd <project-name>
   python3 -m venv venv
   source venv/bin/activate
   ```

2. Install dependencies using assets/fastmcp/requirements.txt:
   ```
   pip install -r requirements.txt
   ```

3. Create .env using assets/fastmcp/env.example (fill real values from Scalekit dashboard).

4. Copy assets/fastmcp/server-minimal.py to server.py and add your tools.

5. Run:
   ```
   python server.py
   ```

6. Test with MCP Inspector (point to http://localhost:3002/mcp — note: /mcp, not /):
   ```
   npx @modelcontextprotocol/inspector@latest
   ```
   Leave Authentication fields empty; DCR handles client registration automatically.

---

# Mode B — Retrofit an existing FastMCP server

## Identify insertion points
Ask for the existing server file. Look for:
- How `FastMCP(...)` is instantiated
- Whether `mcp.run(...)` is already present

## Patch plan (minimal diffs)

### 1. Add env vars
Add to .env:
```
SCALEKIT_ENVIRONMENT_URL=...
SCALEKIT_CLIENT_ID=...
SCALEKIT_RESOURCE_ID=...
MCP_URL=http://localhost:3002/
PORT=3002
```

### 2. Add imports
```python
from fastmcp.server.auth.providers.scalekit import ScalekitProvider
from fastmcp.server.dependencies import AccessToken, get_access_token
```

### 3. Patch FastMCP constructor
Before (typical):
```python
mcp = FastMCP("My Server")
```

After:
```python
mcp = FastMCP(
    "My Server",
    stateless_http=True,
    auth=ScalekitProvider(
        environment_url=os.getenv("SCALEKIT_ENVIRONMENT_URL"),
        client_id=os.getenv("SCALEKIT_CLIENT_ID"),
        resource_id=os.getenv("SCALEKIT_RESOURCE_ID"),
        mcp_url=os.getenv("MCP_URL"),
    ),
)
```

### 4. Add scope helper
Add once near the top of the file:
```python
def _require_scope(scope: str):
    token: AccessToken = get_access_token()
    if scope not in token.scopes:
        return f"Insufficient permissions: `{scope}` scope required."
    return None
```

### 5. Add scope checks to each tool
At the top of each @mcp.tool function body, add:
```python
error = _require_scope("your:scope")
if error:
    return {"error": error}
```

See assets/fastmcp/tool-template.py for the full pattern.

### 6. Patch run call
```python
if __name__ == "__main__":
    mcp.run(transport="http", port=int(os.getenv("PORT", "3002")))
```

---

## Scope design guide
- Register scopes in Scalekit dashboard BEFORE running the server.
- Group by read vs write per resource: e.g. todo:read, todo:write.
- Tools that only read → require read scope.
- Tools that mutate (create/update/delete) → require write scope.
- A token with no matching scope will get {"error": "Insufficient permissions: <scope> required."}.

## Verification checklist
- Server boots and logs HTTP transport on http://localhost:PORT/
- MCP Inspector connects to http://localhost:PORT/mcp
- Tool with correct scope → success
- Tool with wrong scope → {"error": "Insufficient permissions..."}
- No token → 401 + WWW-Authenticate (handled by ScalekitProvider automatically)

See the troubleshooting section below for common issues.

---

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

---

# FastMCP OAuth Troubleshooting

## Common Issues

### Server Won't Start
**Symptom**: `ModuleNotFoundError: No module named 'fastmcp'` or similar.

**Cause**: Dependencies not installed or virtual environment not activated.

**Solution**:
```bash
# Activate virtual environment
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt
```

### MCP Inspector Can't Connect
**Symptom**: Inspector shows "Failed to connect" or timeout.

**Cause 1**: Wrong URL
- Inspector default is `http://localhost:3002/` but MCP endpoint is `/mcp`
- Try: `http://localhost:3002/mcp` in Inspector

**Cause 2**: Server not running
```bash
# Check server is running
python server.py

# Should see output like:
# INFO:     Uvicorn running on http://0.0.0.0:3002
```

**Cause 3**: Wrong transport mode
- Ensure `stateless_http=True` is set in FastMCP constructor
- Check `mcp.run(transport="http", ...)` is used

### "Stateless HTTP transport not enabled" Error
**Symptom**: Server logs show error about stateless transport.

**Cause**: Missing `stateless_http=True` in FastMCP constructor.

**Solution**:
```python
mcp = FastMCP(
    "My Server",
    stateless_http=True,  # ← This is required!
    auth=ScalekitProvider(...)
)
```

### Discovery Endpoint Returns 404
**Symptom**: `curl http://localhost:3002/.well-known/oauth-protected-resource` returns 404.

**Cause**: `ScalekitProvider` not configured correctly.

**Solution**:
```python
# Ensure all 4 parameters are set:
auth=ScalekitProvider(
    environment_url=os.getenv("SCALEKIT_ENVIRONMENT_URL"),
    client_id=os.getenv("SCALEKIT_CLIENT_ID"),
    resource_id=os.getenv("SCALEKIT_RESOURCE_ID"),
    mcp_url=os.getenv("MCP_URL"),
)
```

### Discovery Endpoint Returns Empty JSON
**Symptom**: Discovery endpoint returns `{}` or missing required fields.

**Cause 1**: Missing or invalid `SCALEKIT_RESOURCE_ID`

**Solution**:
- Copy resource ID directly from Scalekit dashboard
- Should start with `res_`
- Verify no extra spaces or quotes

**Cause 2**: `MCP_URL` missing trailing slash

**Solution**:
```env
# Wrong
MCP_URL=http://localhost:3002

# Correct
MCP_URL=http://localhost:3002/
```

### Token Always Invalid (401)
**Symptom**: All tool calls return 401 even with valid token.

**Cause 1**: `SCALEKIT_RESOURCE_ID` mismatch
- Resource ID in code doesn't match Scalekit dashboard

**Solution**:
1. Go to Scalekit dashboard > MCP Servers
2. Copy Resource ID exactly (starts with `res_`)
3. Update .env file
4. Restart server

**Cause 2**: `MCP_URL` mismatch with Scalekit registration
- You registered wrong URL in Scalekit

**Solution**:
1. In Scalekit dashboard, check "Server URL" or base URL
2. Ensure it matches your `MCP_URL` in .env
3. Use trailing slash consistently

### Scope Check Always Fails
**Symptom**: Tool always returns "Insufficient permissions" even with token that has scopes.

**Cause 1**: Scopes not registered in Scalekit dashboard
- You're checking for a scope that doesn't exist

**Solution**:
1. Go to Scalekit dashboard > MCP Servers
2. Add your scopes (e.g., `todo:read`, `todo:write`)
3. Save and restart server

**Cause 2**: Scope string mismatch
- Case sensitivity, extra characters, or typos

**Solution**:
```python
# Ensure exact match between dashboard and code
# Dashboard: "todo:read"
# Code: _require_scope("todo:read")  # Must match exactly
```

**Cause 3**: Token doesn't have the scope
- Client requested different scopes during auth

**Solution**:
1. Check MCP Inspector or client logs for scope list
2. Verify client requested the right scopes
3. Re-authenticate to get new token with correct scopes

### "get_access_token() called outside of request context" Error
**Symptom**: Error when calling `get_access_token()` in a tool.

**Cause**: Tool not being called through MCP protocol (e.g., direct function call).

**Solution**:
- Only call `get_access_token()` inside `@mcp.tool` decorated functions
- Don't call it in global scope or outside tool execution
- Test via MCP Inspector, not by running the function directly

### CORS Errors in Browser
**Symptom**: Browser console shows CORS errors.

**Cause**: CORS not enabled or origin not allowed.

**Solution**:
FastMCP handles CORS automatically with `stateless_http=True`. If issues persist:
```python
# Check server logs for CORS configuration
# FastMCP should log CORS middleware being registered
```

### Port Already in Use
**Symptom**: `OSError: [Errno 48] Address already in use`

**Solution**:
```bash
# Change PORT in .env
PORT=3003  # Use different port

# Or kill existing process
lsof -ti:3002 | xargs kill -9  # Linux/Mac
```

## Debugging Tips

### Enable Verbose Logging
```python
import logging

logging.basicConfig(level=logging.DEBUG)
```

This will show:
- Request/response details
- Token validation steps
- Scope check results

### Test Discovery Endpoint
```bash
# Test without auth (should work)
curl http://localhost:3002/.well-known/oauth-protected-resource

# Expected response:
{
  "authorization_servers": ["https://your-env.scalekit.com/resources/res_xxx"],
  "bearer_methods_supported": ["header"],
  "resource": "http://localhost:3002/",
  "resource_documentation": "...",
  "scopes_supported": ["todo:read", "todo:write"]
}
```

### Test Tool Without Auth (Should Fail)
```bash
curl -X POST http://localhost:3002/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'

# Expected: 401 with WWW-Authenticate header
```

### Inspect Token Contents
Use JWT decoder to verify token claims:
```bash
# Get token from MCP Inspector logs
echo "<your-access-token>" | jq -R 'split(".") | .[1] | @base64d | fromjson'
```

Check:
- `aud`: Should match your resource
- `exp`: Should not be expired
- `scope`: Should include required scopes

### Test with Different Scopes
Create test tokens with different scopes:
```python
# In Scalekit dashboard, create test tokens with:
# - todo:read only
# - todo:write only
# - both scopes
# - no scopes

# Then test each against your tools
```

## Common Environment Variable Mistakes

| Variable | Common Mistake | Correct Value |
|----------|----------------|---------------|
| `SCALEKIT_ENVIRONMENT_URL` | Missing protocol | `https://your-env.scalekit.com` |
| `SCALEKIT_CLIENT_ID` | Wrong client ID | Copy from MCP Server page |
| `SCALEKIT_RESOURCE_ID` | Missing `res_` prefix | `res_abc123...` |
| `MCP_URL` | Missing trailing slash | `http://localhost:3002/` |
| `PORT` | Already in use | Choose unused port |

## MCP Inspector Tips

### Correct URL for FastMCP
```
http://localhost:3002/mcp
```
Note: `/mcp` is auto-appended by FastMCP, NOT `/`

### Leave Auth Fields Empty
When using DCR (Dynamic Client Registration):
- Leave Client ID and Client Secret empty
- ScalekitProvider handles client registration
- Inspector will prompt you to authenticate in browser

### Check Token Scopes
In Inspector, after authentication:
1. Click the connection info
2. Look for "scopes" or "permissions"
3. Verify your expected scopes are listed

## Getting Help

If issues persist:
1. Check Scalekit dashboard for server status
2. Review Scalekit logs for authentication attempts
3. Enable DEBUG logging and capture full output
4. Verify all 5 environment variables are set correctly
5. Test with MCP Inspector to isolate client vs server issues
6. Confirm `stateless_http=True` is set
7. Verify `transport="http"` in `mcp.run()` call
