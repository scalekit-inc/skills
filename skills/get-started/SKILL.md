---
name: get-started
description: Use when a developer wants to get started with Scalekit, install the Scalekit plugin or skill, or set up an AI coding tool (Claude Code, Codex, Copilot CLI, Cursor, or other agents) to implement Scalekit authentication.
---

# Installing Scalekit Auth Stack

Guide the user through installing the Scalekit Auth Stack for their AI coding tool, then help them choose the right auth plugin and start implementing.

## Step 1 — Identify the user's AI coding tool

If not already clear from context, ask: **"Which AI coding tool are you using?"**

Then follow the matching section below.

---

## Claude Code

```bash
claude marketplace add scalekit-inc/claude-code-authstack
claude plugin install agent-auth
```

Replace `agent-auth` with the chosen plugin name (see [Step 2](#step-2--choose-your-auth-plugin)).

---

## GitHub Copilot CLI

```bash
copilot plugin marketplace add scalekit-inc/github-copilot-authstack
copilot plugin install agent-auth@scalekit-auth-stack
```

Replace `agent-auth` with the chosen plugin name.

---

## Codex

```bash
curl -fsSL https://raw.githubusercontent.com/scalekit-inc/codex-authstack/main/install.sh | bash
```

After the script completes:
1. Restart Codex
2. Open Plugin Directory
3. Select **Scalekit Auth Stack**
4. Enable the plugin for your auth type

---

## Cursor

Cursor marketplace review is pending — install locally:

```bash
curl -fsSL https://raw.githubusercontent.com/scalekit-inc/cursor-authstack/main/install.sh | bash
```

After the script completes:
1. Restart Cursor
2. Go to **Settings → Cursor Settings → Plugins**
3. Enable the plugin for your auth type

---

## Other Agents

For OpenCode, Windsurf, Cline, Gemini CLI, and 35+ other agents — use the Vercel Skills CLI:

```bash
# See all available Scalekit skills
npx skills add scalekit-inc/skills --list

# Install a specific skill
npx skills add scalekit-inc/skills --skill agent-auth
```

---

## Step 2 — Choose your auth plugin

Ask the user what they're building if it isn't clear, then recommend:

| Plugin | When to use |
|--------|-------------|
| `agent-auth` | AI agent needs OAuth access to third-party services (Gmail, Slack, Notion, etc.) |
| `full-stack-auth` | Web app needs login, signup, sessions, and RBAC |
| `mcp-auth` | Building an MCP server that needs OAuth 2.1 to secure its tools |
| `modular-sso` | Adding enterprise SSO to an existing app without replacing its auth |
| `modular-scim` | Automated user provisioning and deprovisioning via directory sync |

---

## Step 3 — Implement

Once the plugin or skill is installed, the agent will automatically activate the relevant Scalekit skill when you describe your goal in natural language. For example:

- *"Add OAuth to my MCP server so Claude Desktop can connect to it"*
- *"Implement login and signup with JWT session management"*
- *"Connect my AI agent to Gmail and Google Calendar using OAuth"*
- *"Add enterprise SSO to my existing app"*

Full documentation: [docs.scalekit.com/dev-kit/build-with-ai](https://docs.scalekit.com/dev-kit/build-with-ai/)
