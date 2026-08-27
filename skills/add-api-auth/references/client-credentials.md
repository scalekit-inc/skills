# Client credentials (M2M JWT)

Use this file when the user wants client credentials, M2M JWT, or `/oauth/token`. Do not call `createToken` / `token.validateToken`. Those APIs are for opaque keys.

Default language is Node. Same env names as `SKILL.md`. Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet. This path does not need `jwks-rsa` or `jsonwebtoken`.

Copy the organization ID from the dashboard. Do not invent `org_…` values.

## Step 1 — Init the SDK

```js
import { ScalekitClient, ScalekitValidateTokenFailureException } from '@scalekit-sdk/node';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);
```

**Done when:** the client initializes from those env vars.

## Step 2 — Register an M2M client

```js
const created = await scalekit.m2m.createOrganizationClient(organizationId, {
  name: 'GitHub Actions Deployment Service',
  description: 'Deploys to production via GitHub Actions',
  scopes: ['deploy:applications', 'read:deployments'],
  audience: ['deployment-api.example.com'],
  customClaims: { environment: 'production' },
});
const clientId = created.client.clientId;
const plainSecret = created.plainSecret;
```

Show `plainSecret` once. Store `clientId` (`m2morg_…`). Scalekit cannot return the secret later.

**Done when:** the user saw `plainSecret` once, and the app stored `clientId`.

## Step 3 — The API client fetches a JWT

This runs in the **caller's** code, not your API server.

```sh
curl -X POST "$SCALEKIT_ENVIRONMENT_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=<API_CLIENT_ID>" \
  -d "client_secret=<API_CLIENT_SECRET>"
```

Response has `access_token` (JWT), `token_type`, `expires_in`, and `scope`. The caller sends `Authorization: Bearer <access_token>`.

**Done when:** `/oauth/token` returns a JWT for those client credentials.

## Step 4 — Validate the JWT on every request

Use `scalekit.validateToken`. That is the JWT helper. It is not `scalekit.token.validateToken`.

```js
function requireScope(scope) {
  return async (req, res, next) => {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!token) return res.status(401).json({ error: 'Missing token' });
    try {
      const claims = await scalekit.validateToken(token, {
        requiredScopes: [scope],
      });
      req.tokenClaims = claims;
      next();
    } catch (error) {
      if (error instanceof ScalekitValidateTokenFailureException) {
        return res.status(401).json({ error: 'Invalid or expired token' });
      }
      throw error;
    }
  };
}

app.get('/api/deployments', requireScope('read:deployments'), (req, res) => {
  // req.tokenClaims.scopes, req.tokenClaims.oid
});
```

Missing required scopes also throw `ScalekitValidateTokenFailureException`. Return 401. Optional: pass `audience: ['deployment-api.example.com']` if you set audience in Step 2.

**Done when:** a protected `/api` route calls `validateToken` before the handler, and a bad JWT returns 401.

## Step 5 — Stop

Do not write opaque-key `createToken` code. Do not write MCP OAuth or SaaSKit login.

**Done when:** register, token fetch, and JWT validate are in the repo, and this skill has stopped.

## Python (same path)

Constructor arg is `env_url`. Env name is `SCALEKIT_ENVIRONMENT_URL`. `create_organization_client` uses `.with_call`, so the return is a tuple.

```python
import os
from scalekit import ScalekitClient
from scalekit.v1.clients.clients_pb2 import OrganizationClient

scalekit_client = ScalekitClient(
    env_url=os.environ["SCALEKIT_ENVIRONMENT_URL"],
    client_id=os.environ["SCALEKIT_CLIENT_ID"],
    client_secret=os.environ["SCALEKIT_CLIENT_SECRET"],
)
response, _call = scalekit_client.m2m_client.create_organization_client(
    organization_id=organization_id,
    m2m_client=OrganizationClient(
        name="GitHub Actions Deployment Service",
        scopes=["deploy:applications", "read:deployments"],
        audience=["deployment-api.example.com"],
        expiry=3600,
    ),
)
client_id = response.client.client_id
plain_secret = response.plain_secret
claims = scalekit_client.validate_access_token_and_get_claims(token=access_token)
```

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Client credentials: https://docs.scalekit.com/authenticate/m2m/api-auth-quickstart/
- MCP: https://mcp.scalekit.com
