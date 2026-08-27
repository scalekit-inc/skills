---
name: run-dryrun
description: >
  Runs dryrun so an agent can test a SaaSKit auth setup
  before go-live.
  Use when the user wants to test auth or run dryrun.
  It does not write login (that's `implement-saaskit`)
  or finish a go-live checklist (that's `check-saaskit-prod`).
---

# Run dryrun

Run dryrun against a live environment. Then stop.

## Guardrails

- **MUST** confirm `SCALEKIT_ENVIRONMENT_URL` and `SCALEKIT_CLIENT_ID` before the command.
- **MUST** ask for `organization_id` before `--mode=sso`.
- **MUST** show the CLI output and explain pass/fail in plain language.
- **MUST** keep dryrun local. **MUST NOT** expose `http://localhost:12456/auth/callback` to the internet.
- **MUST NOT** write login. Name `implement-saaskit` instead.
- **MUST NOT** finish a go-live checklist. Name `check-saaskit-prod` instead.

## Gotchas

- The CLI flag is `--env_url`. The app env name is `SCALEKIT_ENVIRONMENT_URL`. Never `SCALEKIT_ENV_URL`.
- Register `http://localhost:12456/auth/callback` under Authentication → Redirect URIs. Spell the port and path exactly.
- Node 20+. Local only. Port `12456`. Default mode is `fsa`.
- SSO needs `--organization_id` (`org_…`). Copy it from the dashboard. Do not invent it.
- Client ID starts with `skc_`. Dashboard → Developers → Settings → API Credentials.
- Dryrun does not persist tokens after `Ctrl+C`.
- Dashboard steps are **user actions**. Print the checklist. Wait. Do not click the dashboard.

## Step 1 — Confirm env and Node

Need Node 20+. Need these two values:

```bash
echo $SCALEKIT_ENVIRONMENT_URL
echo $SCALEKIT_CLIENT_ID
```

`SCALEKIT_CLIENT_ID` must start with `skc_`. If either value is missing, collect them from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Do not invent values.

**Done when:** Node is 20+, both values exist, and the client ID starts with `skc_`.

## Step 2 — Register the dryrun callback

Print this checklist. Wait for the user.

1. Dashboard → Authentication → Redirect URIs
2. Add `http://localhost:12456/auth/callback` exactly

**Done when:** the dashboard lists that exact URL.

## Step 3 — Pick the mode

| Mode | When |
|---|---|
| `fsa` | Default. Hosted login, callback, session. |
| `sso` | User asked to test SSO. Needs `--organization_id`. |

Default to `fsa` unless the user asked for SSO. If they asked for SSO and did not give `organization_id`, ask. Do not guess an `org_…`.

**Done when:** the mode is `fsa`, or the mode is `sso` with a real `org_…`.

## Step 4 — Run dryrun

Full-stack auth:

```bash
npx @scalekit-sdk/dryrun \
  --env_url="$SCALEKIT_ENVIRONMENT_URL" \
  --client_id="$SCALEKIT_CLIENT_ID" \
  --mode=fsa
```

SSO:

```bash
npx @scalekit-sdk/dryrun \
  --env_url="$SCALEKIT_ENVIRONMENT_URL" \
  --client_id="$SCALEKIT_CLIENT_ID" \
  --mode=sso \
  --organization_id=<org_…>
```

The browser opens. The user signs in. The local dashboard must show the user profile and tokens.

If port `12456` is in use, stop the other process and retry.

**Done when:** the local dashboard shows the user profile and tokens.

## Step 5 — Explain the result

Show the command output. Then map failures:

| Symptom | Next step |
|---|---|
| `redirect_uri` mismatch | Add `http://localhost:12456/auth/callback` under Authentication → Redirect URIs |
| Invalid client | Copy `skc_…` from the same env as `--env_url` |
| Organization error | Confirm the org exists, SSO is on, and the id is `org_…` |
| Port in use | Stop the process on `12456` and retry |

**Done when:** the user has a plain-language pass or fail.

## Step 6 — Stop

Do not write login. Do not start the go-live checklist.

**Done when:** dryrun showed the profile and tokens, or the failure has a next step, and this skill has stopped.

## Reach for

- `setup-saaskit` if env is missing
- `implement-saaskit` to write login after dryrun
- `implement-sso` if SSO mode failed on a missing connection
- `check-saaskit-prod` for the go-live record

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- Dryrun: https://docs.scalekit.com/dev-kit/tools/scalekit-dryrun/
- MCP: https://mcp.scalekit.com
