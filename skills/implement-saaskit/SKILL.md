---
name: implement-saaskit
description: >
  Implements SaaSKit login so an agent can add a login
  route, a callback, session cookies, and logout.
  Use when the user wants to add SaaSKit login, a
  callback, or logout.
  It does not store, validate, refresh, or revoke a
  session after login (that's `manage-saaskit-sessions`)
  or write Next.js App Router auth (that's `implement-saaskit-nextjs`)
  or write Django, FastAPI, or Flask auth (that's `implement-saaskit-python`).
---

# Implement SaaSKit

Add login, callback, session cookies, and logout. Then stop.

## Guardrails

- **MUST** validate tokens server-side. **MUST NOT** trust raw JWT claims. **MUST NOT** put tokens in localStorage.
- **MUST** keep `redirectUri` identical to the dashboard Allowed callback URL.
- **MUST NOT** write refresh middleware, remote revoke, or a session list. Name `manage-saaskit-sessions` instead.

## Gotchas

- `setup-saaskit` already wrote env and registered the redirect. Start there.
- Read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, and `SCALEKIT_REDIRECT_URI`. Never `SCALEKIT_ENV_URL`.
- Default language is Node. `setup-saaskit` already printed a Node login URL.
- Next.js App Router → name `implement-saaskit-nextjs` and stop.
- Django, FastAPI, or Flask → name `implement-saaskit-python` and stop.
- Go, Java, or Laravel → stay on this Node path. Open [references/go.md](references/go.md), [references/java.md](references/java.md), or [references/laravel.md](references/laravel.md) only when the repo is that stack.
- Mount `cookieParser()` before the auth routes. Logout reads `req.cookies.idToken`.
- Cookies: `HttpOnly`, `Secure` in production, `sameSite: 'lax'`. `strict` breaks the OAuth callback.
- Path-scope access to `/api` and refresh to `/auth/refresh` if you set both.
- `/dashboard` does not receive the access cookie. Protect `/api/*` only. The page calls `/api`.
- `getLogoutUrl` takes one object: `{ idTokenHint, postLogoutRedirectUri }`. The URL is one-time.
- Register that same post-logout URL in the dashboard: Authentication → Redirect URLs → Post logout URLs.

## Step 1 — Pick the path

- Next.js App Router → name `implement-saaskit-nextjs`. Stop.
- Django, FastAPI, or Flask → name `implement-saaskit-python`. Stop.
- Anything else → stay here. Default snippets are Node.

If env is missing, collect the four values from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Register `SCALEKIT_REDIRECT_URI` under Authentication → Redirect URLs → Allowed callback URLs. Do not invent values.

**Done when:** this skill is the right path, and the four env names exist.

## Step 2 — Init the SDK

Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet. Install `cookie-parser` if Express has no cookie parser yet.

```js
import { ScalekitClient } from '@scalekit-sdk/node';
import cookieParser from 'cookie-parser';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);
const redirectUri = process.env.SCALEKIT_REDIRECT_URI;
app.use(cookieParser());
```

**Done when:** the client initializes from those env vars.

## Step 3 — Login route

```js
app.get('/auth/login', (req, res) => {
  const authorizationUrl = scalekit.getAuthorizationUrl(redirectUri, {
    scopes: ['openid', 'profile', 'email', 'offline_access']
  });
  res.redirect(authorizationUrl);
});
```

**Done when:** `/auth/login` redirects to that URL.

## Step 4 — Callback and session cookies

Use the same `redirectUri` as Step 3. Then redirect off `/auth/callback`.

```js
app.get('/auth/callback', async (req, res) => {
  const { code } = req.query;
  const { idToken, accessToken, refreshToken, expiresIn } =
    await scalekit.authenticateWithCode(code, redirectUri);

  res.cookie('accessToken', accessToken, {
    maxAge: (expiresIn - 60) * 1000,
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/api',
  });
  res.cookie('refreshToken', refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/auth/refresh',
  });
  res.cookie('idToken', idToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
  });
  res.redirect('/dashboard');
});
```

| Token | Purpose |
|---|---|
| `idToken` | User profile. Keep it for logout. |
| `accessToken` | Short-lived. Roles and permissions. |
| `refreshToken` | Long-lived. Used later to renew access. |

Do not validate or refresh here. That is `manage-saaskit-sessions`.

**Done when:** the callback exchanges `code`, sets the three cookies, and the browser leaves `/auth/callback`.

## Step 5 — Logout

Clear the cookies from Step 4, then redirect to Scalekit. The logout URL is one-time.

```js
app.get('/auth/logout', (req, res) => {
  const idTokenHint = req.cookies.idToken;
  res.clearCookie('accessToken', { path: '/api' });
  res.clearCookie('refreshToken', { path: '/auth/refresh' });
  res.clearCookie('idToken', { path: '/' });
  const postLogoutRedirectUri = `${req.protocol}://${req.get('host')}`;
  const logoutUrl = scalekit.getLogoutUrl({
    idTokenHint,
    postLogoutRedirectUri,
  });
  res.redirect(logoutUrl);
});
```

Register that same origin as a Post logout URL. Local default is `http://localhost:3000`.

**Done when:** cookies are gone and the browser hits the logout URL.

## Step 6 — Name the next skill and stop

Name `manage-saaskit-sessions` for store, validate, refresh, and revoke.

**Done when:** `manage-saaskit-sessions` is named, and this skill has stopped.

## Reach for

- `setup-saaskit` if env or the redirect URI is missing
- `manage-saaskit-sessions` to store, validate, refresh, or revoke
- `implement-saaskit-nextjs` for Next.js App Router
- `implement-saaskit-python` for Django, FastAPI, or Flask
- [references/go.md](references/go.md) for Go
- [references/java.md](references/java.md) for Spring Boot
- [references/laravel.md](references/laravel.md) for Laravel

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Auth flow: https://docs.scalekit.com/authenticate/fsa/quickstart/
- Sessions: https://docs.scalekit.com/authenticate/fsa/sessions/
- MCP: https://mcp.scalekit.com
