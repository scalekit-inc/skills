---
name: mcp-auth-fastmcp-scalekit
description: Add Scalekit OAuth authentication to a FastMCP server (Python). Use when you need to protect FastMCP tools with OAuth 2.1 Bearer tokens and enforce per-tool scope checks (e.g. todo:read, todo:write). Authentication is added in 5 lines via ScalekitProvider; scope checks use get_access_token() inside each tool.
compatibility: Python 3.11+. Requires fastmcp>=2.13.0.2 and python-dotenv. Does NOT need custom middleware or a manual .well-known endpoint — FastMCP and ScalekitProvider handle those automatically.
metadata:
  owner: scalekit
  topic: mcp-auth
  framework: fastmcp
  language: python
---

# Add OAuth auth to a FastMCP server (Scalekit)

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
- Mode A: New server → use assets/server.py or assets/server-minimal.py as the base
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

2. Install dependencies using assets/requirements.txt:
   ```
   pip install -r requirements.txt
   ```

3. Create .env using assets/env.example (fill real values from Scalekit dashboard).

4. Copy assets/server-minimal.py to server.py and add your tools.

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

See assets/tool-template.py for the full pattern.

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

See references/TROUBLESHOOTING.md for common issues.
