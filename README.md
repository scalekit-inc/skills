# Scalekit Skills

[Agent Skills](https://agentskills.io) that teach AI coding agents how to integrate [Scalekit](https://scalekit.com) authentication into your applications. Each skill contains step-by-step instructions, code patterns, and reference material for a specific integration task — from adding OAuth to an MCP server to implementing full-stack auth with session management.

Skills work with any agent that supports the [Agent Skills spec](https://agentskills.io/specification): Claude Code, Cursor, Windsurf, and others.

## Installation

Pick one path.

### Portable skills pack (this repo)

```bash
npx skills add scalekit-inc/skills --list
```

Install one skill, or all skills:

```bash
npx skills add scalekit-inc/skills --skill setup-scalekit
npx skills add scalekit-inc/skills --all --global
```

After installing, describe what you want. For example: *"Add OAuth to my MCP server using Scalekit"* fires `add-mcp-oauth`.

### AuthStack plugin

Kits, marketplaces, and MCP live in [scalekit-inc/authstack](https://github.com/scalekit-inc/authstack):

```bash
npx @scalekit-inc/cli setup
```

The wizard detects which AI coding tools you have installed and sets up the right kit. To target a specific tool directly:

```bash
npx @scalekit-inc/cli setup claude
npx @scalekit-inc/cli setup cursor
npx @scalekit-inc/cli setup codex
npx @scalekit-inc/cli setup copilot
```

## Skills Catalog

**21 skills.**

### Getting Started

| Skill | Description |
|-------|-------------|
| `setup-scalekit` | Install the CLI/plugin and pick AgentKit or SaaSKit |
| `setup-agentkit` | Dashboard connection, env credentials, and first connector path |
| `setup-saaskit` | Env credentials, redirect URI, and first login URL |

### Agent Auth

Skills for adding OAuth-based agent authentication — connect AI agents to third-party services like Gmail, Slack, and Notion.

| Skill | Description |
|-------|-------------|
| `integrate-agentkit` | Connected account, authorization link, token, and one downstream API call |
| `discover-connectors` | Live catalog and MCP lookup for connector tools and schemas |
| `expose-agentkit-mcp` | Expose AgentKit tools over MCP on a per-user instance URL |
| `check-agentkit-prod` | AgentKit go-live: every item PASS or WAIVE with a reason |

### Full-Stack Auth

Skills for implementing complete authentication flows — login, signup, sessions, RBAC, and framework-specific integrations.

| Skill | Description |
|-------|-------------|
| `implement-saaskit` | Login, callback, session cookies, and logout |
| `manage-saaskit-sessions` | Store, validate, refresh, and revoke a session |
| `implement-access-control` | Roles and permissions at a route |
| `add-api-auth` | API key or client-credentials auth to protect an API |
| `migrate-to-saaskit` | Audit existing auth and import it to SaaSKit |
| `run-dryrun` | Test a SaaSKit auth setup with the dryrun CLI |
| `check-saaskit-prod` | SaaSKit go-live: every item PASS or WAIVE with a reason |
| `review-scalekit-code` | Review a Scalekit snippet. Do not generate login |

**Framework guides:**

| Skill | Framework |
|-------|-----------|
| `implement-saaskit-nextjs` | Next.js (App Router) |
| `implement-saaskit-python` | Django, FastAPI, or Flask |

Go, Java, and Laravel live in `implement-saaskit` `references/`.

### MCP Auth

Skills for securing MCP (Model Context Protocol) servers with OAuth 2.1 — protect tools that Claude Desktop, Cursor, and VS Code connect to.

| Skill | Description |
|-------|-------------|
| `add-mcp-oauth` | Add OAuth 2.1 to MCP servers for Claude Desktop, Cursor, and VS Code |

### Modular SSO

Skills for adding enterprise SSO to existing applications without replacing your auth system.

| Skill | Description |
|-------|-------------|
| `implement-sso` | SAML/OIDC, IdP-initiated login, and the admin portal |

### Modular SCIM

Skills for implementing SCIM directory sync — automated user provisioning and deprovisioning.

| Skill | Description |
|-------|-------------|
| `implement-scim` | Directory webhooks and a user/group map |

### Self-hosted

| Skill | Description |
|-------|-------------|
| `deploy-self-hosted` | Helm or on-prem Scalekit |

## Skill Structure

Each skill follows the [Agent Skills spec](https://agentskills.io/specification):

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
└── assets/           # Optional: templates, resources
```

The `SKILL.md` file contains YAML frontmatter (`name`, `description`) followed by the instructions that the agent follows.

## Links

- [Scalekit Documentation](https://docs.scalekit.com)
- [Agent Skills Specification](https://agentskills.io/specification)
- [What are skills?](https://support.claude.com/en/articles/12512176-what-are-skills)
- [Using skills in Claude](https://support.claude.com/en/articles/12512180-using-skills-in-claude)
