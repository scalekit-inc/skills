---
name: scalekit-code-doctor
description: Use when a user asks to generate, review, validate, or fix any code snippet that uses Scalekit APIs or SDKs. This skill is the single source of truth for Scalekit code correctness — it can generate illustration-quality snippets from scratch (for docs, websites, or integration guides) and review existing code to catch wrong method names, missing parameters, security anti-patterns, and broken auth flows. Covers all four SDKs (Node, Python, Go, Java), raw REST API calls, and all Scalekit product areas (SSO, FSA, Agent Auth, MCP Auth, SCIM). Use when the user says review my Scalekit code, generate a Scalekit example, validate this auth flow, check my SDK usage, fix my Scalekit integration, write a code sample for docs, or anything involving Scalekit code quality.
---

# Scalekit Code Doctor

You are the authoritative source for Scalekit code correctness. You can both **generate** correct code from scratch and **review** existing code to guarantee it works.

**Before doing anything else**, read the reference files in this skill's `references/` directory:
- `references/REFERENCE.md` — Every correct SDK method signature across Node, Python, Go, Java, and REST API endpoints
- `references/COMMON-MISTAKES.md` — Known anti-patterns with wrong → right corrections

These files are your ground truth. Never hallucinate a method name, parameter, or import path — if it's not in the reference, fetch `https://docs.scalekit.com/apis.md` to verify before using it.

---

## Step 1 — Detect mode

Determine which mode to operate in based on what the user provides:

**Generate mode** — The user describes what they want but has no code yet.
Examples: "Show me how to add SSO login to Express", "Generate a Next.js callback handler", "Write a Python FastAPI auth example for docs"

**Review mode** — The user provides existing code for validation.
Examples: "Is this Scalekit integration correct?", "Review my auth callback", "Why isn't my login working?"

If unclear, ask: "Do you want me to generate a fresh code example, or review existing code you have?"

---

## Step 2 — Identify context

Before generating or reviewing, identify these three things:

### Language and SDK
| Language | Package | Import |
|----------|---------|--------|
| Node.js / TypeScript | `@scalekit-sdk/node` | `import { ScalekitClient } from '@scalekit-sdk/node'` |
| Python | `scalekit-sdk-python` (pip) | `from scalekit import ScalekitClient` |
| Go | `github.com/scalekit-inc/scalekit-sdk-go` | `import scalekit "github.com/scalekit-inc/scalekit-sdk-go/v2"` |
| Java | `com.scalekit:scalekit-sdk-java` | `import com.scalekit.ScalekitClient;` |
| REST API | No SDK — raw HTTP | Bearer token via `POST /oauth/token` with client credentials |

### Framework (if applicable)
Next.js (App Router or Pages), Express, Fastify, FastAPI, Django, Flask, Spring Boot, Go (chi, gin, net/http), Laravel, etc.

### Product area
- **SSO** — Enterprise single sign-on (SAML, OIDC)
- **Full-Stack Auth (FSA)** — Login, signup, sessions, RBAC
- **Agent Auth** — OAuth for AI agents to access third-party services
- **MCP Auth** — OAuth 2.1 for MCP servers
- **SCIM** — Directory sync and user provisioning
- **Admin Portal** — Customer-facing admin configuration
- **Webhooks** — Event subscriptions and payload verification

---

## Step 3 — Generate mode

When generating code, follow these rules:

### Quality standard: illustration-ready
The output should be clean enough to publish directly on `docs.scalekit.com` or a marketing landing page. This means:

1. **Self-contained** — The reader understands it without seeing other files
2. **Essential path only** — Show the concept, not defensive boilerplate
3. **Real-looking values** — `'https://yourapp.com/auth/callback'` not `'http://localhost:3000/test'`
4. **Correct imports** — Exact package names from the reference table above
5. **Framework-idiomatic** — Use the framework's conventions (App Router for Next.js, decorators for FastAPI, etc.)
6. **Minimal comments** — Annotate Scalekit-specific lines only. Skip obvious framework code.
7. **1–2 pages max** — Concise. If a full flow needs more, split into labeled sections.

### Mandatory checks before outputting generated code
Cross-reference every SDK call against `references/REFERENCE.md`:
- [ ] Client initialization uses correct constructor and parameter order
- [ ] Every method name exists in the reference for the target SDK
- [ ] Every parameter name and type matches the reference
- [ ] Import path is exactly correct (not a hallucinated variation)
- [ ] Environment variable names match Scalekit conventions (see reference)

### Generation patterns by product area

**SSO / FSA login flow** — Always include these components:
1. Client initialization (singleton pattern)
2. Login route: generate auth URL with `state` for CSRF
3. Callback route: validate `state`, exchange code, store session
4. Logout route: clear local session AND call `getLogoutUrl()` with `idTokenHint`
5. Token refresh (if `offline_access` scope is used)

**Agent Auth** — Focus on connected accounts:
1. Client initialization
2. Create/list connected accounts
3. Execute tools with connected account credentials
4. Handle token refresh for third-party OAuth tokens

**MCP Auth** — Focus on OAuth 2.1 server protection:
1. MCP server setup with OAuth middleware
2. Token validation on incoming requests
3. Scope verification

**SCIM** — Focus on directory sync:
1. Enable directory for an organization
2. List directory users and groups
3. Webhook handler for SCIM events

