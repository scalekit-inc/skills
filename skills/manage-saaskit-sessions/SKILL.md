---
name: manage-saaskit-sessions
description: >
  Manages SaaSKit sessions so an agent can store,
  validate, refresh, and revoke a session.
  Use when the user wants a session, refresh, or
  revoke.
  It does not write login, callback, or logout
  (that's `implement-saaskit`).
---

# Manage SaaSKit sessions

Store, validate, refresh, and revoke a session. Then stop.

## Guardrails

- **MUST** validate the access token on every protected request.
- **MUST** return 401 when refresh fails. **MUST NOT** continue the request.
- **MUST NOT** write login, callback, or the logout redirect. Name `implement-saaskit` instead.
- **MUST NOT** put the access token in localStorage.

## Gotchas

- Default language is Node. Same client as `implement-saaskit`.
- Traditional web: HttpOnly cookies. SPA: access token in memory + `Authorization: Bearer`; refresh in an HttpOnly cookie or a secure store.
- Cookies: `HttpOnly`, `Secure` in production, `sameSite: 'lax'`. Path-scope access to `/api` and refresh to `/auth/refresh`.
- `encrypt` and `decrypt` in the snippets are app-owned helpers, not Scalekit SDK methods.
- `refreshAccessToken` returns `{ accessToken, refreshToken }` only. Reuse a short access-cookie lifetime.
- Remote revoke uses `scalekit.session.*`. That is not the logout redirect.
- Dashboard session timeouts live at https://docs.scalekit.com/authenticate/fsa/sessions/. Do not cache that page.

## Step 1 — Store tokens

After `implement-saaskit` has tokens, persist them.

Traditional web:

```js
res.cookie('accessToken', encrypt(accessToken), {
  maxAge: (expiresIn - 60) * 1000,
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'lax',
  path: '/api',
});
res.cookie('refreshToken', encrypt(refreshToken), {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'lax',
  path: '/auth/refresh',
});
```

SPA: keep the access token in memory. Send `Authorization: Bearer`. Store the refresh token in an HttpOnly cookie or a secure store.

**Done when:** tokens are stored by app type.

## Step 2 — Validate on every protected request

```js
import { ScalekitClient } from '@scalekit-sdk/node';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);

export async function verifySession(req, res, next) {
  const accessCookie = req.cookies?.accessToken;
  if (!accessCookie) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  const isValid = await scalekit.validateAccessToken(decrypt(accessCookie));
  if (isValid) return next();
  return res.status(401).json({ error: 'Session expired' });
}
```

SPA: read the Bearer token from `Authorization`. Do not read an access-token cookie.

**Done when:** a protected route calls `validateAccessToken` before the handler.

## Step 3 — Refresh at `/auth/refresh`

The refresh cookie is path-scoped to this route.

```js
app.post('/auth/refresh', async (req, res) => {
  const refreshCookie = req.cookies?.refreshToken;
  if (!refreshCookie) {
    return res.status(401).json({ error: 'Session expired. Please sign in again.' });
  }
  try {
    const authResult = await scalekit.refreshAccessToken(decrypt(refreshCookie));
    res.cookie('accessToken', encrypt(authResult.accessToken), {
      maxAge: 4 * 60 * 1000,
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/api',
    });
    res.cookie('refreshToken', encrypt(authResult.refreshToken), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/auth/refresh',
    });
    return res.json({ ok: true });
  } catch (e) {
    return res.status(401).json({ error: 'Authentication failed' });
  }
});
```

SPA: return `{ accessToken: authResult.accessToken }` in the JSON body. The client updates memory. Do not set an access-token cookie.

**Done when:** a failed access token can refresh here, and a failed refresh returns 401.

## Step 4 — Revoke remotely

Use the session APIs. This is not logout.

```js
const sessionDetails = await scalekit.session.getSession('ses_1234567890123456');

const userSessions = await scalekit.session.getUserSessions('usr_1234567890123456', {
  pageSize: 10,
  filter: { status: ['active'] },
});

await scalekit.session.revokeSession('ses_1234567890123456');
await scalekit.session.revokeAllUserSessions('usr_1234567890123456');
```

**Done when:** the app can list, revoke one, and revoke all.

## Step 5 — Stop

Do not write login, callback, or the logout redirect.

**Done when:** store, validate, refresh, and revoke are in the repo, and this skill has stopped.

## Reach for

- `implement-saaskit` for login, callback, cookies, and logout
- `setup-saaskit` if env is missing
- `implement-access-control` for roles and permissions

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Sessions: https://docs.scalekit.com/authenticate/fsa/sessions/
- MCP: https://mcp.scalekit.com
