---
name: implement-access-control
description: >
  Implements roles and permissions at a route so an agent
  can protect an endpoint.
  Use when the user wants roles, permissions, or RBAC.
  It does not write SaaSKit login (that's `implement-saaskit`).
---

# Implement access control

Put roles and permissions on a route. Then stop.

## Guardrails

- **MUST** call `validateToken` before reading `roles` or `permissions`.
- **MUST** enforce the check on the server at the route. Client checks are UX only.
- **MUST** return 403 when the required role or permission is missing. Never default to allow.
- **MUST** mount the validator before `requireRole` / `requirePermission`.
- **MUST NOT** write login, callback, or logout. Name `implement-saaskit` instead.

## Gotchas

- Login must already exist. If it does not, name `implement-saaskit` and stop.
- Default language is Node. Same client as `implement-saaskit`.
- Read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`. Never `SCALEKIT_ENV_URL`.
- Express: read `req.cookies.accessToken` as-is (`path: '/api'`). Do not `decrypt` unless `manage-saaskit-sessions` already encrypts that same cookie.
- Next.js: read `getSession().accessToken` from `scalekit_session`. Do not add an `accessToken` cookie.
- Django, FastAPI, or Flask: check `user["roles"]` from `requires_auth`. Do not add an `accessToken` cookie.
- `validateToken` validates and returns claims. Do not decode the JWT yourself. Node has no `validateAccessTokenAndGetClaims`.
- Claims: `roles` and `permissions` are string arrays. `sub` is the user. `oid` is the org.
- Scalekit already assigns `admin` to the first user in an org and `member` to the rest.
- Permissions use `resource:action` (example: `projects:read`).
- Protect `/api/*` so the Express access cookie is sent. SPA: read `Authorization: Bearer` instead.

## Step 1 — Confirm login and roles

If the app has no SaaSKit login, name `implement-saaskit` and stop.

- Express → stay here. Read the `accessToken` cookie.
- Next.js App Router → stay here. Read `getSession().accessToken` from `scalekit_session`.
- Django, FastAPI, or Flask → stay here. Check `user["roles"]` from `requires_auth`.

Print this checklist. Wait for the user. Then continue.

1. [app.scalekit.com](https://app.scalekit.com) → Roles & Permissions
2. Confirm `admin` and `member` exist. Add a permission such as `projects:read` only if the route needs one.

Do not invent role names.

**Done when:** login exists and the dashboard shows the roles this route will check.

## Step 2 — Init the SDK

Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet. Reuse `cookieParser()` from `implement-saaskit`.

```js
import { ScalekitClient } from '@scalekit-sdk/node';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);
```

**Done when:** the client initializes from those env vars.

## Step 3 — Validate and attach claims

```js
export async function requireAuth(req, res, next) {
  const accessToken = req.cookies?.accessToken;
  if (!accessToken) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  try {
    const claims = await scalekit.validateToken(accessToken);
    req.user = {
      id: claims.sub,
      organizationId: claims.oid,
      roles: claims.roles || [],
      permissions: claims.permissions || [],
    };
    return next();
  } catch {
    return res.status(401).json({ error: 'Authentication failed' });
  }
}
```

SPA: read the Bearer token from `Authorization` instead of the cookie.

**Done when:** a missing token returns 401, and a valid token sets `req.user.roles` and `req.user.permissions`.

## Step 4 — Require a role or permission at the route

```js
const hasRole = (user, role) => user.roles?.includes(role);
const requireRole = (role) => (req, res, next) =>
  hasRole(req.user, role)
    ? next()
    : res.status(403).json({ error: `Access denied. Required role: ${role}` });

const hasPermission = (user, perm) => user.permissions?.includes(perm);
const requirePermission = (perm) => (req, res, next) =>
  hasPermission(req.user, perm)
    ? next()
    : res.status(403).json({ error: `Access denied. Required permission: ${perm}` });

app.get('/api/admin/users', requireAuth, requireRole('admin'), (req, res) => {
  res.json({ ok: true, org: req.user.organizationId });
});
app.get('/api/projects', requireAuth, requirePermission('projects:read'), (req, res) => {
  res.json({ ok: true, org: req.user.organizationId });
});
```

Mount `requireAuth` before the role or permission guard.

**Done when:** those two GET routes exist and the guards run before the handler.

## Step 5 — Verify

Use GET. Send the same cookie the browser has after login.

```bash
curl -H "Cookie: accessToken=<cookie_from_login>" http://localhost:3000/api/admin/users
# admin session → 200
# member session → 403

curl http://localhost:3000/api/admin/users
# missing token → 401
```

**Done when:** admin is 200, member is 403, and a missing token is 401.

## Step 6 — Stop

Do not write login. Do not add refresh or revoke.

**Done when:** a route checks a role or permission, the curls match Step 5, and this skill has stopped.

## Reach for

- `implement-saaskit` for login, callback, cookies, and logout
- `manage-saaskit-sessions` to store, validate, refresh, or revoke
- `implement-scim` to provision users from a directory

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Access control: https://docs.scalekit.com/authenticate/authz/implement-access-control/
- Token claims: https://docs.scalekit.com/authenticate/fsa/session-token-claims/
- MCP: https://mcp.scalekit.com
