---
name: check-saaskit-prod
description: >
  Checks SaaSKit production so an agent can finish a
  go-live checklist.
  Use when the user wants SaaSKit production or to go live
  SaaSKit.
  It does not write login (that's `implement-saaskit`)
  or run dryrun (that's `run-dryrun`).
---

# Check SaaSKit go-live

Complete the SaaSKit go-live record with PASS or WAIVE plus a reason on every item. Then stop.

## Guardrails

- **MUST** record `PASS` or `WAIVE` plus a one-line reason on every item. Sign off only when the record is complete.
- **MUST** use production credentials. `SCALEKIT_ENVIRONMENT_URL` ends in `.scalekit.com`, not `.scalekit.dev`.
- **MUST** keep credentials in environment variables only.
- **MUST NOT** write login. Name `implement-saaskit` instead.
- **MUST NOT** run dryrun. Name `run-dryrun` instead.

## Gotchas

- Read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, and `SCALEKIT_CLIENT_SECRET`. Never `SCALEKIT_ENV_URL`.
- Live dashboard surfaces: Authentication → Redirect URLs, Authentication → Session Policy, Auth Logs.
- Dashboard and browser steps are **user actions**. Run curl yourself. Pause when the user must open the dashboard or a browser.
- A waiver needs a one-line reason. An empty result is a fail.
- If the app has no SSO, SCIM, MCP, or RBAC, waive those items with that reason. Do not add them.
- Prefer a non-customer test user. The host app may be local. Credentials must still be production SaaSKit env vars.
- Use the SDK path from `implement-saaskit` for smoke-test calls. Do not rewrite that skill here.

## Step 1 — Open the record

Create a go-live record. One row per item in Steps 2–6. Columns: item, result (`PASS` or `WAIVE`), reason (required on `WAIVE`).

Example row: `SCIM webhook signature | WAIVE | app has no directory webhook`.

**Done when:** the empty record exists and lists every item from Steps 2–6.

## Step 2 — Quick checks

Run:

```bash
echo $SCALEKIT_ENVIRONMENT_URL
echo $SCALEKIT_CLIENT_ID
echo $SCALEKIT_CLIENT_SECRET

curl -s -o /dev/null -w "%{http_code}" -X POST "$SCALEKIT_ENVIRONMENT_URL/oauth/token" \
  -d "client_id=$SCALEKIT_CLIENT_ID&client_secret=$SCALEKIT_CLIENT_SECRET&grant_type=client_credentials"

rg -n --hidden -g '!**/.git/**' -g '!**/node_modules/**' -g '!**/.env*' 'skc_|SCALEKIT_CLIENT_SECRET\s*=' . || true
```

`SCALEKIT_ENVIRONMENT_URL` must be `https://<subdomain>.scalekit.com`. Token endpoint must return `200`. The search must find no real secrets committed — only env var names or placeholders.

Record `PASS` or `WAIVE` plus a reason for:

1. `SCALEKIT_ENVIRONMENT_URL` ends in `.scalekit.com`
2. `SCALEKIT_CLIENT_ID` is set
3. `SCALEKIT_CLIENT_SECRET` is set
4. Token endpoint returns 200
5. HTTPS on every auth endpoint
6. No hardcoded secrets in source
7. Production callback and post-logout URLs on Authentication → Redirect URLs match the app (user verifies)

**Done when:** all 7 rows have `PASS` or `WAIVE` plus a reason.

## Step 3 — Core auth flows

Record `PASS` or `WAIVE` plus a reason for:

1. Login authorization URL starts the hosted flow
2. Callback URL in code matches Authentication → Redirect URLs exactly
3. Code exchange returns tokens
4. Callback validates `state` (CSRF)
5. Session cookies use `httpOnly`, `secure`, and `sameSite: 'lax'`
6. Authentication → Session Policy has absolute timeout, idle timeout, and access-token lifetime
7. Access tokens refresh before expiry
8. Logout clears cookies and calls `getLogoutUrl` with `idTokenHint`
9. Each enabled method (email/password, magic link, social, passkey) completes sign-up → login → logout

**Done when:** all 9 rows have `PASS` or `WAIVE` plus a reason.

## Step 4 — Enterprise, if the app ships it

Waive a group when that product is not in this app.

SSO:

1. Target IdP login works (Okta, Entra ID, or Google Workspace)
2. SP-initiated and IdP-initiated both work
3. Admin portal is available for self-serve SSO

SCIM:

1. Webhook calls `verifyWebhookPayload` and rejects a bad signature
2. Provision, update, and deactivate were tested
3. `user_deleted` deactivates; it does not hard-delete

MCP:

1. `/.well-known/oauth-protected-resource` is public
2. Scopes are enforced per tool
3. Client reconnects after token expiry

RBAC:

1. Roles and permissions exist at Roles & Permissions
2. A protected API route enforces them

Network:

1. Enterprise VPN customers whitelist `<env>.scalekit.com`, `cdn.scalekit.com`, and `fonts.googleapis.com`

**Done when:** every shipped group has all of its rows as `PASS` or `WAIVE` plus a reason, and unshipped groups are waived.

## Step 5 — Monitoring

Ask the user to open Dashboard → Auth Logs. You cannot open the dashboard.

Record `PASS` or `WAIVE` plus a reason for:

1. Auth Logs monitoring is on
2. Error tracking covers login failures and token refresh errors
3. Alerts fire on repeated authorization failures
4. Log retention is set
5. Incident runbook exists (who to contact; how to roll back the auth flag)

After go-live, track login success/failure rate, token refresh frequency, webhook delivery rate, and SSO completion rate.

**Done when:** all 5 rows have `PASS` or `WAIVE` plus a reason.

## Step 6 — Final smoke

Use `implement-saaskit` for login, callback, cookies, and logout. Pause for the user on the browser.

Record `PASS` or `WAIVE` plus a reason for:

1. Sign up / log in → session cookies are `httpOnly`, `secure`, `sameSite`
2. A protected route accepts the access token
3. Force expiry (or wait) → refresh keeps the session
4. Log out → cookies are gone and a new visit prompts login
5. SSO, if shipped: callback completes and the session exists
6. SCIM, if shipped: a directory event upserts or deactivates a user
7. MCP, if shipped: a client connects and one tool call succeeds

**Done when:** all 7 rows have `PASS` or `WAIVE` plus a reason.

## Step 7 — Sign off

Print the full record. If any item has no result, go back to that step. Do not sign off.

**Done when:** every item from Steps 2–6 is `PASS` or `WAIVE` plus a reason, and the user has the signed record.

## Reach for

- `implement-saaskit` to write login, callback, cookies, and logout
- `run-dryrun` to test the env before this checklist
- `implement-sso` if SSO is missing
- `implement-scim` if the directory webhook is missing
- `check-agentkit-prod` for AgentKit go-live

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Launch checklist: https://docs.scalekit.com/authenticate/launch-checklist/
- Sessions: https://docs.scalekit.com/authenticate/fsa/sessions/
- MCP: https://mcp.scalekit.com
