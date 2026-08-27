# AGENTS.md

This repo is the portable Scalekit **skills** pack. It follows the [Agent Skills spec](https://agentskills.io/specification). No plugin wrapper, no agents, no hooks, no commands.

The plugin pack (marketplaces, MCP config) lives in [scalekit-inc/authstack](https://github.com/scalekit-inc/authstack). Keep `SKILL.md` text aligned with the matching skill under `authstack/kits/*/skills/`.

The four tool-specific repos (`claude-code-authstack`, `cursor-authstack`, `codex-authstack`, `github-copilot-authstack`) are archived. Do not copy skills into them.

## Layout

```
skills/<skill-name>/SKILL.md
```

Flat only. Required by skills.sh.

## Invocation

User-invoked (`disable-model-invocation: true`): `setup-scalekit`, `setup-agentkit`, `setup-saaskit`, `testing-auth-setup`, `production-readiness-agentkit`, `production-readiness-saaskit`.

Model-invoked: every other skill.

## Writing bar

- One job per skill.
- Description states what + when. Front-load `AgentKit`, `SaaSKit`, `connection`, `connected account`, or `dryrun`.
- `SKILL.md` stays at or under 200 lines. Framework dumps go in `references/` in the same folder. One hop only.
- Every step ends on a checkable completion criterion.
- Connector catalog is https://docs.scalekit.com/agentkit/connectors.md. Do not copy connector pages into this repo.
- Point at `https://docs.scalekit.com/llms.txt` and `https://mcp.scalekit.com`. Do not cache them.

## After a skill edit

1. `name` matches the folder name.
2. Update the catalog in `README.md`.
3. Copy the same files into the matching path in `scalekit-inc/authstack`.
