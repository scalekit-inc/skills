---
name: expose-agentkit-mcp
description: >
  Exposes AgentKit tools over MCP so a client can call them
  on a per-user instance URL.
  Use when the user wants to expose AgentKit over MCP, generate
  a per-user MCP URL, or connect LangChain via MCP.
  It does not list connectors (that's `discover-connectors`)
  or create a connected account and token in app code (that's `integrate-agentkit`).
---

# Expose AgentKit over MCP

Create an AgentKit MCP config, a per-user instance URL, and one Streamable HTTP client call. Then stop.

## Guardrails

- **MUST** use Streamable HTTP. stdio and SSE are not supported.
- **MUST** pass the exact dashboard Connection Name (`connection_name`). Never invent a slug. Never use a `connector` field for that value.
- **MUST** give each user their own instance URL. Do not share one URL across users.

## Gotchas

- Read SDK credentials from `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, and `SCALEKIT_CLIENT_SECRET`. Some samples use `SCALEKIT_ENV_URL`; use `SCALEKIT_ENVIRONMENT_URL` here. Do not prepend `https://` if the value already has a scheme.
- A **connection** is dashboard connector config. A **connected account** is one user authorized on that connection. This skill authorizes through the MCP instance auth link, not `integrate-agentkit` app-code token calls.
- Gmail can use Connection Name `gmail` when the dashboard has no Gmail row. Every other connector must already have a dashboard connection. Record that name exactly.
- Default language is Python. The Node SDK has no MCP config API. Stay on Python.
- Look up tool names with `discover-connectors`. Do not copy connector pages into the repo.

## Step 1 — Confirm Connection Names

Default path: Gmail plus Google Calendar, so one email fetch and one reminder event.

- Gmail: Connection Name `gmail` if the dashboard has no Gmail row.
- Google Calendar: have the user create it at **Scalekit Dashboard → AgentKit → Connections → Add connection → Google Calendar** → **Connection Name = `MY_CALENDAR`** → Save.

Wait for the user to confirm the Calendar row. Do not invent that name.

**Done when:** Gmail is `gmail` (or the dashboard Gmail name), and Calendar is the exact dashboard Connection Name.

## Step 2 — Init the SDK

If env vars are missing, collect them from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Put them in the project env file. Do not invent values.

```bash
pip install scalekit-sdk-python langgraph>=0.6.5 langchain langchain-openai langchain-mcp-adapters>=0.1.9 python-dotenv>=1.0.1
```

```python
import os
import asyncio
from dotenv import load_dotenv
from scalekit import ScalekitClient
from scalekit.actions.models.mcp_config import McpConfigConnectionToolMapping
from langgraph.prebuilt import create_react_agent
from langchain_mcp_adapters.client import MultiServerMCPClient

load_dotenv()

sk_client = ScalekitClient(
    client_id=os.getenv("SCALEKIT_CLIENT_ID"),
    client_secret=os.getenv("SCALEKIT_CLIENT_SECRET"),
    env_url=os.getenv("SCALEKIT_ENVIRONMENT_URL"),
)
my_mcp = sk_client.actions.mcp
```

Set `OPENAI_API_KEY` in the environment for the LangChain client in Step 5.

**Done when:** the client initializes from those three env vars, and source files do not hardcode the secret.

## Step 3 — Create the MCP config and instance

Replace `"user_123"` with the project's user id. Replace `"MY_CALENDAR"` with the recorded Calendar Connection Name.

```python
cfg_response = my_mcp.create_config(
    name="reminder-manager",
    description="Summarizes latest email and creates a reminder event",
    connection_tool_mappings=[
        McpConfigConnectionToolMapping(
            connection_name="gmail",
            tools=["gmail_fetch_mails"],
        ),
        McpConfigConnectionToolMapping(
            connection_name="MY_CALENDAR",
            tools=["googlecalendar_create_event"],
        ),
    ],
)
config_name = cfg_response.config.name

inst_response = my_mcp.ensure_instance(
    config_name=config_name,
    user_identifier="user_123",
)
mcp_url = inst_response.instance.url
print("Instance URL:", mcp_url)
```

**Done when:** `mcp_url` is a per-user instance URL.

## Step 4 — Print auth links if needed

```python
auth_state_response = my_mcp.get_instance_auth_state(
    instance_id=inst_response.instance.id,
    include_auth_links=True,
)
for conn in auth_state_response.connections:
    print(
        "Connection:", conn.connection_name,
        " Provider:", conn.provider,
        " Auth Link:", conn.authentication_link,
        " Status:", conn.connected_account_status,
    )
```

Tell the user to open every printed auth link and finish OAuth. A non-interactive run stops here until they do.

**Done when:** each mapped connection is authorized, or every needed auth link is printed.

## Step 5 — Call the instance over Streamable HTTP

```python
async def main():
    client = MultiServerMCPClient(
        {
            "reminder_demo": {
                "transport": "streamable_http",
                "url": mcp_url,
            },
        }
    )
    tools = await client.get_tools()
    agent = create_react_agent("openai:gpt-4o", tools)
    response = await agent.ainvoke(
        {"messages": "get 1 latest email and create a calendar reminder event in next 15 mins for a duration of 15 mins."}
    )
    print(response)

asyncio.run(main())
```

**Done when:** the Streamable HTTP client loads the tools and one invoke succeeds.

## Reach for

- `discover-connectors` for live tool names and schemas
- `integrate-agentkit` to create a connected account and token in app code
- `setup-agentkit` if the connection or env is missing

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Connector catalog: https://docs.scalekit.com/agentkit/connectors.md
- MCP: https://mcp.scalekit.com
