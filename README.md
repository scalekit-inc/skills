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

**18 skills** across 3 product categories.

### Getting Started

| Skill | Description |
|-------|-------------|
| `setup-scalekit` | Guided setup — detects your AI coding tool and walks through plugin installation and auth type selection |

### AgentKit

Skills for connecting AI agents to third-party services like Gmail, Slack, and Notion via [AgentKit](https://docs.scalekit.com/agentkit/quickstart/).

| Skill | Description |
|-------|-------------|
| `integrating-agentkit` | Integrate AgentKit for connections, authorization, tool discovery, and execution |
| `exposing-agentkit-via-mcp` | Configure AgentKit MCP endpoints for LangChain/LangGraph agents |
| `discovering-connector-tools` | Discover live tools and inspect input/output schemas for any connector |
| `sk-actions-custom-provider` | Create custom connectors with OAuth, Basic, Bearer, or API Key auth |
| `production-readiness-agentkit` | Production readiness checklist for AgentKit implementations |

### SaaSKit

Skills for implementing authentication, SSO, SCIM, MCP server auth, and RBAC via [SaaSKit](https://docs.scalekit.com/authenticate/fsa/quickstart/).

| Skill | Description |
|-------|-------------|
| `implementing-saaskit` | SaaSKit auth (sign-up, login, logout, sessions) across Node.js, Python, Go, Java |
| `implementing-saaskit-nextjs` | SaaSKit auth in Next.js App Router with @scalekit-sdk/node |
| `implementing-saaskit-python` | SaaSKit auth in Django, FastAPI, or Flask with scalekit-sdk-python |
| `implementing-modular-sso` | Enterprise SSO (SAML/OIDC), IdP-initiated login, and admin portal |
| `implementing-scim-provisioning` | SCIM user provisioning using Scalekit Directory API and webhooks |
| `implementing-access-control` | Server-side RBAC with role/permission validation at route boundaries |
| `managing-saaskit-sessions` | Token storage, validation, refresh middleware, and session revocation |
| `adding-mcp-oauth` | OAuth 2.1 authorization for MCP servers (Express, FastAPI, FastMCP) |
| `adding-api-auth` | API keys (org/user scoped) and OAuth 2.0 client credentials for M2M auth |
| `migrating-to-saaskit` | Incremental migration from existing auth systems to SaaSKit |
| `testing-auth-setup` | Validate auth integration via the dryrun CLI |
| `production-readiness-saaskit` | Unified production readiness checklist (auth, SSO, SCIM, MCP, RBAC) |

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
