---
name: migrate-to-saaskit
description: >
  Migrates existing auth to SaaSKit so an agent can audit
  and import it.
  Use when the user wants to migrate to SaaSKit or replace
  Auth0 or Clerk.
  It does not write a first-time login (that's `implement-saaskit`).
---

# Migrate to SaaSKit

Audit existing auth and import it to SaaSKit. Then stop.

## Guardrails

- **MUST** audit and export before any import.
- **MUST** store original org and user primary keys in `external_id`.
- **MUST** set `sendInvitationEmail: false` on every imported user.
- **MUST NOT** copy password hashes unless the Scalekit Solutions team does it.
- **MUST** keep a rollback feature flag through the first rollout window.
- **MUST NOT** write first-time login, callback, or logout. Name `implement-saaskit` instead.

## Gotchas

- Default language is Node. Same client as `implement-saaskit`.
- Read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, and `SCALEKIT_CLIENT_SECRET`. Never `SCALEKIT_ENV_URL`. Do not prepend `https://`.
- Audit steps live in [references/AUDIT-CHECKLIST.md](references/AUDIT-CHECKLIST.md). Import samples live in [references/IMPORT-SAMPLES.md](references/IMPORT-SAMPLES.md). Open those files. Do not paste them here.
- Users re-authenticate on hosted login (SSO, social, or passwordless). Do not import hashes.
- Rebuild SSO with `implement-sso`. IdP secrets are not exportable.
- Cut over behind a feature flag. Do not flip all traffic first.
- Dashboard: Authentication → Redirect URLs. Roles live at Roles & Permissions.

## Step 1 — Confirm this is a migration

If the app has no existing auth, name `implement-saaskit` and stop.

Collect the three env names from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Do not invent values.

**Done when:** this skill is the right path, and the three env names exist.

## Step 2 — Audit and export

Open [references/AUDIT-CHECKLIST.md](references/AUDIT-CHECKLIST.md). Complete that checklist. Then stop reading it.

Export users, organizations, roles, and SSO/IdP configs. Keep original primary keys.

Before import:

1. Save one sample JWT or session cookie from the old system
2. Add a feature flag that still routes to the old auth
3. Write the rollback steps

Minimum user fields: `email` (required), `first_name`, `last_name`, `email_verified` (defaults `false`).

**Done when:** the export exists, the flag can roll back, and the audit file is checked off.

## Step 3 — Import organizations

Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet. Open [references/IMPORT-SAMPLES.md](references/IMPORT-SAMPLES.md) for Python, Go, Java, or cURL.

```js
import { ScalekitClient } from '@scalekit-sdk/node';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);

const { organization } = await scalekit.organization.createOrganization(
  org.display_name,
  { externalId: org.external_id }
);
```

`externalId` is the source org primary key. Live Node options are `externalId`, `logoUrl`, and `slug` only.

**Done when:** each source org exists in Scalekit and `organization.externalId` matches the export.

## Step 4 — Import users

Create users after their org exists. Use the Scalekit org id from Step 3.

```js
const { user } = await scalekit.user.createUserAndMembership(organization.id, {
  email: source.email,
  externalId: source.external_id,
  sendInvitationEmail: false,
  userProfile: { firstName: source.first_name, lastName: source.last_name },
});
```

Batch in parallel. Respect rate limits. Do not send invite email.

**Done when:** each source user has a membership, `sendInvitationEmail` was false, and `user.externalId` matches the export.

## Step 5 — Rebuild SSO and redirects

Print this checklist. Wait for the user.

1. Authentication → Redirect URLs → Allowed callback URLs: the app callback
2. Authentication → Redirect URLs → Post logout URLs: the post-logout origin
3. Roles & Permissions: recreate source roles

Name `implement-sso` to rebuild each IdP connection. Do not copy IdP secrets from Auth0 or Clerk.

**Done when:** both redirect URLs are registered, roles exist, and `implement-sso` is named or SSO is waived.

## Step 6 — Point the app at SaaSKit

Name `implement-saaskit` for login, callback, cookies, and logout.

Name `manage-saaskit-sessions` for validate, refresh, and revoke.

Do not write those routes here.

**Done when:** those skills are named, and this skill has not written login.

## Step 7 — Cut over behind the flag

1. Test login with a small set of migrated users
2. Turn the flag on for 5–10% of traffic
3. Watch Dashboard → Auth Logs
4. Keep rollback on for 48 hours

**Done when:** a subset of users signs in through SaaSKit, and the flag still rolls back.

## Step 8 — Stop

Name `run-dryrun` to test the env. Name `check-saaskit-prod` before go-live.

**Done when:** orgs and users are imported with `external_id`, the flag is in place, and this skill has stopped.

## Reach for

- [references/AUDIT-CHECKLIST.md](references/AUDIT-CHECKLIST.md) for the audit
- [references/IMPORT-SAMPLES.md](references/IMPORT-SAMPLES.md) for other languages
- `implement-saaskit` for login, callback, cookies, and logout
- `implement-sso` to rebuild SSO
- `run-dryrun` to test the env
- `check-saaskit-prod` for the go-live record

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Migration: https://docs.scalekit.com/fsa/guides/migration-guide/
- Auth0: https://docs.scalekit.com/cookbooks/migrate-from-auth0-to-scalekit/
- MCP: https://mcp.scalekit.com
