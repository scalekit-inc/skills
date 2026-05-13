# Common Mistakes in Scalekit Code

This file catalogs known anti-patterns, hallucinated methods, and security issues found in Scalekit integrations. Each entry shows the wrong pattern and the correct fix. Use this as a lookup during both generation and review.

---

## 1. Wrong Import Paths

### Node.js

**Wrong:**
```typescript
import ScalekitClient from '@scalekit-sdk/node';        // default import
import { ScalekitClient } from 'scalekit';               // wrong package
import { ScalekitClient } from 'scalekit-sdk-node';      // wrong package
import { Scalekit } from '@scalekit-sdk/node';            // wrong export name
```

**Correct:**
```typescript
import { ScalekitClient } from '@scalekit-sdk/node';
```

Note: The REST API docs show `import { Scalekit } from "@scalekit-sdk/node"` — this is an alias that also works, but `ScalekitClient` is the canonical export used in the SDK source and REFERENCE.md.

### Python

**Wrong:**
```python
from scalekit_sdk import ScalekitClient    # wrong module name
from scalekit.client import ScalekitClient  # internal path, not public API
import scalekit                             # missing class import
pip install scalekit                        # wrong pip package name
```

**Correct:**
```python
from scalekit import ScalekitClient
# pip install scalekit-sdk-python
```

### Go

**Wrong:**
```go
import "github.com/scalekit-inc/scalekit-sdk-go"             // missing version
import "github.com/scalekit/scalekit-sdk-go/v2"              // wrong org name
```

**Correct:**
```go
import scalekit "github.com/scalekit-inc/scalekit-sdk-go/v2"
```

### Java

**Wrong:**
```java
import com.scalekit.sdk.ScalekitClient;    // wrong package path
import io.scalekit.ScalekitClient;         // wrong package
```

**Correct:**
```java
import com.scalekit.ScalekitClient;
```

---

## 2. Wrong Method Names

### Node.js

| Wrong | Correct | Notes |
|-------|---------|-------|
| `scalekit.authenticate(code)` | `scalekit.authenticateWithCode(code, redirectUri)` | Missing `WithCode` suffix and `redirectUri` param |
| `scalekit.getAuthUrl(...)` | `scalekit.getAuthorizationUrl(redirectUri, options?)` | Wrong method name |
| `scalekit.login(...)` | `scalekit.getAuthorizationUrl(redirectUri, options?)` | No `login` method |
| `scalekit.logout(...)` | `scalekit.getLogoutUrl(options?)` | Returns URL, doesn't perform logout |
| `scalekit.verifyToken(token)` | `scalekit.validateAccessToken(token)` or `scalekit.validateToken(token)` | Wrong name |
| `scalekit.createOrganization(...)` | `scalekit.organization.createOrganization(...)` | Must use sub-client |
| `scalekit.getOrganization(...)` | `scalekit.organization.getOrganization(...)` | Must use sub-client |

### Python

| Wrong | Correct | Notes |
|-------|---------|-------|
| `client.authenticateWithCode(...)` | `client.authenticate_with_code(...)` | Python uses snake_case |
| `client.getAuthorizationUrl(...)` | `client.get_authorization_url(...)` | Python uses snake_case |
| `client.getLogoutUrl(...)` | `client.get_logout_url(...)` | Python uses snake_case |
| `client.validateToken(...)` | `client.validate_access_token(...)` | Different method name in Python |
| `client.verify_webhook(...)` | `client.verify_webhook_payload(...)` | Missing `_payload` suffix |

### Go

| Wrong | Correct | Notes |
|-------|---------|-------|
| `client.AuthenticateWithCode(code, uri)` | `client.AuthenticateWithCode(ctx, code, uri, options)` | Missing `ctx` parameter |
| `client.GetAuthorizationUrl(uri)` | `client.GetAuthorizationUrl(uri, options)` | Missing `options` param (required in Go) |
| `client.Organization.Create(...)` | `client.Organization().CreateOrganization(ctx, request)` | Use accessor method `Organization()`, not field |

### Java

| Wrong | Correct | Notes |
|-------|---------|-------|
| `client.organization.create(...)` | `client.organizations().create(...)` | Use `organizations()` accessor method, plural |
| `client.getOrganization(id)` | `client.organizations().getById(id)` | Use sub-client accessor |
| `client.connections.list(...)` | `client.connections().listConnectionsByOrganization(orgId)` | Use accessor method |

---

## 3. Missing Required Parameters

### `authenticateWithCode` — missing `redirectUri`

