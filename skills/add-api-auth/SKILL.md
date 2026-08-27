---
name: add-api-auth
description: >
  Adds API key or client-credentials auth so an agent
  can protect an API.
  Use when the user wants an API key or client credentials.
  It does not put OAuth 2.1 on an MCP server (that's `add-mcp-oauth`)
  or write SaaSKit login (that's `implement-saaskit`).
---

# Add API auth

Add an API key or client credentials to protect an API. Then stop.

## Guardrails

- **MUST** read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET` from env. **MUST NOT** hardcode them.
- **MUST** validate the token server-side on every request. Return 401 on invalid, expired, or revoked.
- **MUST** show plain-text `token` / `plainSecret` once. Store `tokenId` for list and invalidate. **MUST NOT** log or commit the secret.

## Gotchas

- Default language is Node. Default path is an org-scoped opaque API key.
- Client credentials / M2M JWT is a different API. Open [references/client-credentials.md](references/client-credentials.md). Do not call `createToken` on that path.
- Python, Go, or Java → open [references/languages.md](references/languages.md).
- Never `SCALEKIT_ENV_URL`. Do not prepend `https://` if the env URL already has a scheme.
- Copy the organization ID from the dashboard. Do not invent `org_…` values.
- `scalekit.token.validateToken` is for opaque keys. `scalekit.validateToken` is for JWTs. Do not mix them.
- Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet.

## Step 1 — Pick the path

- Client credentials, M2M JWT, or `/oauth/token` → open [references/client-credentials.md](references/client-credentials.md). Stay on that file.
- Anything else → stay here. Default is an org-scoped API key.

If env is missing, collect the three values from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Copy the organization ID from Organizations.

**Done when:** this skill is the right path, the three env names exist, and an organization ID is copied from the dashboard.

## Step 2 — Init the SDK

Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet.

```js
import { ScalekitClient, ScalekitValidateTokenFailureException } from '@scalekit-sdk/node';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);
```

**Done when:** the client initializes from those env vars.

## Step 3 — Create an org-scoped key

`organizationId` is the dashboard value from Step 1.

```js
const response = await scalekit.token.createToken(organizationId, {
  description: 'CI/CD pipeline token',
});
const opaqueToken = response.token;
const tokenId = response.tokenId;
```

Show `token` once. Store `tokenId` (`apit_…`). Scalekit cannot return the secret later.

**Done when:** the user saw `token` once, and the app stored `tokenId`.

## Step 4 — Validate on every request

```js
async function authenticateToken(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'Missing authorization token' });
  try {
    const result = await scalekit.token.validateToken(token);
    req.tokenInfo = result.tokenInfo;
    next();
  } catch (error) {
    if (error instanceof ScalekitValidateTokenFailureException) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
    throw error;
  }
}

app.get('/api/resources', authenticateToken, (req, res) => {
  const { organizationId, userId } = req.tokenInfo;
});
```

**Done when:** a protected `/api` route calls `validateToken` before the handler, and invalid keys return 401.

## Step 5 — List and invalidate

```js
const listed = await scalekit.token.listTokens(organizationId, { pageSize: 10 });
await scalekit.token.invalidateToken(tokenId);
```

Invalidate is instant and idempotent. Rotate: create new → update consumer → verify → invalidate old.

**Done when:** the app can list keys and invalidate one.

## Step 6 — Stop

Do not write MCP OAuth or SaaSKit login.

**Done when:** create, validate, list, and invalidate are in the repo, and this skill has stopped.

## Reach for

- `setup-saaskit` if env is missing
- `add-mcp-oauth` to put OAuth 2.1 on an MCP server
- `implement-saaskit` for SaaSKit login
- [references/client-credentials.md](references/client-credentials.md) for M2M JWT
- [references/languages.md](references/languages.md) for Python, Go, Java, or a user-scoped key

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- API keys: https://docs.scalekit.com/authenticate/m2m/api-keys/
- Client credentials: https://docs.scalekit.com/authenticate/m2m/api-auth-quickstart/
- MCP: https://mcp.scalekit.com
