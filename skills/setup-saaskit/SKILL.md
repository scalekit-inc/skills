---
name: setup-saaskit
description: >
  Configures SaaSKit so a project has env credentials, a redirect
  URI, and a first login URL.
  Use when the user wants to setup SaaSKit or add login to this app.
  It does not install the CLI (that's `setup-scalekit`)
  or write login/callback/session code (that's `implement-saaskit`).
---

# Setup SaaSKit

Give this project env credentials, a registered redirect URI, and a first login URL. Then stop.

## Guardrails

- **MUST** wait for dashboard credential values. **MUST NOT** invent them.
- **MUST** keep `SCALEKIT_REDIRECT_URI` identical to the dashboard Allowed callback URL.
- **MUST NOT** write login, callback, or session code. Name `implement-saaskit` instead.

## Gotchas

- Read credentials from `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, and `SCALEKIT_REDIRECT_URI`.
- `SCALEKIT_REDIRECT_URI` must match an Allowed callback URL in the dashboard, character for character.
- Default callback is `http://localhost:3000/auth/callback` when the project has no callback path yet.
- This skill stops at the first login URL. Login, callback, and session code belong to `implement-saaskit`.
- Wait for the user to supply credentials. Do not invent values.

## Step 1 — Get API credentials

Open [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials.

Collect:

```bash
SCALEKIT_ENVIRONMENT_URL=https://your-env.scalekit.com
SCALEKIT_CLIENT_ID=<from dashboard>
SCALEKIT_CLIENT_SECRET=<from dashboard>
```

Self-hosted: use the environment URL and credentials from that admin dashboard.

**Done when:** the user has those three values from the dashboard.

## Step 2 — Register the redirect URI

Pick the callback URL. Use the project's existing callback path when it has one. Otherwise use `http://localhost:3000/auth/callback`.

In the dashboard: **Authentication → Redirect URLs → Allowed callback URLs**. Add that exact URL.

Set `SCALEKIT_REDIRECT_URI` to the same string.

**Done when:** the dashboard lists the URL, and `SCALEKIT_REDIRECT_URI` matches it exactly.

## Step 3 — Write project env

```sh
SCALEKIT_ENVIRONMENT_URL=<your-environment-url>
SCALEKIT_CLIENT_ID=<your-client-id>
SCALEKIT_CLIENT_SECRET=<your-client-secret>
SCALEKIT_REDIRECT_URI=<your-callback-url>
```

Put these in the project's env file. Keep secrets out of source.

**Done when:** the env file contains all four names.

## Step 4 — Produce the first login URL

Use the Scalekit SDK already in the project. Install `@scalekit-sdk/node` only when the repo has no Scalekit SDK yet.

```js
import { ScalekitClient } from '@scalekit-sdk/node';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL,
  process.env.SCALEKIT_CLIENT_ID,
  process.env.SCALEKIT_CLIENT_SECRET
);

const loginUrl = scalekit.getAuthorizationUrl(process.env.SCALEKIT_REDIRECT_URI, {
  scopes: ['openid', 'profile', 'email', 'offline_access']
});
console.log(loginUrl);
```

If the repo is Python, call `get_authorization_url` on `scalekit-sdk-python` with the same env names. Do not implement the callback or session here.

The URL looks like `<SCALEKIT_ENVIRONMENT_URL>/oauth/authorize?...`.

**Done when:** that authorization URL is printed, or the user has a one-liner that prints it.

## Step 5 — Name the next skill and stop

- Next.js App Router → name `implement-saaskit-nextjs`. Stop.
- Django, FastAPI, or Flask → name `implement-saaskit-python`. Stop.
- Anything else → name `implement-saaskit`. Stop.

**Done when:** one of those skills is named, and this skill has stopped.

## Reach for

- `setup-scalekit` if the plugin is missing
- `run-dryrun` to check credentials after this wizard
- `deploy-self-hosted` for an on-prem environment
- `setup-agentkit` if the user wanted connections and tools

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- MCP: https://mcp.scalekit.com
