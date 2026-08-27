---
name: implement-scim
description: >
  Implements SCIM so an agent can provision users and
  groups from a directory.
  Use when the user wants SCIM or to provision users.
  It does not write SaaSKit login (that's `implement-saaskit`)
  or add SSO (that's `implement-sso`).
---

# Implement SCIM

Provision users and groups from a directory. Then stop.

## Guardrails

- **MUST** call `verifyWebhookPayload` before reading the event. Invalid signature → 400. Do not process it.
- **MUST** upsert. The same `user_created` can arrive twice.
- **MUST** deactivate on `organization.directory.user_deleted`. **MUST NOT** hard-delete unless the repo already does.
- **MUST NOT** generate the admin portal. Name `implement-sso` instead.

## Gotchas

- Default language is Node. Same client as `implement-saaskit`.
- Read `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, and `SCALEKIT_WEBHOOK_SECRET`. Never `SCALEKIT_ENV_URL`. Do not prepend `https://`.
- The signing secret exists after the user registers the endpoint. Write the route first with that env name.
- Mount `express.raw({ type: 'application/json' })` on `/webhooks/scalekit` before `express.json()`. The signature is the exact request bytes.
- `verifyWebhookPayload(secret, headers, payload)` takes a string. It throws. Catch → 400.
- Headers are `webhook-id`, `webhook-timestamp`, and `webhook-signature`.
- Webhook user fields: `email`, `name`, `organization_id`. Group fields: `id`, `display_name`, `organization_id`.
- Directory API users have `email`, `givenName`, `familyName` — no `name`. Groups have `id`, `displayName`.
- `getPrimaryDirectoryByOrganizationId(orgId)` returns the directory object, not `{ directory }`.
- Copy `org_…` from the dashboard or the event. Do not invent IDs.
- The endpoint URL must be public HTTPS. Print dashboard checklists. Wait. Do not click the dashboard.

## Step 1 — Confirm env

If the user wants the admin portal so IT can turn on the directory, name `implement-sso`. Stay here for the webhook.

Print this checklist. Wait for the user. Then continue.

1. [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Copy the three env names.
2. The customer org already has a directory, or IT will add one after the webhook exists.

Put the three env names in the project env file. Leave `SCALEKIT_WEBHOOK_SECRET` for Step 5.

**Done when:** the three env names exist.

## Step 2 — Init the SDK

Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet.

```js
import { ScalekitClient } from '@scalekit-sdk/node';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);
```

**Done when:** the client initializes from those env vars.

## Step 3 — Webhook route

```js
app.post('/webhooks/scalekit', express.raw({ type: 'application/json' }), async (req, res) => {
  const payload = req.body.toString('utf8');
  try {
    scalekit.verifyWebhookPayload(
      process.env.SCALEKIT_WEBHOOK_SECRET,
      req.headers,
      payload
    );
  } catch {
    return res.status(400).json({ error: 'Invalid signature' });
  }
  const event = JSON.parse(payload);
  await handleDirectoryEvent(event.type, event.data);
  return res.status(201).json({ received: true });
});
```

Respond 201 within 10 seconds. If the map is slow, enqueue and still return 201.

**Done when:** POST `/webhooks/scalekit` verifies the signature and returns 201.

## Step 4 — Map users and groups

Call the repo's existing create, update, and deactivate helpers. Search for those names. Do not invent a second user store.

```js
async function handleDirectoryEvent(type, data) {
  switch (type) {
    case 'organization.directory.user_created':
    case 'organization.directory.user_updated':
      return upsertUser({ email: data.email, name: data.name, orgId: data.organization_id });
    case 'organization.directory.user_deleted':
      return deactivateUser(data.email);
    case 'organization.directory.group_created':
    case 'organization.directory.group_updated':
      return upsertGroup({ id: data.id, name: data.display_name, orgId: data.organization_id });
    case 'organization.directory.group_deleted':
      return removeGroup(data.id);
    default:
      return;
  }
}
```

**Done when:** those six events map to local users and groups.

## Step 5 — Register the webhook

Print this checklist. Wait for the user. Then continue.

1. Dashboard → Webhooks → +Add Endpoint
2. URL: the public `https://…/webhooks/scalekit`
3. Subscribe:
   - `organization.directory.user_created`
   - `organization.directory.user_updated`
   - `organization.directory.user_deleted`
   - `organization.directory.group_created`
   - `organization.directory.group_updated`
   - `organization.directory.group_deleted`
4. Copy the signing secret into `SCALEKIT_WEBHOOK_SECRET`
5. Send Test Event
6. Share the [SCIM setup guide](https://docs.scalekit.com/guides/integrations/scim-integrations/) with the customer's IT admin

**Done when:** the secret is in env and a test event created or updated a local user.

## Step 6 — On-demand directory map

Use this for a first sync or a backfill. `orgId` is the customer's `org_…` from the dashboard or the last event.

```js
const directory = await scalekit.directory.getPrimaryDirectoryByOrganizationId(orgId);
const { users } = await scalekit.directory.listDirectoryUsers(orgId, directory.id);
for (const user of users) {
  await upsertUser({
    email: user.email,
    name: [user.givenName, user.familyName].filter(Boolean).join(' '),
    orgId,
  });
}
const { groups } = await scalekit.directory.listDirectoryGroups(orgId, directory.id);
for (const group of groups) {
  await upsertGroup({ id: group.id, name: group.displayName, orgId });
}
```

**Done when:** a list of directory users and groups upserts into the same store as Step 4.

## Step 7 — Stop

Do not embed the admin portal here.

**Done when:** the webhook maps users and groups, a test event landed, and this skill has stopped.

## Reach for

- `implement-sso` for the admin portal so IT can turn on the directory
- `implement-saaskit` if the app also needs SaaSKit login
- `implement-access-control` for roles and permissions at a route

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Modular SCIM: https://docs.scalekit.com/directory/scim/quickstart/
- Directory events: https://docs.scalekit.com/directory/reference/directory-events/
- MCP: https://mcp.scalekit.com
