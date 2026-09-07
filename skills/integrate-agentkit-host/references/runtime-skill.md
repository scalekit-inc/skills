---
name: scalekit-agent-auth
description: >
  Use when the host must act as a named user in Gmail, Slack, Notion,
  Calendar, or any Scalekit connection.
  Trigger on unread mail, Slack as a person, Notion pages, or act as alice.
  Do not use for Slack bot chat, bundled GitHub, Linear MCP, or hermes mcp login.
version: 0.1.0
license: MIT
required_environment_variables:
  - name: SCALEKIT_CLIENT_ID
    prompt: Scalekit client ID
    required_for: Scalekit client auth
  - name: SCALEKIT_CLIENT_SECRET
    prompt: Scalekit client secret
    required_for: Scalekit client auth
  - name: SCALEKIT_ENVIRONMENT_URL
    prompt: Scalekit environment URL
    required_for: Scalekit client auth
  - name: SCALEKIT_IDENTIFIER
    prompt: Named user identifier
    required_for: connected-account lookup
---

# Host runtime — act as a named user

The always-on host loads this file at chat time. Coding agents stay on `../SKILL.md`.

Hermes is the host. Scalekit is the vault. Run tools as `SCALEKIT_IDENTIFIER`.

Run commands from the on-host skill `scripts/` directory.

```bash
uv run tool_exec.py --list-connections --provider <PROVIDER>
```

## Step 1 — Discover the connection

Use the first connection with `"status": "COMPLETED"` as `<CONNECTION_NAME>`.

**Done when:** a completed `key_id` exists, or the run stops because none exists.

LinkedIn maps to provider `HARVESTAPI`.

## Step 2 — Check and authorize

```bash
uv run tool_exec.py --generate-link --connection-name <CONNECTION_NAME>
```

OAuth: if not `ACTIVE`, show the magic link, wait, then continue.
API key: if missing or not `ACTIVE`, send the user to the Dashboard and stop.

**Done when:** the connected account is `ACTIVE`, or the next action is on screen.

Do not use `--get-authorization` in this flow.

## Step 3 — Find the tool and its schema

```bash
uv run tool_exec.py --get-tool --provider <PROVIDER>
uv run tool_exec.py --get-tool --tool-name <TOOL_NAME>
```

Use only parameter names from `input_schema.properties`. Include every `required` field.

**Done when:** a matching tool plus its schema exist, or no tool exists.

## Step 4 — Execute

```bash
uv run tool_exec.py --execute-tool \
  --tool-name <TOOL_NAME> \
  --connection-name <CONNECTION_NAME> \
  --tool-input '<JSON_INPUT>'
```

Pass `--identifier <id>` when the user names a person other than `SCALEKIT_IDENTIFIER`.

**Done when:** the tool result is returned.

## Step 5 — Proxy fallback

Only if Step 3 found no tool:

```bash
uv run tool_exec.py --proxy-request \
  --connection-name <CONNECTION_NAME> \
  --path <API_PATH> \
  --method <GET|POST|PUT|DELETE>
```

If the result is `TOOL_PROXY_DISABLED`, say the catalog does not cover this action.

**Done when:** the proxy result is returned, or the action is unsupported.

## Pitfalls

Put only Scalekit client credentials on the host.
Honor `SCALEKIT_IDENTIFIER` as the named user.
Return a magic link when the connected account is not `ACTIVE`.
Do not write Gmail, Slack-user, or Calendar tokens to disk.
Do not run `hermes mcp login` against Scalekit.
Do not mint a Virtual MCP session token.
Do not treat the Slack gateway bot as the named user.
