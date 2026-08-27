---
name: setup-agentkit
description: >
  Configures AgentKit so a project has a dashboard connection, env
  credentials, and a first connector path.
  Use when the user wants to setup AgentKit in this project, add
  AgentKit, or connect Gmail/Slack.
  It does not install the CLI (that's `setup-scalekit`)
  or write app-code tool calls (that's `integrate-agentkit`).
---

# Setup AgentKit

Give this project a dashboard connection, env credentials, and a first connector path. Then stop.

## Guardrails

- **MUST** wait for dashboard credential values. **MUST NOT** invent them.
- **MUST** record the Connection Name (`gmail` when the dashboard has no Gmail row).
- **MUST NOT** write app-code tool calls. Name `integrate-agentkit` instead.

## Gotchas

- Read SDK credentials from `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, and `SCALEKIT_CLIENT_SECRET`. Some samples use `SCALEKIT_ENV_URL` for the same URL; use `SCALEKIT_ENVIRONMENT_URL` here.
- This skill stops after the **connection**. A **connected account** belongs to `integrate-agentkit`.
- Gmail can proceed without extra dashboard config. Enable every other connector in the dashboard before the next skill.
- Record the dashboard **Connection Name**. Later SDK calls use that exact string, not the connector slug.
- The Scalekit MCP server at https://mcp.scalekit.com needs no extra env vars. It does not replace the SDK credentials.
- Look up connectors at https://docs.scalekit.com/agentkit/connectors.md.
- Wait for the user to supply credentials. Do not invent values.

## Step 1 — Get API credentials

Open [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials.

Collect:

```bash
SCALEKIT_ENVIRONMENT_URL=https://your-env.scalekit.com
SCALEKIT_CLIENT_ID=<from dashboard>
SCALEKIT_CLIENT_SECRET=<from dashboard>
```

**Done when:** the user has those three values from the dashboard.

## Step 2 — Write project env

Put the three variables in the project's env file (`.env` or the existing env file). Keep secrets out of source.

**Done when:** the env file contains all three names, and source files do not hardcode the secret.

## Step 3 — Create the first connection

Ask which connector to start with only when the user has not named one. Default is Gmail.

If the connector is Gmail and the dashboard has no Gmail row, record Connection Name `gmail`.

If the connector is not Gmail, have the user create it:

**Scalekit Dashboard → AgentKit → Connections → Add connection** → select the connector → set **Connection Name** → Save.

For OAuth connectors that need a provider app, open the live guide: https://docs.scalekit.com/agentkit/connections/

If the dashboard already has a row for this connector, record that **Connection Name** exactly as shown.

**Done when:** a Connection Name is written down. For Gmail with no dashboard row, that name is `gmail`. For every other connector, a dashboard connection exists.

## Step 4 — Record the first connector path

Keep these three items for the next skill:

- Connector (for example Gmail or Slack)
- Connection Name
- Catalog: https://docs.scalekit.com/agentkit/connectors.md

**Done when:** those three items are known in this session.

## Step 5 — Name the next skill and stop

Name `integrate-agentkit`. That skill creates a connected account, an authorization link, and one downstream call.

Do not write those app-code calls here.

**Done when:** `integrate-agentkit` is named, and this skill has stopped.

## Reach for

- `setup-scalekit` if the plugin is missing
- `discover-connectors` for the live tool catalog
- `setup-saaskit` if the user wanted app login

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Connector catalog: https://docs.scalekit.com/agentkit/connectors.md
- MCP: https://mcp.scalekit.com
