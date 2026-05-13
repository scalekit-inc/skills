# AGENTS.md

This repository contains portable Scalekit skills that follow the [Agent Skills spec](https://agentskills.io/specification).
Any agent changing this repo must follow this document.

## What this repo contains

Standalone skills that teach AI coding agents how to integrate Scalekit authentication. Unlike the auth stack repos (claude-code-authstack, codex-authstack, cursor-authstack, github-copilot-authstack), this repo has no plugin wrapper, no agents, no rules, no hooks, and no commands. It is pure skills.

Skills from this repo are distributed via:
- `npx skills add scalekit-inc/skills --skill <name>` (Claude Code)
- Manual copy of `SKILL.md` into `.cursor/skills/` or `.windsurf/skills/` (Cursor, Windsurf)
- Any tool supporting the Agent Skills spec

## Layout

```
skills/
├── skills/
│   ├── setup-scalekit/                # Getting started
│   │   └── SKILL.md
│   ├── integrating-agentkit/          # AgentKit skills
│   │   └── SKILL.md
│   ├── discovering-connector-tools/
│   │   └── SKILL.md
│   ├── ...
│   └── production-readiness-saaskit/  # SaaSKit skills
│       └── SKILL.md
├── README.md
├── AGENTS.md                          # This file
└── scalekit-logo.svg
```

## Skill inventory (18 skills)

### Getting Started (1)
- `setup-scalekit` — guided onboarding

### AgentKit (5)
- `integrating-agentkit` — core integration
- `exposing-agentkit-via-mcp` — MCP endpoint configuration
- `discovering-connector-tools` — live tool discovery
- `sk-actions-custom-provider` — custom connectors
- `production-readiness-agentkit` — production checklist

### SaaSKit (12)
- `implementing-saaskit` — core auth flow
- `implementing-saaskit-nextjs` — Next.js auth
- `implementing-saaskit-python` — Django, FastAPI, Flask
- `implementing-modular-sso` — enterprise SSO
- `implementing-scim-provisioning` — SCIM directory sync
- `implementing-access-control` — RBAC
- `managing-saaskit-sessions` — session management
- `adding-mcp-oauth` — MCP server OAuth
- `adding-api-auth` — API keys and client credentials
- `migrating-to-saaskit` — migration from existing auth
- `testing-auth-setup` — dryrun CLI validation
- `production-readiness-saaskit` — unified production checklist

## Non-negotiable rules

- Maintain flat `skills/<skill-name>/SKILL.md` structure. Do not nest skills inside categories or add wrapper directories. This flat layout is required for skills.sh and Tessl compatibility.
- Never add secrets, tokens, credentials, or private endpoints to any file.
- Keep instructions stable and agent-agnostic. Skills must work across Claude Code, Cursor, Windsurf, and any Agent Skills-compatible tool. Do not use agent-specific features (slash commands, `.mdc` rules, hooks, sub-agents).
- Use the Scalekit MCP server (`https://mcp.scalekit.com`) as the live playground for tool discovery and execution. Do not create skills that duplicate MCP server capabilities.

## Skill authoring rules

Each skill is a folder containing at minimum a `SKILL.md` file.

### Required frontmatter

```yaml
---
name: skill-name
description: Third-person description of what this skill does and when to use it.
---
```

- `name` must be lowercase, hyphenated, max 64 chars. Must match the folder name.
- `description` must be third person and include both what it does and when to use it.

### Content structure

```
skill-name/
├── SKILL.md           # Required: frontmatter + instructions
├── scripts/           # Optional: executable utilities
├── references/        # Optional: deep docs, framework-specific files
└── assets/            # Optional: templates, resources
```

### Context budget

- Keep `SKILL.md` focused and practical. Aim for the instructions an agent needs to complete the task.
- Put framework-specific variants in reference files (e.g., `fastapi-reference.md`, `express-reference.md`) linked from `SKILL.md`.
- Do not create multi-hop reference chains. One level of reference files is the maximum.

### Difference from auth stack plugins

| Concern | Auth stack plugins | This repo |
|---------|-------------------|-----------|
| Wrapper | Plugin manifest, README, agents, rules, hooks | None — bare skills |
| Distribution | Marketplace install | `npx skills add` or manual copy |
| Agent-specific features | Yes (slash commands, `.mdc` rules, hooks) | No — agent-agnostic |
| Structure | `plugins/<plugin>/skills/<skill>/SKILL.md` | `skills/<skill>/SKILL.md` |
| MCP config | `.mcp.json` in plugin | Not applicable |

### Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with valid frontmatter.
2. Add the skill to the catalog table in `README.md` under the correct category.
3. Update the skill count in `README.md`.
4. If the skill has framework variants, add reference files in the same directory.
5. Verify the folder name matches the `name` field in frontmatter.

### Removing or renaming a skill

1. Remove or rename the folder under `skills/`.
2. Update the catalog table in `README.md`.
3. Update the skill count in `README.md`.
4. Search all other skills for cross-references and update them.

## Keeping in sync with auth stack repos

Skills in this repo should stay aligned with the canonical content in the auth stack plugins. When a skill is updated in claude-code-authstack (the reference implementation), propagate the content changes here. The structure will differ (no plugin wrapper), but the instructions and code samples should match.