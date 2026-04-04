---
name: setup-scalekit
description: Use when a developer is new to Scalekit and needs guidance on where to start, doesn't know which auth plugin or skill to choose, wants to connect an AI agent or agentic workflow to third-party services (Gmail, Slack, Notion, Google Calendar), needs OAuth or tool-calling auth for agents, wants to add authentication to a project but hasn't chosen an approach yet, or needs to install the Scalekit plugin for their AI coding tool (Claude Code, Codex, Copilot CLI, Cursor, or other agents).
---

# Installing Scalekit Auth Stack

Guide the user through installing the Scalekit Auth Stack for their AI coding tool, then help them choose the right auth plugin and start implementing.

## Step 1 — Identify the user's AI coding tool

If not already clear from context, ask: **"Which AI coding tool are you using?"**

Then follow the matching section below.

---

## Step 2 — Choose your auth plugin

Ask the user what they're building if it isn't clear, then recommend:

| Plugin name | When to use |
|-------------|-------------|
| `agent-auth` | AI agent needs OAuth access to third-party services (Gmail, Slack, Notion, etc.) |
| `full-stack-auth` | Web app needs login, signup, sessions, and RBAC |
| `mcp-auth` | Building an MCP server that needs OAuth 2.1 to secure its tools |
| `modular-sso` | Adding enterprise SSO to an existing app without replacing its auth |
| `modular-scim` | Automated user provisioning and deprovisioning via directory sync |

Use the chosen plugin name in the install commands below.

---

## Agent behavior — install first

When the user asks to "set up Scalekit", "install Scalekit", or similar, the next action should usually be to run the install command for the user's AI coding tool.

- Prioritize plugin or skill installation before making repo-local code changes.
- Do not start patching the user's app before installation unless the user explicitly says the plugin or skill is already installed, or explicitly asks to skip installation.
- If the install changes the agent's global environment, requires a restart, or needs user approval in the current runtime, state that clearly and then run the install command as the next step.
- After a Codex or Cursor local install completes, stop and tell the user to restart the tool and enable the right plugin before continuing with implementation.

---

## Claude Code

```bash
claude marketplace add scalekit-inc/claude-code-authstack

# Pick one:
claude plugin install agent-auth
claude plugin install full-stack-auth
claude plugin install mcp-auth
claude plugin install modular-sso
claude plugin install modular-scim
```

---

## GitHub Copilot CLI

```bash
copilot plugin marketplace add scalekit-inc/github-copilot-authstack

# Pick one:
copilot plugin install agent-auth@scalekit-auth-stack
copilot plugin install full-stack-auth@scalekit-auth-stack
copilot plugin install mcp-auth@scalekit-auth-stack
copilot plugin install modular-sso@scalekit-auth-stack
copilot plugin install modular-scim@scalekit-auth-stack
```

---

## Codex

When the user is in Codex and asks to set up Scalekit, run this installer first rather than editing the repo:

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

# Pick one based on your auth type:
npx skills add scalekit-inc/skills --skill integrating-agent-auth
npx skills add scalekit-inc/skills --skill implementing-scalekit-fsa
npx skills add scalekit-inc/skills --skill adding-mcp-oauth
npx skills add scalekit-inc/skills --skill modular-sso
npx skills add scalekit-inc/skills --skill implementing-scim-provisioning

# Or install everything at once:
npx skills add scalekit-inc/skills --all
```

---

## Step 3 — Implement

Once the plugin or skill is installed, the agent will automatically activate the relevant Scalekit skill when you describe your goal in natural language. For example:

- *"Add OAuth to my MCP server so Claude Desktop can connect to it"*
- *"Implement login and signup with JWT session management"*
- *"Connect my AI agent to Gmail and Google Calendar using OAuth"*
- *"Add enterprise SSO to my existing app"*

---

## Documentation

Fetch the right resource depending on what you need:

| Resource | URL | When to use |
|----------|-----|-------------|
| **LLM doc index** | `https://docs.scalekit.com/llms.txt` | Start here — maps each Scalekit product (Agent Auth, MCP, FSA, SSO, SCIM) to its documentation set. Fetch this to understand which docs apply to the user's auth type before implementing. |
| **API reference** | `https://docs.scalekit.com/apis.md` | Full REST API reference in Markdown (generated from OpenAPI spec). Covers Connected Accounts, Connections, Organizations, Users, Tool Execution, Admin Portal endpoints with request/response schemas. |
| **Docs sitemap** | `https://docs.scalekit.com/sitemap-0.xml` | Complete index of all documentation pages. Use to discover specific guides (e.g. a framework integration, provider setup, or troubleshooting page) when you need a URL you don't have. |

**Recommended lookup flow:**
1. Fetch `llms.txt` to identify the right documentation set for the user's chosen auth type
2. Fetch `apis.md` when you need specific endpoint details during implementation
3. Query the sitemap only if you need to find a page not covered by the above two
