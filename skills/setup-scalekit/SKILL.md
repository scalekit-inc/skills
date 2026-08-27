---
name: setup-scalekit
description: >
  Installs Scalekit, then picks AgentKit or SaaSKit for the project.
  Use when the user wants to install Scalekit, add the plugin, or
  decide which kit to use.
  It does not configure a dashboard connection (that's `setup-agentkit`)
  or set app login env (that's `setup-saaskit`).
---

# Setup Scalekit

Install the Scalekit CLI and plugin. Pick AgentKit or SaaSKit. Stop.

## Guardrails

- **MUST** stop after install + kit pick and name `setup-agentkit` or `setup-saaskit`.
- **MUST NOT** start those wizards from this skill.

## Gotchas

- Run `npx @scalekit-inc/cli setup` first. Use a native plugin command only when that CLI cannot run.
- Marketplace names are `agentkit` and `saaskit`.
- Plugin install uses `scalekit-inc/authstack`. Portable skills use `scalekit-inc/skills`.
- After the kit is picked, name `setup-agentkit` or `setup-saaskit`. Stop. Do not start those wizards here.
- For current CLI flags, run `npx @scalekit-inc/cli --help`.

## Step 1 — Install

```bash
npx @scalekit-inc/cli setup
```

For repeated use:

```bash
npm install -g @scalekit-inc/cli
scalekit setup
```

Target a specific tool only when the user names it:

```bash
npx @scalekit-inc/cli setup claude
npx @scalekit-inc/cli setup cursor
npx @scalekit-inc/cli setup codex
npx @scalekit-inc/cli setup copilot
```

Skip this step when the plugin or skills pack is already installed.

**Done when:** the plugin is visible in the current tool.

| Tool | Check |
|------|--------|
| Claude Code | Restart the session. `/plugin list` shows `agentkit` and/or `saaskit`. |
| GitHub Copilot | `copilot plugin list` shows the plugin. |
| Cursor / Codex | Re-open the tool. Authstack plugins or skills are available. |
| Other (skills CLI) | The chosen skill folder exists on disk (for example `setup-agentkit/SKILL.md` in the tool's skills directory). |

## Step 2 — Pick the kit

| Kit | Pick when the user needs |
|-----|--------------------------|
| AgentKit | connections, token vault, tools |
| SaaSKit | app login, sessions, SSO, SCIM, MCP server auth, API keys |

Ask which kit only when the user has not already named one.

**Done when:** the user has one kit: AgentKit or SaaSKit.

## Step 3 — Name the next skill and stop

- AgentKit → name `setup-agentkit`. Stop.
- SaaSKit → name `setup-saaskit`. Stop.

Tell the user the next skill name. Do not start that wizard here.

**Done when:** `setup-agentkit` or `setup-saaskit` is named, and this skill has stopped.

## Fallback — native install

Use this only when Step 1 cannot run. Then apply the same check as Step 1.

### Claude Code

```
/plugin marketplace add scalekit-inc/authstack
/plugin install agentkit@authstack
```

Use `saaskit@authstack` when the kit is SaaSKit.

### GitHub Copilot

```bash
copilot plugin marketplace add scalekit-inc/authstack
copilot plugin install agentkit@authstack
```

### Other agents

```bash
npx skills add scalekit-inc/skills --all
```

`--all` puts the next named skill on disk, not only the two wizards.

Codex and Cursor go through `npx @scalekit-inc/cli setup`.

## Live lookups

- CLI: `npx @scalekit-inc/cli --help`
- Docs index: https://docs.scalekit.com/llms.txt
- MCP: https://mcp.scalekit.com
