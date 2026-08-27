# Scalekit Skills

[Agent Skills](https://agentskills.io) that teach AI coding agents how to integrate [Scalekit](https://scalekit.com) authentication into your applications. Each skill contains step-by-step instructions, code patterns, and reference material for a specific integration task — from adding OAuth to an MCP server to implementing full-stack auth with session management.

Skills work with any agent that supports the [Agent Skills spec](https://agentskills.io/specification): Claude Code, Cursor, Windsurf, and others.

## Quick Start

### Claude Code

```bash
# Install the onboarding skill to get guided setup
npx skills add scalekit-inc/skills --skill setup-scalekit

# Browse and install specific skills
npx skills add scalekit-inc/skills --skill adding-mcp-oauth

# List all available skills
npx skills add scalekit-inc/skills --list

# Install all skills globally
npx skills add scalekit-inc/skills --all --global
```

After installing, just describe what you want — Claude will automatically activate the relevant skill. For example: *"Add OAuth to my MCP server using Scalekit"* will trigger the `adding-mcp-oauth` skill.

### Cursor / Windsurf

Copy the `SKILL.md` file from any skill directory into your project's `.cursor/skills/` or `.windsurf/skills/` directory.

## Skills Catalog

**38 skills** across 5 product categories.

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
| `sk-actions-custom-provider` | Create custom Scalekit providers/connectors with OAuth, Basic, Bearer, or API Key auth |
| `check-agentkit-prod` | AgentKit go-live: every item PASS or WAIVE with a reason |

### Full-Stack Auth

Skills for implementing complete authentication flows — login, signup, sessions, RBAC, and framework-specific integrations.

| Skill | Description |
|-------|-------------|
| `implement-saaskit` | Login, callback, session cookies, and logout |
| `implementing-fsa-logout` | Complete logout flow clearing session cookies and invalidating sessions |
| `manage-saaskit-sessions` | Store, validate, refresh, and revoke a session |
| `implementing-access-control` | Server-side RBAC with role/permission validation at route boundaries |
| `implementing-admin-portal` | Admin portal for customer self-serve SSO and SCIM configuration |
| `add-api-auth` | API key or client-credentials auth to protect an API |
| `migrating-to-scalekit-auth` | Incremental migration from existing auth systems to Scalekit |
| `production-readiness-full-stack-auth` | Production readiness checklist for full-stack authentication |

**Framework guides:**

| Skill | Framework |
|-------|-----------|
| `implementing-scalekit-nextjs-auth` | Next.js (App Router) |
| `implementing-scalekit-django-auth` | Django |
| `implementing-scalekit-fastapi-auth` | FastAPI |
| `implementing-scalekit-flask-auth` | Flask |
| `implementing-scalekit-go-auth` | Go (Gin) |
| `implementing-scalekit-laravel-auth` | Laravel |
| `implementing-scalekit-springboot-auth` | Spring Boot 3.x |

### MCP Auth

Skills for securing MCP (Model Context Protocol) servers with OAuth 2.1 — protect tools that Claude Desktop, Cursor, and VS Code connect to.

| Skill | Description |
|-------|-------------|
| `adding-mcp-oauth` | Add OAuth 2.1 to MCP servers for Claude Desktop, Cursor, and VS Code |
| `mcp-oauth-fastmcp` | OAuth 2.1 authorization for FastMCP servers using Scalekit provider |
| `mcp-oauth21-scalekit` | Production OAuth 2.1 with .well-known discovery and Bearer token validation |
| `mcp-auth-expressjs-scalekit` | Scalekit OAuth in Express.js MCP server with middleware and transport |
| `mcp-auth-fastapi-fastmcp-scalekit` | Scalekit OAuth in FastAPI+FastMCP with middleware-level token validation |
| `mcp-auth-fastmcp-scalekit` | Scalekit OAuth in FastMCP with per-tool scope checks |
| `express-mcp-server` | Build an MCP server using Express.js, TypeScript, and OAuth 2.1 |
| `fastapi-fastmcp` | Build an MCP server using FastAPI, FastMCP, and OAuth 2.1 |
| `production-readiness-mcp-auth` | Production readiness checklist for MCP authentication |

### Modular SSO

Skills for adding enterprise SSO to existing applications without replacing your auth system.

| Skill | Description |
|-------|-------------|
| `implement-sso` | SAML/OIDC, IdP-initiated login, and the admin portal |
| `production-readiness-sso` | Production readiness checklist for SSO implementations |

### Modular SCIM

Skills for implementing SCIM directory sync — automated user provisioning and deprovisioning.

| Skill | Description |
|-------|-------------|
| `implementing-scim-provisioning` | SCIM user provisioning using Scalekit Directory API and webhooks |
| `implementing-admin-portal-scim` | Admin portal for customer self-serve SCIM and SSO configuration |
| `production-readiness-scim` | Production readiness checklist for SCIM provisioning |

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
