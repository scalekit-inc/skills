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
