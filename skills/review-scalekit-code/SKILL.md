---
name: review-scalekit-code
description: >
  Reviews Scalekit snippets so an agent can check if a
  fragment is right.
  Use when the user wants to review this Scalekit code or
  asks if this snippet is right.
  It does not generate login (that's `implement-saaskit`).
---

# Review Scalekit code

Review a Scalekit snippet. Then stop. Do not write a new login.

## Guardrails

- **MUST** review only. **MUST NOT** write a new login, callback, session, or logout.
- **MUST** open [references/REFERENCE.md](references/REFERENCE.md) and [references/COMMON-MISTAKES.md](references/COMMON-MISTAKES.md). Do not paste them here.
- **MUST** say "This method could not be verified" when a call is not in the reference or a live source.
- **MUST NOT** treat `SCALEKIT_ENV_URL` as valid. The env name is `SCALEKIT_ENVIRONMENT_URL`. Do not prepend `https://`.

## Gotchas

- If the user has no snippet and wants new auth, name the implementing skill and stop.
- SaaSKit login → `implement-saaskit` (Node), `implement-saaskit-nextjs`, or `implement-saaskit-python`.
- AgentKit → `integrate-agentkit`. SCIM → `implement-scim`. SSO → `implement-sso`. Sessions after login → `manage-saaskit-sessions`.
- A one-line corrected call is review. A new auth flow is generation. Do not generate.
- Cookies: `httpOnly`, `secure` in production, `sameSite: 'lax'`. Never `strict`.
- `next` / `returnTo` is a relative path only.
- Client is a module-level singleton.

## Step 1 — Confirm this is a review

Need an existing snippet.

- No snippet, or the user asked to generate login / callback / logout → name `implement-saaskit` (or the sibling for Next.js, Python, AgentKit). Stop.
- Snippet exists → stay.

**Done when:** a snippet is in hand, or the implementing skill is named and this skill has stopped.

## Step 2 — Identify language and product

| Language | Package | Import |
|---|---|---|
| Node.js / TypeScript | `@scalekit-sdk/node` | `import { ScalekitClient } from '@scalekit-sdk/node'` |
| Python | `scalekit-sdk-python` | `from scalekit import ScalekitClient` |
| Go | `scalekit-sdk-go` | `import scalekit "github.com/scalekit-inc/scalekit-sdk-go/v2"` |
| Java | `scalekit-sdk-java` | `import com.scalekit.ScalekitClient;` |

Product: **SaaSKit** (login, sessions, SSO, SCIM, RBAC) or **AgentKit** (connections, tools, MCP auth).

**Done when:** language, package, and product are named.

## Step 3 — SDK correctness

Open [references/REFERENCE.md](references/REFERENCE.md). Then stop reading it.

For every Scalekit call, record pass or fail:

1. Import path matches the table
2. Method name exists for that SDK
3. Parameters match name, order, and type
4. Return shape is handled (Promise, dict, `(result, error)`, checked exception)
5. Client is constructed from `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`

If the snippet is raw HTTP, check the REST section of that same file: path, method, and Bearer token from `POST /oauth/token`.

Open [references/COMMON-MISTAKES.md](references/COMMON-MISTAKES.md) for the wrong → right pairs. Then stop reading it.

**Done when:** every Scalekit call is pass, fail, or "could not be verified".

## Step 4 — Flow and security

Record pass, fail, or waive (not in this snippet) for:

1. Login has a callback
2. Callback compares stored `state` to the query `state` before `authenticateWithCode`
3. Logout calls `getLogoutUrl` with `idTokenHint`
4. Refresh exists if `offline_access` is used
5. Cookies are `httpOnly`, `secure` in production, `sameSite: 'lax'`
6. `state` is cryptographically random
7. `next` is a relative path
8. Secrets come from env vars
9. Webhooks verify the signature on the raw body
10. OAuth redirect uses `window.location.href`, not `router.push`

Do not write the missing route. Name the implementing skill.

**Done when:** every item is pass, fail, or waive.

## Step 5 — Environment

Record pass or fail for:

1. Env name is `SCALEKIT_ENVIRONMENT_URL`, never `SCALEKIT_ENV_URL`
2. No `https://` prepended onto a value that already has a scheme
3. Redirect URI matches the dashboard
4. Domain is `https://<subdomain>.scalekit.com`, `.scalekit.dev`, or `https://app.<domain>` (self-hosted)

**Done when:** all 4 rows have pass or fail.

## Step 6 — Unknown methods

If a call is not in [references/REFERENCE.md](references/REFERENCE.md):

1. Live SDK `REFERENCE.md` at `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-{node,python,go,java}/main/REFERENCE.md`
2. REST API at https://docs.scalekit.com/apis
3. State: "This method could not be verified."

Do not invent a method.

**Done when:** every unknown call is verified or marked unverified.

## Step 7 — Report and stop

For each fail: What's wrong → Why it matters → the correct call from the reference, or the implementing skill name.

If every check passed: say the snippet is right.

Do not write a new login.

**Done when:** the user has the report, and this skill has not written a new auth flow.

## Reach for

- [references/REFERENCE.md](references/REFERENCE.md) for signatures
- [references/COMMON-MISTAKES.md](references/COMMON-MISTAKES.md) for wrong → right pairs
- `implement-saaskit` to write login
- `implement-saaskit-nextjs` for Next.js App Router
- `implement-saaskit-python` for Django, FastAPI, or Flask
- `integrate-agentkit` for a connected account
- `implement-scim` / `implement-sso` / `manage-saaskit-sessions` when that is the gap

## Live lookups

- Docs index: https://docs.scalekit.com/llms.txt
- REST API: https://docs.scalekit.com/apis
- SaaSKit docs: https://docs.scalekit.com/_llms-txt/saaskit-complete.txt
- AgentKit docs: https://docs.scalekit.com/_llms-txt/agentkit.txt
- MCP: https://mcp.scalekit.com
