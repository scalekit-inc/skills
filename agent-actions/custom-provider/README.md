# Custom Provider Skill

This skill helps an agent create, review, update, or prepare deletion for a Scalekit custom provider.

It is meant for **proxy-only** connectors.

It helps with:
- reading API and auth docs
- inferring the auth type: `OAUTH`, `BASIC`, `BEARER`, or `API_KEY`
- identifying tracked fields like `domain`, `version`, or `path_variables`
- generating the final provider JSON
- checking whether the provider already exists
- preparing safe create, update, or delete steps

## Install

### Claude Code

Copy this folder to either:
- `~/.claude/skills/custom-provider/`
- `.claude/skills/custom-provider/` inside your repo

Make sure the file exists at:
- `~/.claude/skills/custom-provider/SKILL.md`
- or `.claude/skills/custom-provider/SKILL.md`

### Codex

Copy this folder to:
- `$CODEX_HOME/skills/custom-provider/`

Make sure the file exists at:
- `$CODEX_HOME/skills/custom-provider/SKILL.md`

### GitHub Copilot

Copy this folder to either:
- `~/.copilot/skills/custom-provider/`
- `.github/skills/custom-provider/` inside your repo
- `.claude/skills/custom-provider/` inside your repo

Make sure the file exists at:
- `~/.copilot/skills/custom-provider/SKILL.md`
- or `.github/skills/custom-provider/SKILL.md`

## How To Use

Ask the agent to use the skill directly. Example prompts:

```text
Use $custom-provider to create a custom provider for <provider-name>.
```

```text
Use $custom-provider to review this existing custom provider.
```

```text
Use $custom-provider to update the custom provider for <provider-name>.
```

Then share:
- `SCALEKIT_ENVIRONMENT_URL`
- `SCALEKIT_CLIENT_ID`
- `SCALEKIT_CLIENT_SECRET`
- custom provider name
- API docs link
- auth docs link if separate
- base API URL if known

## Important Behavior

- The skill is only for proxy-only connectors.
- It may fetch an environment access token.
- It may list existing custom providers.
- It only creates after explicit approval.
- It only updates after showing a diff and getting confirmation.
- It does not run delete for you; it prints the delete curl for you to run manually.
