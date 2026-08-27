---
name: integrate-agentkit
description: >
  Integrates AgentKit so an agent can create a connection, a connected
  account, and an authorized token, then call one downstream API.
  Use when the user wants AgentKit in app code, a Gmail/Slack/Notion
  connected account, or an authorization link.
  It does not list connectors (that's `discover-connectors`)
  or expose tools over MCP (that's `expose-agentkit-mcp`).
---

# Integrate AgentKit

Take this repo from a **connection** to a **connected account**, an authorized token, and one downstream API call. Then stop.

## Guardrails

- **MUST** pass the exact dashboard Connection Name (`connection_name` in Python, `connectionName` in Node). Never invent a slug. Never use a `connector` field for that value.
- **MUST** re-fetch the connected account immediately before using the token. Scalekit auto-refreshes.
- **MUST** print the authorization link and stop when the process is not interactive. Re-run from the token step after the user finishes OAuth.

## Gotchas

- Read SDK credentials from `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, and `SCALEKIT_CLIENT_SECRET`. Some samples use `SCALEKIT_ENV_URL`; use `SCALEKIT_ENVIRONMENT_URL` here.
- A **connection** is dashboard connector config. A **connected account** is one user authorized on that connection.
- The **connection** already exists from `setup-agentkit`. This skill starts there.
- Gmail can use Connection Name `gmail` when the dashboard has no Gmail row. Every other connector must already have a dashboard connection. Record that name exactly.
- Default language is Python. If the repo is Node, open [references/node.md](references/node.md). If the language is unknown, stay on Python.

## Step 1 — Confirm the Connection Name

Use the Connection Name already recorded by `setup-agentkit`.

If none is recorded:

- User named a connector: use the dashboard **Connection Name** exactly as shown.
- User did not name one: Gmail, Connection Name `gmail`.
- Non-Gmail with no dashboard row: name `setup-agentkit` and stop.

**Done when:** a Connection Name is written down. For Gmail with no dashboard row, that name is `gmail`.

## Step 2 — Init the SDK

If the repo is Node, follow [references/node.md](references/node.md) from here.

If env vars are missing, collect them from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Put them in the project env file. Do not invent values.

```bash
pip install scalekit-sdk-python python-dotenv requests
```

```python
from scalekit import ScalekitClient
import os
from dotenv import load_dotenv
load_dotenv()

sk_client = ScalekitClient(
    client_id=os.getenv("SCALEKIT_CLIENT_ID"),
    client_secret=os.getenv("SCALEKIT_CLIENT_SECRET"),
    env_url=os.getenv("SCALEKIT_ENVIRONMENT_URL"),
)
actions = sk_client.actions
```

**Done when:** the client initializes from those three env vars, and source files do not hardcode the secret.

## Step 3 — Create the connected account

Replace `"user_123"` with the project's user id. Replace `"gmail"` with the recorded Connection Name.

```python
response = actions.get_or_create_connected_account(
    connection_name="gmail",
    identifier="user_123"
)
connected_account = response.connected_account
```

**Done when:** a connected account exists for that identifier and Connection Name.

## Step 4 — Authorization link if not ACTIVE

If `connected_account.status` is `ACTIVE`, skip this step.

```python
import sys

if connected_account.status != "ACTIVE":
    link_response = actions.get_authorization_link(
        connection_name="gmail",
        identifier="user_123"
    )
    print("Authorize here:", link_response.link)
    if not sys.stdin.isatty():
        print("Complete OAuth in a browser, then re-run from Step 5 (fetch tokens).")
        raise SystemExit(0)
    input("Press Enter after authorizing...")
```

In a web app, redirect to `link`.

**Done when:** status is `ACTIVE`, or the authorization link is printed. A non-interactive run stops here until the user finishes OAuth.

## Step 5 — Fetch the token

Re-fetch immediately. Do not reuse a token from Step 3.

```python
response = actions.get_connected_account(
    connection_name="gmail",
    identifier="user_123"
)
tokens = response.connected_account.authorization_details["oauth_token"]
access_token = tokens["access_token"]
refresh_token = tokens["refresh_token"]
```

**Done when:** `access_token` is present.

## Step 6 — Call one downstream API

Use `access_token` as a Bearer token. Default: five unread Gmail messages.

```python
import requests

headers = {"Authorization": f"Bearer {access_token}"}
list_url = "https://gmail.googleapis.com/gmail/v1/users/me/messages"

messages = requests.get(
    list_url, headers=headers, params={"q": "is:unread", "maxResults": 5}
).json().get("messages", [])

for msg in messages:
    data = requests.get(
        f"{list_url}/{msg['id']}", headers=headers,
        params={"format": "metadata", "metadataHeaders": ["From", "Subject", "Date"]}
    ).json()
    hdrs = data.get("payload", {}).get("headers", [])
    print(next((h["value"] for h in hdrs if h["name"] == "Subject"), "No Subject"))
    print(next((h["value"] for h in hdrs if h["name"] == "From"), "Unknown"))
    print(data.get("snippet", ""))
    print("-" * 50)
```

For a non-Gmail connector, keep the same token path. Change only this HTTP call. Look up the provider API from https://docs.scalekit.com/agentkit/connectors.md.

**Done when:** one downstream API call succeeds with the fetched token.

## Reach for

- `setup-agentkit` if the connection or env is missing
- `discover-connectors` for the live tool catalog
- `expose-agentkit-mcp` to expose tools over MCP
- [references/node.md](references/node.md) for the Node SDK path
- [references/frameworks.md](references/frameworks.md) for LangChain and Google ADK

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Connector catalog: https://docs.scalekit.com/agentkit/connectors.md
- MCP: https://mcp.scalekit.com