**Wrong:**
```typescript
const result = await scalekit.authenticateWithCode(code);
```

**Correct:**
```typescript
const result = await scalekit.authenticateWithCode(code, redirectUri);
```

The `redirectUri` must exactly match the one used in `getAuthorizationUrl` AND what's registered in the Scalekit dashboard.

### `getAuthorizationUrl` — missing `state` for CSRF

**Wrong:**
```typescript
const authUrl = scalekit.getAuthorizationUrl(redirectUri);
```

**Correct:**
```typescript
import crypto from 'crypto';
const state = crypto.randomBytes(32).toString('base64url');
// Store state in session/cookie for validation in callback
const authUrl = scalekit.getAuthorizationUrl(redirectUri, { state });
```

While `state` is technically optional, omitting it is a **CSRF vulnerability**. Always generate and validate it.

### Go — missing `context.Context`

**Wrong:**
```go
resp, err := client.AuthenticateWithCode(code, redirectUri, opts)
```

**Correct:**
```go
resp, err := client.AuthenticateWithCode(ctx, code, redirectUri, opts)
```

All Go network methods require `context.Context` as the first parameter.

---

## 4. Auth Flow Gaps

### Missing callback handler

If you see a login route that generates an auth URL but no corresponding callback route, the flow is incomplete. The callback MUST:
1. Validate the `state` parameter against the stored value
2. Call `authenticateWithCode(code, redirectUri)`
3. Store the session (tokens + user info)
4. Redirect to the application

### Missing `state` validation in callback

**Wrong:**
```typescript
app.get('/auth/callback', async (req, res) => {
  const { code } = req.query;
  const result = await scalekit.authenticateWithCode(code, redirectUri);
  // ... store session
});
```

**Correct:**
```typescript
app.get('/auth/callback', async (req, res) => {
  const { code, state } = req.query;

  const storedState = req.session.oauthState; // or from cookie
  if (!state || state !== storedState) {
    return res.status(403).send('CSRF validation failed');
  }

  const result = await scalekit.authenticateWithCode(code, redirectUri);
  // ... store session
});
```

### Incomplete logout — only clearing local session

**Wrong:**
```typescript
app.post('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/');
});
```

**Correct:**
```typescript
app.post('/logout', (req, res) => {
  const logoutUrl = scalekit.getLogoutUrl({
    idTokenHint: req.session.idToken,
    postLogoutRedirectUri: 'https://yourapp.com',
  });
  req.session.destroy();
  res.redirect(logoutUrl); // Ends IdP session too
});
```

Without calling `getLogoutUrl()`, the user's IdP session persists and they get silently re-authenticated on next login.

### Missing IdP-initiated login handling

If the callback route doesn't check for `idp_initiated_login` query parameter, IdP-initiated SSO won't work:

```typescript
app.get('/auth/callback', async (req, res) => {
  const { idp_initiated_login, code, state } = req.query;

  if (idp_initiated_login) {
    const claims = await scalekit.getIdpInitiatedLoginClaims(idp_initiated_login);
    const authUrl = scalekit.getAuthorizationUrl(redirectUri, {
      connectionId: claims.connection_id,
      organizationId: claims.organization_id,
      loginHint: claims.login_hint,
      ...(claims.relay_state && { state: claims.relay_state }),
    });
    return res.redirect(authUrl);
  }

  // Normal SP-initiated flow continues...
});
```

---

## 5. Security Anti-Patterns

### `sameSite: 'strict'` on session cookies

**Wrong:**
```typescript
res.cookie('session', data, { sameSite: 'strict', httpOnly: true, secure: true });
```

**Correct:**
```typescript
res.cookie('session', data, { sameSite: 'lax', httpOnly: true, secure: true });
```

OAuth callbacks are cross-site redirects from Scalekit back to your app. `strict` drops the cookie on that redirect, causing CSRF state mismatch errors on every login.

### Missing `httpOnly` flag

**Wrong:**
```typescript
res.cookie('session', data, { secure: true });
```

**Correct:**
```typescript
res.cookie('session', data, { httpOnly: true, secure: true, sameSite: 'lax' });
```

Without `httpOnly`, JavaScript can read the session cookie — XSS becomes session hijacking.

### Open redirect via unvalidated `next` parameter

**Wrong:**
```typescript
const next = req.query.next;
res.redirect(next); // Attacker can set next=https://evil.com
```

**Correct:**
```typescript
const next = req.query.next;
// Only allow relative paths
if (!next || !next.startsWith('/') || next.startsWith('//')) {
  return res.redirect('/dashboard');
}
res.redirect(next);
```

