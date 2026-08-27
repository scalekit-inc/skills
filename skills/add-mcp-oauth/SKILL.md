---
name: add-mcp-oauth
description: >
  Adds MCP OAuth so an agent can protect the user's
  MCP server.
  Use when the user wants MCP OAuth or to protect
  their MCP server.
  It does not add API keys or client credentials
  (that's `add-api-auth`)
  or expose AgentKit tools over MCP
  (that's `expose-agentkit-mcp`).
---

# Add MCP OAuth

Put OAuth 2.1 on the user's MCP server. Then stop.

## Guardrails

- **MUST** use Streamable HTTP. stdio cannot do OAuth.
- **MUST** keep `/.well-known/oauth-protected-resource` public.
- **MUST** return 401 with `WWW-Authenticate` and `resource_metadata` on a missing or invalid token. A bare 401 is a host silent-fail.
- **MUST** call `validateToken` with the dashboard Server URL as `audience`.
- **MUST** register well-known, then Bearer middleware, then the MCP POST. A POST registered first never sees auth.

## Gotchas

- Default path is Node + Express + Streamable HTTP. FastAPI → open [references/fastapi.md](references/fastapi.md). FastMCP Scalekit provider → open [references/fastmcp.md](references/fastmcp.md). Stay on that file.
- Read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`. Never `SCALEKIT_ENV_URL`. Do not prepend `https://` — the env URL already has a scheme.
- Audience must match the dashboard **Server URL** exactly, including a trailing slash when the dashboard has one. If Server URL is empty, use the generated resource id.
- Paste the dashboard **Metadata JSON**. Do not build `authorization_servers` by adding a scheme onto `SCALEKIT_ENVIRONMENT_URL`.
- Reuse the existing Express `app` if the file has one. Do not create a second `express()` app.
- Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet. Always install Express and MCP packages the later steps import.

## Step 1 — Confirm Streamable HTTP

stdio cannot do OAuth. The default path is Express + `StreamableHTTPServerTransport` from `@modelcontextprotocol/sdk/server/streamableHttp.js`. FastAPI or FastMCP → open the matching file under `references/` and stay there.

Keep the user's tools. Do not invent a new MCP server if one already exists.

**Done when:** this skill is the right path, and the transport is Streamable HTTP (or Step 5 will add it).

## Step 2 — Install and init

Install only what the repo is missing. Later steps import all of these:

```bash
npm install @scalekit-sdk/node @modelcontextprotocol/sdk express
```

If env is missing, collect the three values from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials.

Put imports at the top of the file.

```js
import express from 'express';
import { ScalekitClient } from '@scalekit-sdk/node';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);
```

Reuse the existing Express `app` if the file has one. If there is no `app` yet:

```js
const app = express();
app.use(express.json());
```

Do not register the MCP POST here. That route goes on after the Bearer middleware in Step 5.

**Done when:** those packages are installed, and the client initializes from those env vars.

## Step 3 — Register the MCP server (user action)

Print this checklist. Wait. Do not invent dashboard clicks. Do not write code until the user confirms.

1. Open [app.scalekit.com](https://app.scalekit.com) → **MCP servers** → **Add MCP server**.
2. Enter a **name**.
3. Enable **dynamic client registration**.
4. Enable **Client ID Metadata Document (CIMD)**.
5. Set **Server URL** to the public MCP base URL (local default `http://localhost:3002/`, keep the trailing slash).
6. **Save**.
7. Copy **Metadata JSON** from **MCP servers → your server → Metadata JSON**.
8. Restart the MCP process after DCR or CIMD toggles.

Audience is that Server URL. If Server URL is empty, use the generated resource id.

**Done when:** the user confirmed the row, Metadata JSON is copied, and the Server URL (or resource id) is recorded.

## Step 4 — Public discovery endpoint

Serve the copied Metadata JSON at `/.well-known/oauth-protected-resource`. Keep this route public. Register it before the Bearer middleware.

```js
const metadata = /* paste dashboard Metadata JSON */;
app.get('/.well-known/oauth-protected-resource', (req, res) => {
  res.json(metadata);
});
```

If you must edit `authorization_servers`, join `SCALEKIT_ENVIRONMENT_URL` with `/resources/<RESOURCE_ID>`. Do not prepend `https://`.

**Done when:** that path returns the dashboard JSON with no auth.

## Step 5 — Bearer middleware, then MCP POST

Register order: well-known → this `auth` → MCP POST. Express runs handlers in registration order.

```js
const audience = 'http://localhost:3002/'; // dashboard Server URL
const metadataUrl = `${audience.replace(/\/$/, '')}/.well-known/oauth-protected-resource`;
const wwwAuthenticate = `Bearer realm="OAuth", resource_metadata="${metadataUrl}"`;

async function auth(req, res, next) {
  if (req.path.includes('.well-known')) return next();
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
  if (!token) return res.status(401).set('WWW-Authenticate', wwwAuthenticate).end();
  try {
    await scalekit.validateToken(token, { audience: [audience] });
    next();
  } catch {
    return res.status(401).set('WWW-Authenticate', wwwAuthenticate).end();
  }
}

app.use(auth);
```

If `POST /` (or the existing MCP path) is already on the stack, move it below `app.use(auth)`, or attach `auth` on that route: `app.post('/', auth, handler)`.

If the repo has no Streamable HTTP route yet, add it now. Keep an existing path if the server already has one. Default is `POST /`.

```js
const server = new McpServer({ name: 'mcp-server', version: '1.0.0' });

app.post('/', async (req, res) => {
  const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
  await server.connect(transport);
  await transport.handleRequest(req, res, req.body);
});
```

If the file has no listener, add `app.listen(Number(process.env.PORT) || 3002)`. Reuse an existing listener.

**Done when:** `auth` sits above the MCP POST, a request without a token returns 401 with `WWW-Authenticate` and `resource_metadata`, and a listener is on 3002 (or `PORT`).

## Step 6 — Optional scopes

If the user asked for tool-level scopes, re-validate with `requiredScopes`. Extra Express notes: [references/express.md](references/express.md).

```js
await scalekit.validateToken(token, {
  audience: [audience],
  requiredScopes: ['todo:write'],
});
```

Insufficient scope → 403 `insufficient_scope`.

**Done when:** scopes are skipped, or a tool checks `requiredScopes`.

## Step 7 — Verify

```bash
curl -i -X POST http://localhost:3002/
curl -i http://localhost:3002/.well-known/oauth-protected-resource
```

Use the real MCP path if it is not `/`. Expect 401 + `WWW-Authenticate` with `resource_metadata` on the MCP POST, and JSON with `resource`, `authorization_servers`, and `scopes_supported` on well-known.

**Done when:** both curls pass.

## Step 8 — Stop

Do not write API keys. Do not expose AgentKit tools over MCP.

**Done when:** well-known is public, Bearer middleware validates audience, verify passed, and this skill has stopped.

## Reach for

- `setup-saaskit` if env is missing
- `add-api-auth` for API keys or client credentials
- `expose-agentkit-mcp` to expose AgentKit tools over MCP
- [references/express.md](references/express.md) for Express extras
- [references/fastapi.md](references/fastapi.md) for FastAPI
- [references/fastmcp.md](references/fastmcp.md) for the FastMCP Scalekit provider

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- MCP OAuth: https://docs.scalekit.com/authenticate/mcp/quickstart/
- MCP: https://mcp.scalekit.com
