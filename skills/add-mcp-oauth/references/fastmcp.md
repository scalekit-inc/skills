# FastMCP Scalekit provider

Use this file when the user wants FastMCP's built-in Scalekit provider. Do not run the Express samples in `SKILL.md`.

The provider owns token validation, `WWW-Authenticate`, and `/.well-known/oauth-protected-resource`. Then stop.

## Guardrails

- **MUST** use HTTP transport. stdio cannot do OAuth.
- **MUST** set `mcp_url` to the dashboard Server URL with a trailing slash. FastMCP appends `/mcp`.
- **MUST NOT** put auth on a path the provider already serves.

## Gotchas

- Env names: `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_RESOURCE_ID`, `MCP_URL`. Never `SCALEKIT_ENV_URL`.
- `SCALEKIT_RESOURCE_ID` is the dashboard resource id (`res_…`). Copy it. Do not invent it.
- `MCP_URL` is the base URL you registered (local default `http://localhost:3002/`). Keep the trailing slash.
- `ScalekitProvider` takes `environment_url`, `client_id`, `resource_id`, and `mcp_url`. It does not take `client_secret`.
- Do not prepend `https://` onto `SCALEKIT_ENVIRONMENT_URL`.

## Step 1 — Install

Install only what the repo is missing. Later steps import all of these:

```bash
pip install "fastmcp>=2.13.0.2" python-dotenv
```

**Done when:** those packages are installed.

## Step 2 — Register (user action)

Print this checklist. Wait. Do not invent dashboard clicks.

1. Open [app.scalekit.com](https://app.scalekit.com) → **MCP servers** → **Add MCP server**.
2. Enter a **name**.
3. Enable **dynamic client registration**.
4. Enable **Client ID Metadata Document (CIMD)**.
5. Set **Server URL** to `http://localhost:3002/` (keep the trailing slash). FastMCP appends `/mcp`.
6. **Save**. Copy `SCALEKIT_RESOURCE_ID` from the server page.

**Done when:** the user confirmed the row and `SCALEKIT_RESOURCE_ID` is copied.

## Step 3 — Provider

Put imports at the top of the file.

```python
import os
from dotenv import load_dotenv
from fastmcp import FastMCP
from fastmcp.server.auth.providers.scalekit import ScalekitProvider

load_dotenv()

mcp = FastMCP(
    "mcp-server",
    stateless_http=True,
    auth=ScalekitProvider(
        environment_url=os.environ["SCALEKIT_ENVIRONMENT_URL"],
        client_id=os.environ["SCALEKIT_CLIENT_ID"],
        resource_id=os.environ["SCALEKIT_RESOURCE_ID"],
        mcp_url=os.environ["MCP_URL"],
    ),
)

if __name__ == "__main__":
    mcp.run(transport="http", port=int(os.environ.get("PORT", "3002")))
```

Keep the user's tools.

**Done when:** the server runs with `ScalekitProvider` and HTTP transport.

## Step 4 — Optional scopes

```python
from fastmcp.server.dependencies import AccessToken, get_access_token

def _require_scope(scope: str) -> str | None:
    token: AccessToken = get_access_token()
    if scope not in token.scopes:
        return f"Insufficient permissions: `{scope}` scope required."
    return None
```

Call `_require_scope("todo:write")` inside a tool. Extra scope patterns live in the FastMCP live lookup.

**Done when:** scopes are skipped, or a tool checks `token.scopes`.

## Step 5 — Verify

```bash
curl -i http://localhost:3002/mcp
curl -i http://localhost:3002/.well-known/oauth-protected-resource
```

Expect 401 + `WWW-Authenticate` with `resource_metadata` on `/mcp`. Expect JSON with `resource`, `authorization_servers`, and `scopes_supported` on the well-known route.

**Done when:** both curls pass.

## Live lookups

- FastMCP: https://docs.scalekit.com/authenticate/mcp/fastmcp-quickstart/
- Docs index: https://docs.scalekit.com/llms.txt
- Example: https://github.com/scalekit-inc/mcp-demo/tree/main/todo-fastmcp