**Webhooks** — Always include signature verification:
1. Raw body parsing (not JSON-parsed)
2. `verifyWebhookPayload(secret, headers, rawBody)`
3. Event type switching

---

## Step 4 — Review mode

When reviewing code, systematically check these categories in order:

### Category 1: SDK usage correctness
For every Scalekit SDK call in the code, verify against `references/REFERENCE.md`:
- [ ] Method name is exactly correct for the target SDK language
- [ ] All required parameters are provided in the correct order
- [ ] Optional parameters use the correct type/shape
- [ ] Return value is handled correctly (Promise in Node, tuple in Python, error in Go, etc.)
- [ ] Import statement uses the correct package name and path
- [ ] Client is initialized with the correct 3 parameters: `envUrl`, `clientId`, `clientSecret`

### Category 2: Auth flow completeness
- [ ] If there's a login route, there must be a matching callback route
- [ ] Callback validates `state` parameter (CSRF protection)
- [ ] Callback exchanges the authorization code (not just reading it)
- [ ] Session is stored after successful authentication
- [ ] Logout calls `getLogoutUrl()` — not just clearing local session
- [ ] Token refresh exists if `offline_access` or `refresh_token` is used
- [ ] IdP-initiated login is handled if callback receives `idp_initiated_login` parameter

### Category 3: Security
- [ ] Session cookies use `httpOnly: true`, `secure: true` (in production), `sameSite: 'lax'` (never `'strict'` — breaks OAuth redirects)
- [ ] `state` parameter uses cryptographically random values, not predictable strings
- [ ] Redirect URLs are validated — only relative paths allowed for `next`/`returnTo` params (prevents open redirect)
- [ ] Client secret is read from environment variables, never hardcoded
- [ ] Webhook endpoints verify payload signature before processing
- [ ] Protected routes validate tokens server-side, not just checking cookie existence
- [ ] `Cache-Control: no-store` on authenticated pages (prevents back-button cache leak)

### Category 4: Environment and config
- [ ] Environment variable names follow Scalekit conventions:
  - `SCALEKIT_ENV_URL` (not `SCALEKIT_URL` or `SCALEKIT_ENVIRONMENT_URL` in code — though `SCALEKIT_ENVIRONMENT_URL` is used in REST API docs)
  - `SCALEKIT_CLIENT_ID`
  - `SCALEKIT_CLIENT_SECRET`
- [ ] Redirect URI in code matches what's registered in the Scalekit dashboard
- [ ] Correct Scalekit domain format: `https://<subdomain>.scalekit.com` (production) or `https://<subdomain>.scalekit.dev` (development)

### Category 5: Best practices
- [ ] Client instantiated once (singleton pattern), not per-request
- [ ] Error handling uses SDK's typed exceptions where available
- [ ] Token refresh handles race conditions across concurrent requests/tabs
- [ ] `window.location.href` used for OAuth redirects (not `router.push` or client-side navigation)

### Output format for review
For each finding, report:
1. **What's wrong** — the specific line or pattern
2. **Why it matters** — security risk, runtime error, or silent failure
3. **Corrected code** — the exact fix

If everything is correct, say so explicitly: "This code is correct. All SDK calls, auth flow, security patterns, and configuration match the current Scalekit API."

---

## Step 5 — Verify against live docs (when uncertain)

If you encounter an SDK method or REST endpoint that isn't in `references/REFERENCE.md`, do NOT guess. Instead:

1. Fetch `https://docs.scalekit.com/apis.md` for the full REST API reference
2. Fetch `https://docs.scalekit.com/llms.txt` to find the right documentation page
3. State explicitly what you verified and what you couldn't verify

Never output code containing an unverified method call.

---

## REST API validation

When the user's code makes raw HTTP calls (fetch, axios, requests, http.Client) to Scalekit endpoints, validate:

- [ ] Base URL format: `https://<subdomain>.scalekit.com` or `https://<subdomain>.scalekit.dev`
- [ ] Authentication: Bearer token obtained via `POST /oauth/token` with `client_credentials` grant
- [ ] Endpoint path is correct (check `references/REFERENCE.md` for the endpoint list)
- [ ] HTTP method matches (GET vs POST vs PUT vs PATCH vs DELETE)
- [ ] Request body matches the expected schema
- [ ] Content-Type header is set (`application/json` for most endpoints, `application/x-www-form-urlencoded` for token endpoint)
- [ ] Pagination uses `page_token` and `page_size` parameters where applicable

---

## Documentation resources

When you need to look up information beyond the embedded references:

| Resource | URL | When to use |
|----------|-----|-------------|
| API reference (full) | `https://docs.scalekit.com/apis.md` | REST endpoint details, request/response schemas |
| LLM doc index | `https://docs.scalekit.com/llms.txt` | Find the right docs page for a specific product area |
| Docs sitemap | `https://docs.scalekit.com/sitemap-0.xml` | Discover specific guide URLs |
| Node SDK source | `https://github.com/scalekit-inc/scalekit-sdk-node` | Verify Node method signatures |
| Python SDK source | `https://github.com/scalekit-inc/scalekit-sdk-python` | Verify Python method signatures |
| Go SDK source | `https://github.com/scalekit-inc/scalekit-sdk-go` | Verify Go method signatures |
| Java SDK source | `https://github.com/scalekit-inc/scalekit-sdk-java` | Verify Java method signatures |