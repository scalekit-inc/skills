---
name: setup-scalekit
description: Guides developers through Scalekit onboarding — installs the CLI, helps choose the right auth plugin (agentkit or saaskit), and walks through plugin setup for their AI coding tool. Use when a developer is new to Scalekit, needs to install the Scalekit plugin for Claude Code, Codex, Copilot CLI, Cursor, or other agents, wants to connect an AI agent to third-party services (Gmail, Slack, Notion, Google Calendar) via OAuth, or wants to add authentication (SSO, SCIM, sessions, RBAC) to a project but hasn't chosen an approach yet.
---

# Setup Scalekit

## Step 1 — Install the CLI

```bash
npm i -g @scalekit-inc/cli
```

Verify: `scalekit --version` should print a version number.

## Step 2 — Choose your plugin

| Plugin | Use case |
|--------|----------|
| `agentkit` | AI agent needs OAuth access to third-party services — connections, tool discovery, token storage / refresh |
| `saaskit` | Web app needs login, sessions, SSO, SCIM, MCP server auth, RBAC, or API keys |

## Step 3 — Install for your tool

### Claude Code

```
/plugin marketplace add scalekit-inc/claude-code-authstack
/plugin install agentkit@claude-code-authstack   # or saaskit
```

Verify: restart Claude Code, then run `/plugin list` — the plugin should appear as enabled.

### GitHub Copilot CLI

```bash
copilot plugin marketplace add scalekit-inc/github-copilot-authstack
copilot plugin install agentkit@github-copilot-authstack   # or saaskit
```

Verify: `copilot plugin list` should show the plugin.

### Codex

```bash
curl -fsSL https://raw.githubusercontent.com/scalekit-inc/codex-authstack/main/install.sh | bash
```

Post-install: restart Codex → Plugin Directory → select **Scalekit Auth Stack** → enable your plugin.

### Cursor

```bash
curl -fsSL https://raw.githubusercontent.com/scalekit-inc/cursor-authstack/main/install.sh | bash
```

Post-install: restart Cursor → **Settings → Cursor Settings → Plugins** → enable your plugin.

### Other agents (OpenCode, Windsurf, Cline, Gemini CLI, 35+)

```bash
npx skills add scalekit-inc/skills --list              # see available skills
npx skills add scalekit-inc/skills --skill integrating-agentkit
npx skills add scalekit-inc/skills --skill implementing-saaskit
npx skills add scalekit-inc/skills --all                # or install everything
```

## Step 4 — Start building

Describe your goal and the installed skill will guide implementation:

- *"Add OAuth to my MCP server so Claude Desktop can connect"*
- *"Implement login and signup with JWT session management"*
- *"Connect my AI agent to Gmail and Google Calendar"*
- *"Add enterprise SSO to my existing app"*

## Documentation

| Resource | URL | When to use |
|----------|-----|-------------|
| LLM doc index | `https://docs.scalekit.com/llms.txt` | Maps each product to its doc set — start here |
| API reference | `https://docs.scalekit.com/apis.md` | Full REST API (OpenAPI-generated) |
| Docs sitemap | `https://docs.scalekit.com/sitemap-0.xml` | Find specific guides or pages |
