---
name: discovering-connector-tools
description: Discovers live tools for a Scalekit AgentKit connector and explains their input and output schemas. Use when a user asks what tools are available for Gmail, Slack, Salesforce, or another connector, wants to inspect `input_schema` or `output_schema`, or needs help narrowing the tool set for an agent.
---

# Discovering Connector Tools

Use live AgentKit metadata as the source of truth for tool names, required inputs, and output schemas.

Do not rely on static connector notes as a complete catalog. Those may lag the live platform.

## When to use this skill

Use this skill when the user asks:

- what tools exist for a connector
- which tool should the agent use
- what inputs a tool requires
- what output shape a tool returns
- how to reduce the tool set before giving tools to an LLM

## Discovery workflow

1. Identify the target connector or exact tool name.
2. Use the Scalekit SDK to fetch live tool metadata (see code below).
3. Summarize:
   - tool name
   - connector
   - what the tool does
   - required fields from `input_schema.required`
   - optional fields from `input_schema.properties`
   - important fields from `output_schema.properties`
4. Recommend the smallest useful tool set for the workflow.

## Live tool discovery (Python)

```python
import scalekit.client, os
from dotenv import load_dotenv
load_dotenv()

client = scalekit.client.ScalekitClient(
    client_id=os.getenv("SCALEKIT_CLIENT_ID"),
    client_secret=os.getenv("SCALEKIT_CLIENT_SECRET"),
    env_url=os.getenv("SCALEKIT_ENV_URL"),
)

# List all tools for a provider
tools = client.actions.get_tools(providers=["GMAIL"], page_size=100)
for tool in tools.tools:
    print(f"Tool: {tool.name}")
    print(f"  Description: {tool.description}")
    print(f"  Input schema: {tool.input_schema}")
    print(f"  Output schema: {tool.output_schema}")

# Get a specific tool by name
tool = client.actions.get_tools(tool_name="gmail_fetch_mails")
```

## Live tool discovery (Node.js)

```typescript
import { ScalekitClient } from '@scalekit-sdk/node';
import 'dotenv/config';

const client = new ScalekitClient(
  process.env.SCALEKIT_ENV_URL!,
  process.env.SCALEKIT_CLIENT_ID!,
  process.env.SCALEKIT_CLIENT_SECRET!
);

// List all tools for a provider
const tools = await client.actions.getTools({ providers: ['GMAIL'], pageSize: 100 });
for (const tool of tools.tools) {
  console.log(`Tool: ${tool.name}`);
  console.log(`  Description: ${tool.description}`);
}

// Get a specific tool by name
const tool = await client.actions.getTools({ toolName: 'gmail_fetch_mails' });
```

## Terminology

- `connector`: Gmail, Slack, Salesforce, Notion, or a custom connector
- `connection`: the exact dashboard configuration name used for authorization
- `connected account`: the per-user authorized record
- `tool`: the executable action exposed by a connector

Use `connector` in explanations. Only use `provider` when the SDK or API filter field literally expects that name.

## What to emphasize

- `connection_name` is the exact dashboard value and may not equal the connector slug.
- Tool metadata is the durable way to determine current inputs and outputs.
- Restrict the tool set before handing it to an LLM. Fewer relevant tools improve tool selection and parameter filling.

## Deep reference

- AgentKit overview: [docs.scalekit.com/agentkit/overview](https://docs.scalekit.com/agentkit/overview/)
- Tool discovery: [docs.scalekit.com/agentkit/tool-discovery](https://docs.scalekit.com/agentkit/tool-discovery/)
- Connectors catalog: [docs.scalekit.com/agentkit/connectors](https://docs.scalekit.com/agentkit/connectors/)

## When to switch skills

- Use `integrating-agentkit` for the full integration workflow (create account, authorize, execute).
- Use the Scalekit MCP server (`https://mcp.scalekit.com`) to validate a tool call interactively.
- Use `exposing-agentkit-via-mcp` to expose discovered tools over MCP.