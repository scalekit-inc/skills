# AGENTS.md

This repo is the portable Scalekit **skills** pack. It follows the [Agent Skills spec](https://agentskills.io/specification). No plugin wrapper, no agents, no hooks, no commands.

The plugin pack (marketplaces, MCP config) lives in [scalekit-inc/authstack](https://github.com/scalekit-inc/authstack). Keep `SKILL.md` text aligned with the matching skill under `authstack/kits/*/skills/` or `authstack/skills/`. Do not invent a third wording.

The four tool-specific repos (`claude-code-authstack`, `cursor-authstack`, `codex-authstack`, `github-copilot-authstack`) are archived. Do not copy skills into them.

## Layout

```
skills/<skill-name>/SKILL.md
scripts/validate.sh
```

Flat only. Required by skills.sh. Plugin files do not live here.

## Invocation

Every skill is **model-invoked**. Do not set `disable-model-invocation`.

After CLI install, English is the normal path. "Setup AgentKit in this project" must fire `setup-agentkit`.

`setup-scalekit` names the kit. Then `setup-agentkit` or `setup-saaskit`. Those two stay model-invoked so a user who already installed the CLI can skip the router.

The invocation table lives in `scalekit-inc/authstack` `AGENTS.md`. Update that table when you add or rename a skill. Do not keep a second copy here.

Folder names on disk match the invocation table in `scalekit-inc/authstack` `AGENTS.md`.

## Writing bar

- One job per skill.
- Description contract: action verb first, then `Use when`, then a sibling `It does not … (that's \`name\`)`.
- Leading words live in `CONTEXT.md`. Do not redefine them here.
- `SKILL.md` stays at or under 200 lines. Framework dumps go in `references/` in the same folder. One hop only.
- Every step ends on a checkable completion criterion.
- Point at the live environment. Do not cache CLI help, `https://docs.scalekit.com/llms.txt`, or MCP output.
- Live lookups: `npx @scalekit-inc/cli --help`, `https://docs.scalekit.com/llms.txt`, `https://mcp.scalekit.com`.
- Connector catalog is https://docs.scalekit.com/agentkit/connectors.md. Do not copy connector pages into this repo.

## After a skill edit

1. `scripts/validate.sh` must pass.
2. Update the catalog in `README.md`.
3. Copy the same files into the matching path in `scalekit-inc/authstack`.
