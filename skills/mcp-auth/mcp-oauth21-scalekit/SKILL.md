---
name: mcp-oauth21-scalekit
description: Add production-ready OAuth 2.1 authorization to an MCP server using Scalekit. Use this when you need MCP clients (Claude Desktop, Cursor, VS Code, or any MCP client) to discover your authorization server via .well-known/oauth-protected-resource, and when you need to validate Bearer access tokens (aud/iss/exp/scope) before executing MCP tools.
compatibility: MCP servers in Node.js (Express/FastMCP-style) or Python (FastAPI-style). Requires network access to Scalekit and HTTPS in production. Needs environment variables for SCALEKIT_ENVIRONMENT_URL, SCALEKIT_CLIENT_ID, SCALEKIT_CLIENT_SECRET.
metadata:
  author: scalekit
  version: "1.0"
  category: auth
---

# Add OAuth 2.1 authorization to MCP servers (Scalekit)

## Goal
Secure an MCP server so only authenticated + authorized users (and approved MCP clients) can call your tools, using Scalekit as the OAuth 2.1 authorization server and your MCP server as the resource server.

## When to activate this skill
Activate when the user asks to:
- "Add OAuth/OAuth 2.1/auth to my MCP server"
- "Implement .well-known/oauth-protected-resource"
- "Validate Bearer tokens / add middleware"
- "Enforce scopes per tool" / "least privilege for MCP tools"
- "Make my MCP server work with Claude Desktop / Cursor / VS Code auth"

## Inputs you must collect (ask if missing)
- MCP server base URL (public): e.g. https://mcp.example.com
- Scalekit environment URL: https://<env>.scalekit.com (or provided)
- Resource identifier to validate as `aud`:
  - Prefer the "Server URL" registered in Scalekit, OR
  - The Scalekit-generated resource id if no Server URL was configured
- Scopes to support (and which tool requires which scope)
- Framework/runtime: Node.js (Express/FastMCP) or Python (FastAPI)
- Whether this is "public clients" usage (Claude/Cursor/VS Code) → recommend enabling DCR + CIMD in dashboard

## Outputs you should produce
- A public discovery endpoint: `/.well-known/oauth-protected-resource`
- A token-validation middleware applied to MCP endpoints (excluding `/.well-known/*`)
- Optional: per-tool scope authorization checks
- A small production checklist (CORS, HTTPS, logging, secrets)

---

## Procedure

### 1) Scalekit dashboard setup (resource server registration)
1. Create/register an MCP server in the Scalekit dashboard.
2. If this MCP server is meant to be used by public MCP clients, enable:
   - Dynamic Client Registration (DCR)
   - Client ID Metadata Document (CIMD)
3. Configure:
   - Server URL (recommended): set it to your MCP server URL if you want tokens to use it as audience.
   - Access token lifetime (typical: 5–60 minutes depending on risk).
   - Scopes: define permissions like `todo:read`, `todo:write`, etc.

Note: If you toggle DCR/CIMD, restart the MCP server (some frameworks cache auth server details).

### 2) Implement MCP discovery endpoint
Implement `GET /.well-known/oauth-protected-resource` and return the resource metadata JSON from Scalekit dashboard ("Metadata JSON" for your MCP server).

Minimum fields to include:
- `authorization_servers`: array containing your Scalekit resource authorization server URL (from dashboard)
- `bearer_methods_supported`: include `header`
- `resource`: your MCP server identifier (usually your base URL)
- `resource_documentation`: docs URL (optional but recommended)
- `scopes_supported`: list of scopes you configured

If the user wants a template, point them to:
- `assets/oauth-protected-resource.json`
- `assets/express/well-known-route.ts` or `assets/fastapi/well_known_route.py`

### 3) Add Bearer token validation middleware (resource server enforcement)
Apply middleware to all MCP endpoints.
Rules:
- Allow unauthenticated access to `/.well-known/*` so clients can discover metadata.
- For all other routes:
  1. Extract access token from `Authorization: Bearer <token>`
  2. If missing → respond `401` and include `WWW-Authenticate: Bearer ... resource_metadata="<your .well-known url>"`
  3. Validate token using Scalekit SDK:
     - Validate `aud` includes your configured resource identifier
     - Validate issuer if your SDK requires/permits it
     - Validate expiry and issued-at (SDK typically handles this)
  4. On validation failure → respond `401` with `WWW-Authenticate`

Templates:
- Node/Express: `assets/express/auth-middleware.ts`
- Python/FastAPI: `assets/fastapi/auth_middleware.py`

Security notes:
- Do not log raw tokens.
- Prefer constant-time comparisons where relevant (SDK should handle signatures).
- Keep the middleware small; push details to reference docs.

### 4) Optional: scope-based authorization at tool execution time
For each MCP tool, define required scope(s) and enforce them when executing the tool.
Suggested approach:
- Maintain a map: `tool_name -> required_scopes` (see `assets/tool-scope-map.example.yaml`)
- At execution:
  - Validate token again with `requiredScopes` (or validate once and check claims, depending on SDK support)
  - If insufficient scope → return an OAuth-style error response (403, `insufficient_scope`) with a helpful message

### 5) Testing checklist
- Discovery works: call `/.well-known/oauth-protected-resource` without auth and confirm JSON is correct.
- Middleware rejects missing token (401 + WWW-Authenticate).
- Valid token passes (200).
- Token with wrong `aud` fails.
- Scope enforcement denies (403) and allows with correct scope.
- Test with at least one MCP host (Claude Desktop / Cursor / VS Code) if that's your target.

### 6) Production checklist
See `references/SECURITY.md`. Minimum:
- HTTPS everywhere
- Correct CORS for MCP endpoints
- Secure secret storage (env/secret manager)
- Monitoring + audit logs for auth failures and tool execution
- Reasonable token lifetimes
- Validate resource audience (`aud`) strictly
- Consider rate limiting on auth-related endpoints

---

## References
- Deep technical notes: `references/REFERENCE.md`
- Scope design patterns: `references/SCOPES.md`
- Production hardening: `references/SECURITY.md`
