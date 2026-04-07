---
name: setup-scalekit
description: Use when a developer is new to Scalekit and needs guidance on where to start, doesn't know which auth plugin or skill to choose, wants to connect an AI agent or agentic workflow to third-party services (Gmail, Slack, Notion, Google Calendar), needs OAuth or tool-calling auth for agents, wants to add authentication to a project but hasn't chosen an approach yet, or needs to install the Scalekit plugin for their AI coding tool (Claude Code, Codex, Copilot CLI, Cursor, or other agents).
---

# Installing Scalekit Auth Stack

**Important**: This skill guides you through installing Scalekit yourself. You'll execute the commands and make the choices — the AI assistant is here to provide clear instructions and answer questions along the way.

## Step 1 — Identify your AI coding tool

First, identify which AI coding tool you're using. If you're not sure, check your current environment or tell the assistant what tool you're working in.

Then find the matching section below for your tool.

---

## Step 2 — Choose your auth plugin

Review the table below and select the plugin that matches what you're building:

| Plugin name | When to use |
|-------------|-------------|
| `agent-auth` | AI agent needs OAuth access to third-party services (Gmail, Slack, Notion, etc.) |
| `full-stack-auth` | Web app needs login, signup, sessions, and RBAC |
| `mcp-auth` | Building an MCP server that needs OAuth 2.1 to secure its tools |
| `modular-sso` | Adding enterprise SSO to an existing app without replacing its auth |
| `modular-scim` | Automated user provisioning and deprovisioning via directory sync |

You'll use this plugin name in the install commands in the next step.

---

## User-driven setup process

When setting up Scalekit, you (the user) should:

1. **Review the instructions** for your AI coding tool below
2. **Execute the install commands yourself** in your terminal
3. **Restart your tool** if required
4. **Enable the plugin** for your chosen auth type
5. **Ask questions** if anything is unclear

The AI assistant can:
- Explain what each command does
- Help you troubleshoot errors
- Guide you to the next step
- Answer questions about auth types and plugins

**You remain in control** of executing commands and making changes to your environment.

---

## Claude Code

Run these commands inside Claude Code (the REPL prompt, not the terminal):

```
/plugin marketplace add scalekit-inc/claude-code-authstack

# Pick one based on your auth needs:
/plugin install agent-auth@scalekit-auth-stack
/plugin install full-stack-auth@scalekit-auth-stack
/plugin install mcp-auth@scalekit-auth-stack
/plugin install modular-sso@scalekit-auth-stack
/plugin install modular-scim@scalekit-auth-stack
```

After running the commands, restart Claude Code for the plugin to take effect.

---

## GitHub Copilot CLI

Run these commands in your terminal:

```bash
copilot plugin marketplace add scalekit-inc/github-copilot-authstack

# Pick one based on your auth needs:
copilot plugin install agent-auth@scalekit-auth-stack
copilot plugin install full-stack-auth@scalekit-auth-stack
copilot plugin install mcp-auth@scalekit-auth-stack
copilot plugin install modular-sso@scalekit-auth-stack
copilot plugin install modular-scim@scalekit-auth-stack
```

After running the commands, the plugin will be installed and ready to use.

---

## Codex

Run this installer script in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/scalekit-inc/codex-authstack/main/install.sh | bash
```

After the script completes, you'll need to:
1. Restart Codex
2. Open Plugin Directory
3. Select **Scalekit Auth Stack**
4. Enable the plugin for your auth type

These manual steps are required to activate the plugin in Codex.

---

## Cursor

Cursor marketplace review is pending — install locally by running this script in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/scalekit-inc/cursor-authstack/main/install.sh | bash
```

After the script completes, you'll need to:
1. Restart Cursor
2. Go to **Settings → Cursor Settings → Plugins**
3. Enable the plugin for your auth type

These manual steps are required to activate the plugin in Cursor.

---

## Other Agents

For OpenCode, Windsurf, Cline, Gemini CLI, and 35+ other agents — use the Vercel Skills CLI.

First, see all available Scalekit skills:

```bash
npx skills add scalekit-inc/skills --list
```

Then pick one based on your auth type and run the install command:

```bash
npx skills add scalekit-inc/skills --skill integrating-agent-auth
npx skills add scalekit-inc/skills --skill implementing-scalekit-fsa
npx skills add scalekit-inc/skills --skill adding-mcp-oauth
npx skills add scalekit-inc/skills --skill modular-sso
npx skills add scalekit-inc/skills --skill implementing-scim-provisioning
```

Or install everything at once:

```bash
npx skills add scalekit-inc/skills --all
```

Run the command that matches your needs in your terminal.

---

## Step 3 — Start implementing

Once you've installed the plugin or skill, you can start implementing. Describe your goal in natural language and the AI assistant will guide you through the process:

- *"Add OAuth to my MCP server so Claude Desktop can connect to it"*
- *"Implement login and signup with JWT session management"*
- *"Connect my AI agent to Gmail and Google Calendar using OAuth"*
- *"Add enterprise SSO to my existing app"*

The assistant will provide step-by-step instructions, code examples, and explanations. You'll implement the changes yourself with guidance.

---

## Documentation

You can fetch these resources to learn more about Scalekit:

| Resource | URL | When to use |
|----------|-----|-------------|
| **LLM doc index** | `https://docs.scalekit.com/llms.txt` | Start here — maps each Scalekit product (Agent Auth, MCP, FSA, SSO, SCIM) to its documentation set. Fetch this to understand which docs apply to your auth type before implementing. |
| **API reference** | `https://docs.scalekit.com/apis.md` | Full REST API reference in Markdown (generated from OpenAPI spec). Covers Connected Accounts, Connections, Organizations, Users, Tool Execution, Admin Portal endpoints with request/response schemas. |
| **Docs sitemap** | `https://docs.scalekit.com/sitemap-0.xml` | Complete index of all documentation pages. Use to discover specific guides (e.g. a framework integration, provider setup, or troubleshooting page) when you need a URL you don't have. |

**Recommended lookup flow:**
1. Fetch `llms.txt` to identify the right documentation set for your chosen auth type
2. Fetch `apis.md` when you need specific endpoint details during implementation
3. Query the sitemap only if you need to find a page not covered by the above two

You can ask the AI assistant to fetch these resources for you when needed.