### Hardcoded client secret

**Wrong:**
```typescript
const scalekit = new ScalekitClient(
  'https://myapp.scalekit.com',
  'skc_12345',
  'sks_secret_abc123'  // NEVER hardcode secrets
);
```

**Correct:**
```typescript
const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENV_URL!,
  process.env.SCALEKIT_CLIENT_ID!,
  process.env.SCALEKIT_CLIENT_SECRET!
);
```

### Webhook handler without signature verification

**Wrong:**
```typescript
app.post('/webhooks', express.json(), (req, res) => {
  const event = req.body;  // Trusting unverified payload
  handleEvent(event);
  res.sendStatus(200);
});
```

**Correct:**
```typescript
app.post('/webhooks', express.raw({ type: 'application/json' }), (req, res) => {
  const isValid = scalekit.verifyWebhookPayload(
    process.env.SCALEKIT_WEBHOOK_SECRET!,
    req.headers,
    req.body.toString()
  );

  if (!isValid) {
    return res.sendStatus(401);
  }

  const event = JSON.parse(req.body.toString());
  handleEvent(event);
  res.sendStatus(200);
});
```

Note: The webhook body must be raw (not JSON-parsed) for signature verification to work.

### Client-side navigation for OAuth redirect

**Wrong:**
```typescript
// React / Next.js
router.push(authUrl);  // Client-side route change
```

**Correct:**
```typescript
window.location.href = authUrl;  // Full page navigation required for OAuth
```

OAuth redirects are full HTTP redirects to an external domain (Scalekit/IdP). Client-side routing doesn't work.

---

## 6. Environment Variable Mistakes

| Wrong | Correct | Issue |
|-------|---------|-------|
| `SCALEKIT_URL` | `SCALEKIT_ENV_URL` | Missing `ENV_` |
| `SCALEKIT_SECRET` | `SCALEKIT_CLIENT_SECRET` | Missing `CLIENT_` |
| `SCALEKIT_ID` | `SCALEKIT_CLIENT_ID` | Missing `CLIENT_` |
| `SCALEKIT_CALLBACK_URL` | `SCALEKIT_REDIRECT_URI` | Wrong name entirely |
| `http://myapp.scalekit.com` | `https://myapp.scalekit.com` | Must be HTTPS |
| `https://myapp.scalekit.com/` | `https://myapp.scalekit.com` | No trailing slash |

---

## 7. Client Instantiation Mistakes

### Creating a new client per request

**Wrong:**
```typescript
app.get('/api/data', async (req, res) => {
  const scalekit = new ScalekitClient(envUrl, clientId, clientSecret); // per-request!
  // ...
});
```

**Correct:**
```typescript
// Module-level singleton
const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENV_URL!,
  process.env.SCALEKIT_CLIENT_ID!,
  process.env.SCALEKIT_CLIENT_SECRET!
);

app.get('/api/data', async (req, res) => {
  // Use the singleton
  const result = await scalekit.validateAccessToken(token);
});
```

The client manages its own token lifecycle and connection pooling. Creating it per request wastes resources and can hit rate limits.

---

## 8. Token Refresh Race Conditions

When multiple browser tabs trigger token refresh simultaneously, the second request often fails because the first one already consumed the refresh token.

**Mitigation pattern:**
```typescript
// Before refreshing, set a short-lived flag
const REFRESH_LOCK_KEY = 'refresh_in_progress';

async function refreshToken(session) {
  if (session[REFRESH_LOCK_KEY]) return; // Another tab is refreshing

  session[REFRESH_LOCK_KEY] = true;
  try {
    const result = await scalekit.refreshAccessToken(session.refreshToken);
    session.accessToken = result.accessToken;
    session.refreshToken = result.refreshToken;
  } finally {
    delete session[REFRESH_LOCK_KEY];
  }
}
```

---

## 9. Missing Scopes

### Refresh tokens require `offline_access` scope

**Wrong:**
```typescript
const authUrl = scalekit.getAuthorizationUrl(redirectUri, {
  scopes: ['openid', 'profile', 'email'],
});
// Later: scalekit.refreshAccessToken(refreshToken) → fails because no refresh token was issued
```

**Correct:**
```typescript
const authUrl = scalekit.getAuthorizationUrl(redirectUri, {
  scopes: ['openid', 'profile', 'email', 'offline_access'],
});
```

Without `offline_access`, the authorization server won't issue a refresh token.