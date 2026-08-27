---
name: implement-saaskit-nextjs
description: >
  Implements SaaSKit login in the Next.js App Router
  so an agent can add login, callback, session cookies,
  and logout.
  Use when the user wants SaaSKit Next.js or App Router
  auth.
  It does not write generic Node login (that's `implement-saaskit`)
  or write Django, FastAPI, or Flask auth
  (that's `implement-saaskit-python`).
---

# Implement SaaSKit Next.js
Add login, callback, a `scalekit_session` cookie, logout, and refresh in the App Router. Then stop.

## Guardrails
- **MUST** re-check the session in Server Components. Middleware cookie-presence is not enough.
- **MUST** keep `redirectUri` identical to the dashboard Allowed callback URL.
- **MUST** set `sameSite: 'lax'` on every auth cookie. **MUST NOT** use `'strict'` — it drops the cookie on the OAuth callback.
- **MUST** treat `next` as a relative path only (`/...`, not `//…`). **MUST NOT** redirect to an arbitrary URL.

## Gotchas
- `setup-saaskit` already wrote env and registered the redirect. Start there.
- Read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, and `SCALEKIT_REDIRECT_URI`. Never `SCALEKIT_ENV_URL`. Do not prepend `https://`.
- One `scalekit_session` JSON HttpOnly cookie. Do not copy Express path-scoped cookies from `implement-saaskit`.
- `ScalekitClient` is Node-only. Do not import it in `middleware.ts` (Edge).
- FSA scopes include `offline_access`. `refreshAccessToken` returns `{ accessToken, refreshToken }` only.
- `getLogoutUrl({ idTokenHint, postLogoutRedirectUri })`. Register that post-logout URL.

## Step 1 — Pick the path

- App Router → stay here.
- Pages Router or not Next.js → name `implement-saaskit`. Stop.
- Django, FastAPI, or Flask → name `implement-saaskit-python`. Stop.

If env is missing, collect the four values from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Register `SCALEKIT_REDIRECT_URI` under Authentication → Redirect URLs → Allowed callback URLs. Do not invent values.

**Done when:** this skill is the right path, and the four env names exist.

## Step 2 — Init the SDK and session cookie

Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet. Do not add `jose` or `cookie-parser`.

```ts
// lib/scalekit.ts
import { ScalekitClient } from '@scalekit-sdk/node';
export const scalekit = new ScalekitClient(process.env.SCALEKIT_ENVIRONMENT_URL, process.env.SCALEKIT_CLIENT_ID, process.env.SCALEKIT_CLIENT_SECRET);
export const redirectUri = process.env.SCALEKIT_REDIRECT_URI;
```

```ts
// lib/session.ts — one scalekit_session JSON cookie
import { cookies } from 'next/headers';
const NAME = 'scalekit_session';
const opts = { httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax' as const, path: '/' };
export async function getSession() {
  try { return JSON.parse((await cookies()).get(NAME)?.value ?? ''); } catch { return null; }
}
export async function setSession(data: object) {
  (await cookies()).set(NAME, JSON.stringify(data), { ...opts, maxAge: 30 * 24 * 60 * 60 });
}
export async function clearSession() { (await cookies()).delete(NAME); }
```

**Done when:** the client initializes from those env vars, and the app can read, write, and clear `scalekit_session`.

## Step 3 — Login

`app/auth/login/route.ts` — GET. Link to `/auth/login`. Do not `router.push` to Scalekit.

```ts
import { NextResponse } from 'next/server';
import { scalekit, redirectUri } from '@/lib/scalekit';
export async function GET(request: Request) {
  const next = new URL(request.url).searchParams.get('next');
  const dest = next?.startsWith('/') && !next.startsWith('//') ? next : '/dashboard';
  const state = crypto.randomUUID();
  const res = NextResponse.redirect(scalekit.getAuthorizationUrl(redirectUri, {
    state, scopes: ['openid', 'profile', 'email', 'offline_access'],
  }));
  const cookie = { httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax' as const, path: '/', maxAge: 600 };
  res.cookies.set('oauth_state', state, cookie);
  res.cookies.set('oauth_next', dest, cookie);
  return res;
}
```

**Done when:** `/auth/login` redirects to that URL.

## Step 4 — Callback

Put this route at the path in `SCALEKIT_REDIRECT_URI`. Default is `/auth/callback` → `app/auth/callback/route.ts`. Same `redirectUri` as Step 3.

```ts
import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { scalekit, redirectUri } from '@/lib/scalekit';
import { setSession } from '@/lib/session';
export async function GET(request: Request) {
  const url = new URL(request.url);
  const jar = await cookies();
  const next = jar.get('oauth_next')?.value ?? '';
  const dest = next.startsWith('/') && !next.startsWith('//') ? next : '/dashboard';
  if (!url.searchParams.get('code') || url.searchParams.get('state') !== jar.get('oauth_state')?.value) {
    return NextResponse.redirect(new URL('/auth/login', url.origin));
  }
  const { user, idToken, accessToken, refreshToken, expiresIn } =
    await scalekit.authenticateWithCode(url.searchParams.get('code')!, redirectUri);
  await setSession({ user, idToken, accessToken, refreshToken, expiresAt: Math.floor(Date.now() / 1000) + expiresIn });
  const res = NextResponse.redirect(new URL(dest, url.origin));
  res.cookies.delete('oauth_state');
  res.cookies.delete('oauth_next');
  return res;
}
```

**Done when:** the callback exchanges `code`, writes `scalekit_session`, and the browser leaves `/auth/callback`.

## Step 5 — Logout

`app/auth/logout/route.ts` — GET. Link to `/auth/logout`. Register the origin as a Post logout URL (local default `http://localhost:3000`).

```ts
import { NextResponse } from 'next/server';
import { scalekit } from '@/lib/scalekit';
import { getSession, clearSession } from '@/lib/session';
export async function GET(request: Request) {
  const session = await getSession();
  await clearSession();
  return NextResponse.redirect(scalekit.getLogoutUrl({
    idTokenHint: session?.idToken, postLogoutRedirectUri: new URL(request.url).origin,
  }));
}
```

**Done when:** `scalekit_session` is gone and the browser hits the logout URL.

## Step 6 — Refresh

`manage-saaskit-sessions` is Express path-scoped cookies. Stay here. `app/auth/refresh/route.ts` — POST.

```ts
import { NextResponse } from 'next/server';
import { scalekit } from '@/lib/scalekit';
import { getSession, setSession } from '@/lib/session';
export async function POST() {
  const session = await getSession();
  if (!session?.refreshToken) return NextResponse.json({ error: 'no session' }, { status: 401 });
  try {
    const { accessToken, refreshToken } = await scalekit.refreshAccessToken(session.refreshToken);
    await setSession({ ...session, accessToken, refreshToken, expiresAt: Math.floor(Date.now() / 1000) + 240 });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: 'refresh failed' }, { status: 401 });
  }
}
```

Default path: if `expiresAt` is past, a Client Component runs `fetch('/auth/refresh', { method: 'POST' })` and retries. Failed → `/auth/login`. Keep 401 only for a later `/api` route.

**Done when:** a past `expiresAt` POSTs `/auth/refresh`, and a failed refresh returns 401.

## Step 7 — Protect pages

Put `middleware.ts` at the project root. It runs first. Check cookie presence only. Do not import `ScalekitClient`.

```ts
import { NextResponse, type NextRequest } from 'next/server';
export function middleware(request: NextRequest) {
  const path = request.nextUrl.pathname;
  if (path.startsWith('/dashboard') && !request.cookies.get('scalekit_session')) {
    const login = new URL('/auth/login', request.url);
    login.searchParams.set('next', path);
    return NextResponse.redirect(login);
  }
  return NextResponse.next();
}
```

Then re-check: `const session = await getSession(); if (!session?.accessToken) redirect('/auth/login');` If `session.expiresAt` is past, a Client Component POSTs `/auth/refresh` and retries.

**Done when:** a missing cookie hits `/auth/login`, the Server Component reads `getSession()`, and a past `expiresAt` refreshes.

## Step 8 — Stop

Do not write Express `cookie-parser` middleware or Python auth.

**Done when:** login, callback, `scalekit_session`, logout, and refresh are in the App Router, and this skill has stopped.

## Reach for

- `setup-saaskit` if env or the redirect URI is missing
- `implement-saaskit` for Node, Express, or Pages Router
- `implement-saaskit-python` for Django, FastAPI, or Flask

## Live lookups
- Docs index: https://docs.scalekit.com/llms.txt
- Auth flow: https://docs.scalekit.com/authenticate/fsa/quickstart/
- MCP: https://mcp.scalekit.com
