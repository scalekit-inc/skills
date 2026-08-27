---
name: implement-sso
description: >
  Implements Modular SSO so an agent can add SAML/OIDC,
  IdP-initiated login, and the admin portal.
  Use when the user wants SSO, SAML, OIDC, Modular SSO, or IdP.
  It does not write SaaSKit login (that's `implement-saaskit`)
  or provision users from a directory (that's `implement-scim`).
---

# Implement SSO

Add SAML/OIDC, IdP-initiated login, and the admin portal. Then stop.

## Guardrails

- **MUST** pass one selector on every authorization URL: `connectionId`, `organizationId`, or `loginHint`.
- **MUST** keep `redirectUri` identical to the dashboard Allowed callback URL.
- **MUST** call `validateToken` before using claims.
- **MUST** keep `relay_state` as `state` on IdP-initiated login.
- **MUST** print dashboard checklists, wait for the user, then continue. Do not click the dashboard.

## Gotchas

- Modular SSO is for apps that already manage users and sessions. Scalekit handles SAML/OIDC. The app keeps the user store and session.
- Full-Stack Auth / SaaSKit login already includes SSO. Name `implement-saaskit` and stop. Modular SSO or FSA, not both.
- Auth mode: Dashboard → Settings → Authentication Mode → Modular Auth. Path is `/settings/authentication-mode`.
- Read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`. Never `SCALEKIT_ENV_URL`. Do not prepend `https://` if the URL already has a scheme.
- Default language is Node. Default scopes are `openid profile email`. Modular SSO does not support `offline_access`. Do not write refresh tokens or SaaSKit cookies.
- Selector order: `connectionId` > `organizationId` > `loginHint`. `domainHint` also works. Without a selector Scalekit cannot pick an IdP.
- Copy organization IDs from the dashboard. Do not invent `org_…` values.
- Test proof is Organizations → Test Organization. Do not ask for FSA dryrun or a hosted-login URL.
- IdP click-paths live in [references/providers.md](references/providers.md). Point IT at the live guide.

## Step 1 — Confirm Modular Auth

If the app already uses SaaSKit or Full-Stack Auth login, name `implement-saaskit` and stop.

Print this checklist. Wait for the user. Then continue.

1. [app.scalekit.com](https://app.scalekit.com) → Settings → Authentication Mode → Modular Auth
2. Developers → Settings → API Credentials. Copy the three env names.
3. Authentication → Redirects:
   - Allowed callback URLs: the app `/auth/callback` (local default `http://localhost:3000/auth/callback`)
   - Initiate login URL: the app `/login` (local default `http://localhost:3000/login`)

Put the three env names in the project env file. Do not invent values.

**Done when:** mode is Modular Auth, the three env names exist, and both redirect URLs are registered.

## Step 2 — Init the SDK

Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet.

```js
import { ScalekitClient } from '@scalekit-sdk/node';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);
const redirectUri = 'http://localhost:3000/auth/callback';
```

Use the same `redirectUri` string that is registered in Step 1.

**Done when:** the client initializes from those env vars.

## Step 3 — Login route

Pass one selector. Empty query fails.

```js
app.get('/auth/login', (req, res) => {
  const { connectionId, organizationId, loginHint, domainHint } = req.query;
  const authorizationUrl = scalekit.getAuthorizationUrl(redirectUri, {
    connectionId,
    organizationId,
    loginHint,
    domainHint,
    scopes: ['openid', 'profile', 'email'],
  });
  res.redirect(authorizationUrl);
});
```

**Done when:** `/auth/login` redirects to that URL with one selector.

## Step 4 — IdP-initiated `/login`

Register this exact URL as Initiate login URL.

```js
app.get('/login', async (req, res) => {
  const { idp_initiated_login, error, error_description } = req.query;
  if (error) return res.status(400).send(error_description);
  const claims = await scalekit.getIdpInitiatedLoginClaims(idp_initiated_login);
  const authorizationUrl = scalekit.getAuthorizationUrl(redirectUri, {
    connectionId: claims.connection_id,
    organizationId: claims.organization_id,
    loginHint: claims.login_hint,
    state: claims.relay_state,
    scopes: ['openid', 'profile', 'email'],
  });
  res.redirect(authorizationUrl);
});
```

**Done when:** `/login` reads `idp_initiated_login` and redirects with `relay_state` as `state`.

## Step 5 — Callback and app session

Use the same `redirectUri` as Step 3. The app creates its own session after validation.

```js
app.get('/auth/callback', async (req, res) => {
  const { code, error, error_description } = req.query;
  if (error) return res.status(400).send(error_description);
  const result = await scalekit.authenticateWithCode(code, redirectUri);
  await scalekit.validateToken(result.idToken);
  await scalekit.validateToken(result.accessToken);
  // Create the app's own session from result.user.
  res.redirect('/dashboard');
});
```

Do not write SaaSKit HttpOnly cookies. Modular SSO does not return a refresh token.

**Done when:** the callback exchanges `code`, validates both tokens, and the app session exists.

## Step 6 — Test with the simulator

Print this checklist. Wait for the user. Then continue.

1. Dashboard → Organizations → Test Organization
2. Copy the test `organization_id` or `connection_id`. Domains are `example.com` and `example.org`.
3. Open `/auth/login` with one of: `organizationId=<id>`, `connectionId=<id>`, or `loginHint=user@example.com`
4. Complete the simulator (SP-initiated, then IdP-initiated)

**Done when:** the callback created the app session for a simulator login.

## Step 7 — Admin portal

Shareable link (no code): Dashboard → Organizations → the org → Generate link. Send that URL plus the matching [SSO setup guide](https://docs.scalekit.com/guides/integrations/sso-integrations/) to the customer's IT admin. Open [references/providers.md](references/providers.md) for Okta, Entra ID, Google Workspace, and JumpCloud.

Embed: register the page origin under Authentication → Redirects → Allowed callback URLs. Generate the link server-side on every load. Links are single-use. `orgId` is the customer's organization ID from the dashboard.

```js
const portalLink = await scalekit.organization.generatePortalLink(orgId);
res.json({ portalUrl: portalLink.location });
```

```html
<iframe src="${portalUrl}" width="100%" height="600" frameborder="0" allow="clipboard-write"></iframe>
```

On `message`, if `event.data.event_type` is `PORTAL_SESSION_EXPIRY`, generate a new link and set `iframe.src`. Do the same for `PORTAL_LOAD_FAILURE` when `data.error_code` is `SESSION_EXPIRED`.

**Done when:** a shareable link can be generated, and the iframe uses a fresh `portalLink.location`.

## Step 8 — Stop

Name `implement-scim` only if the user wants directory provisioning.

**Done when:** SAML/OIDC, IdP-initiated `/login`, and the admin portal are in the repo, and this skill has stopped.

## Reach for

- `implement-saaskit` if the app wants SaaSKit login instead
- `implement-scim` to provision users from a directory
- [references/providers.md](references/providers.md) for Okta, Entra ID, Google Workspace, and JumpCloud

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Modular SSO: https://docs.scalekit.com/authenticate/sso/add-modular-sso.md
- Admin portal: https://docs.scalekit.com/authenticate/sso/admin-portal/
- MCP: https://mcp.scalekit.com
