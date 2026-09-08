# AgentKit on Hermes

Use this file when the host is Hermes. Do not run the OpenClaw `clawhub` step in `SKILL.md`.

Wire Hermes so it can act as a named user through AgentKit. Then stop.

## Guardrails

- **MUST** copy the runtime skill and `scripts/` onto the Hermes profile. Do not `hermes skills install` this parent folder. That file is for coding agents.
- **MUST** put only Scalekit client credentials in the Hermes env file.
- **MUST NOT** run `hermes mcp login` against Scalekit. **MUST NOT** mint a Virtual MCP session token.

## Gotchas

- Env names: `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, `SCALEKIT_IDENTIFIER`. Never `SCALEKIT_ENV_URL`.
- Hermes already injects declared env vars into the process. The script reads the environment. It does not open the Hermes env file.
- The Slack gateway bot is a channel. It is not the named user.
- Cron cannot click a magic link. The connected account must already be `ACTIVE`.

## Step 1 — Copy the runtime skill

Clone the public repo, then copy from the skill directory:

```bash
git clone --depth 1 https://github.com/scalekit-inc/authstack.git
cd authstack/kits/agentkit/skills/integrate-agentkit-host
DEST="${HERMES_HOME:-$HOME/.hermes}/skills/scalekit-agent-auth"
mkdir -p "$DEST/scripts"
cp references/runtime-skill.md "$DEST/SKILL.md"
cp scripts/tool_exec.py scripts/pyproject.toml "$DEST/scripts/"
cd "$DEST/scripts" && uv sync
```

The on-host folder name stays `scalekit-agent-auth` so it matches the shipped ClawHub **install slug**. The ClawHub listing frontmatter `name` is `openclaw-tool-executor`. That is slug parity, not skill-name parity.

**Done when:** `hermes skills list` shows `scalekit-agent-auth`.

## Step 2 — Write host env

Add Scalekit **client** credentials to the Hermes env file (`~/.hermes/.env` for the default profile):

```bash
SCALEKIT_ENVIRONMENT_URL=https://your-env.scalekit.cloud
SCALEKIT_CLIENT_ID=<from dashboard>
SCALEKIT_CLIENT_SECRET=<from dashboard>
SCALEKIT_IDENTIFIER=<named user>
```

**Done when:** those four names exist in the Hermes env file, and source files do not hardcode the secret.

## Step 3 — Confirm the connection

```bash
cd "${HERMES_HOME:-$HOME/.hermes}/skills/scalekit-agent-auth/scripts"
uv run tool_exec.py --list-connections --provider GMAIL
```

Use the Connection Name from `setup-agentkit`. Gmail with no dashboard row is `gmail`.

**Done when:** a completed connection is listed, or `setup-agentkit` is named and this file has stopped.

## Step 4 — Authorize if needed

```bash
uv run tool_exec.py --generate-link --connection-name <CONNECTION_NAME>
```

OAuth: if not `ACTIVE`, show the magic link and wait.

**Done when:** the connected account is `ACTIVE`, or the next action is on screen.

## Step 5 — Stop

Name one real Hermes prompt, for example `/scalekit-agent-auth show my unread emails`. Do not write app-code SDK calls.

**Done when:** the runtime skill is on the Hermes profile, env is set, and this file has stopped.

## Live lookups

- Hermes skills: https://hermes-agent.nousresearch.com/docs/user-guide/features/skills
- Docs index: https://docs.scalekit.com/llms.txt
- Connector catalog: https://docs.scalekit.com/agentkit/connectors.md
