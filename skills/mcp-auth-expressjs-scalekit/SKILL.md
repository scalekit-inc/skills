---
name: mcp-auth-expressjs-scalekit
description: "Add Scalekit OAuth authentication to an Express.js MCP server (TypeScript). Supports two modes: scaffold a new server from scratch, or retrofit an existing Express app. Implements /.well-known/oauth-protected-resource for MCP client discovery, a Bearer-token validation middleware using @scalekit-sdk/node (audience check), and a POST / MCP endpoint using StreamableHTTPServerTransport."
compatibility: Node.js 20+. Express + TypeScript. Requires SK_ENV_URL, SK_CLIENT_ID, SK_CLIENT_SECRET, EXPECTED_AUDIENCE, and PROTECTED_RESOURCE_METADATA JSON.
metadata:
  owner: scalekit
  topic: mcp-auth
  framework: express
  language: typescript
---

# Add MCP OAuth auth to Express.js (Scalekit)

## Choose a mode
Ask: "Are we scaffolding a brand-new MCP server repo, or adding MCP auth into an existing Express app?"
- Mode A: New project scaffold (recommended for demos/POCs)
- Mode B: Retrofit existing Express app (recommended for real products)

## Inputs to collect (ask if missing)
- Server base URL and port; confirm whether trailing slash is required for the audience (example: http://localhost:3002/)
- SK_ENV_URL, SK_CLIENT_ID, SK_CLIENT_SECRET
- PROTECTED_RESOURCE_METADATA JSON (copied from Scalekit dashboard MCP server page)
- EXPECTED_AUDIENCE (must match the Server URL registered in Scalekit)

## Required outcomes
1) Public discovery endpoint: GET /.well-known/oauth-protected-resource (returns PROTECTED_RESOURCE_METADATA as JSON)
2) Public health endpoint: GET /health
3) Auth middleware: validates Authorization: Bearer <token>, returns 401 + WWW-Authenticate with resource_metadata URL on failure
4) MCP endpoint: POST / protected by middleware, handled via MCP SDK StreamableHTTPServerTransport
5) At least one tool registered with server.tool(...)

---

# Mode A — Scaffold a new project

## Steps
1) Create a folder and initialize dependencies using templates in:
- assets/new-project/package.json
- assets/new-project/tsconfig.json
- assets/new-project/src/server.ts

2) Create .env using assets/env.example (fill real values).

3) Run:
- npm install
- npm run dev

## Notes
- Ensure EXPECTED_AUDIENCE exactly matches the Scalekit "Server URL" (including trailing slash if used).
- Keep /.well-known/oauth-protected-resource public; MCP clients need it for discovery.

---

# Mode B — Retrofit an existing Express app

## Identify insertion points
Ask for:
- Existing server entrypoint file (e.g., src/index.ts or src/server.ts)
- Current app router structure and whether POST / is already used
- Existing auth middlewares and CORS settings

## Patch plan (minimal diffs)
1) Add env vars (SK_*, EXPECTED_AUDIENCE, PROTECTED_RESOURCE_METADATA).
2) Add routes:
- GET /.well-known/oauth-protected-resource (public)
- GET /health (public)
3) Add auth middleware (public-path exemptions + Bearer extraction + validateToken with audience).
4) Add MCP server + route:
- Create McpServer + tools (assets/retrofit/mcp-server.ts)
- Add POST handler (assets/retrofit/mcp-route.ts)
5) Route mounting:
- If POST / is free, mount MCP at /
- If POST / is used, mount MCP at /mcp and update RESOURCE_METADATA_URL accordingly (and ensure clients point to correct MCP URL)

## Templates
- Auth middleware: assets/retrofit/auth-middleware.ts
- Well-known route: assets/retrofit/well-known-route.ts
- MCP server + tool registration: assets/retrofit/mcp-server.ts
- MCP POST handler: assets/retrofit/mcp-route.ts

---

## Verification checklist
- GET /.well-known/oauth-protected-resource works without Authorization header
- POST MCP endpoint without token -> 401 + WWW-Authenticate (resource_metadata points to the well-known URL)
- Valid token with correct audience -> MCP tool call succeeds
- Wrong-audience token -> 401

See references/TROUBLESHOOTING.md for common misconfigurations.
