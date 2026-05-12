---
name: testing-agentkit-tools
description: Tests live Scalekit AgentKit flows by generating authorization links, fetching tool metadata, and executing a tool for a connected account. Use when a user wants to validate a connector, inspect the exact payload for `execute_tool`, or build a workflow step by step.
---

# Testing AgentKit Tools

Live playground for testing AgentKit operations: generate authorization links, discover tools, and execute tool calls against real connectors.

## Prerequisites

- `SCALEKIT_ENV_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET` set in environment

## Operations

### 1. Generate an authorization link

Create or fetch a connected account and print an authorization link if the account is not yet `ACTIVE`.

**Python:**
```python
import scalekit.client, os
from dotenv import load_dotenv
load_dotenv()

client = scalekit.client.ScalekitClient(
    client_id=os.getenv("SCALEKIT_CLIENT_ID"),
    client_secret=os.getenv("SCALEKIT_CLIENT_SECRET"),
    env_url=os.getenv("SCALEKIT_ENV_URL"),
)

response = client.actions.get_or_create_connected_account(
    connection_name="gmail",
    identifier="user_123"
)

if response.connected_account.status != "ACTIVE":
    link = client.actions.get_authorization_link(
        connection_name="gmail",
        identifier="user_123"
    )
    print("Authorize here:", link.link)
else:
    print("Already connected:", response.connected_account.id)
```

### 2. Discover tools for a connector

Fetch live tool metadata to inspect schemas before execution.

**Python:**
```python
tools = client.actions.get_tools(providers=["GMAIL"], page_size=100)
for tool in tools.tools:
    print(f"Tool: {tool.name}")
    print(f"  Required: {tool.input_schema.get('required', [])}")
    print(f"  Properties: {list(tool.input_schema.get('properties', {}).keys())}")
```

### 3. Execute a tool

Run a tool with real inputs and inspect the result.

**Python:**
```python
result = client.actions.execute_tool(
    tool_name="gmail_fetch_mails",
    identifier="user_123",
    connected_account_id=response.connected_account.id,
    tool_input={
        "query": "is:unread",
        "max_results": 5,
    },
)
print("Result:", result)
```

## Testing workflow

1. Confirm environment variables are available.
2. Generate an authorization link if the connected account is not `ACTIVE`.
3. Open the auth link in a browser and complete OAuth.
4. Discover the tool and inspect its schema.
5. Execute the tool with the smallest valid `tool_input`.
6. Show the exact command and payload used so the user can translate it into app code.

## Guardrails

- Treat live metadata as the source of truth for `input_schema` and `output_schema`.
- Do not assume the dashboard `connection_name` matches the connector slug.
- Ask for missing credentials instead of inventing placeholder values.
- Keep the tool set constrained to the current workflow.

## Deep reference

- AgentKit overview: [docs.scalekit.com/agentkit/overview](https://docs.scalekit.com/agentkit/overview/)
- Tool discovery: [docs.scalekit.com/agentkit/tool-discovery](https://docs.scalekit.com/agentkit/tool-discovery/)
- Code samples: [docs.scalekit.com/agentkit/code-samples](https://docs.scalekit.com/agentkit/code-samples/)

## When to switch skills

- Use `integrating-agentkit` for the full production integration guide.
- Use `discovering-connector-tools` for detailed schema inspection.
- Use `exposing-agentkit-via-mcp` to expose tools over MCP.