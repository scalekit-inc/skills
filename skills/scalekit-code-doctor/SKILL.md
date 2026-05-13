---
name: scalekit-code-doctor
description: Use when a user asks to generate, review, validate, or fix any code snippet that uses Scalekit APIs or SDKs. This skill is the single source of truth for Scalekit code correctness — it can generate illustration-quality snippets from scratch (for docs, websites, or integration guides) and review existing code to catch wrong method names, missing parameters, security anti-patterns, and broken auth flows. Covers all four SDKs (Node, Python, Go, Java), raw REST API calls, and both Scalekit product suites — SaaSKit (SSO, login, sessions, RBAC, SCIM) and AgentKit (connections, tool calling, MCP auth). Use when the user says review my Scalekit code, generate a Scalekit example, validate this auth flow, check my SDK usage, fix my Scalekit integration, write a code sample for docs, or anything involving Scalekit code quality.
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

Scalekit has two product suites. Identify which one the user's code belongs to:

**SaaSKit** — Full-stack authentication for B2B SaaS apps
- SSO — Enterprise single sign-on (SAML, OIDC)
- Login & Sessions — Sign-up, login, logout, session management
- RBAC — Roles, permissions, access control
- SCIM — Directory sync and user provisioning
- Admin Portal — Customer-facing admin configuration

**AgentKit** — Authentication and tool access for AI agents
- Connections — OAuth token vault for third-party services (connected accounts)
- Tool Calling — Execute tools via connected accounts
- MCP Authentication — OAuth 2.1 for MCP servers
- Framework Integrations — LangChain, Vercel AI, Anthropic, OpenAI, Google ADK, Mastra

**Cross-product**
- Webhooks — Event subscriptions and payload verification
- M2M Auth — API keys and client credentials

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

**SaaSKit — Login, SSO, and sessions**
1. Client initialization (singleton pattern)
2. Login route: generate auth URL with `state` for CSRF
3. Callback route: validate `state`, exchange code, store session
4. Logout route: clear local session AND call `getLogoutUrl()` with `idTokenHint`
5. Token refresh (if `offline_access` scope is used)

**SaaSKit — SCIM provisioning**
1. Enable directory for an organization
2. List directory users and groups
3. Webhook handler for SCIM events

**AgentKit — Connections and tool calling**
1. Client initialization
2. Create/list connected accounts
3. Execute tools with connected account credentials
4. Handle token refresh for third-party OAuth tokens

**AgentKit — MCP Authentication**
1. MCP server setup with OAuth middleware
2. Token validation on incoming requests
3. Scope verification

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

## Step 5 — Handling SDK updates and unknown methods

The `references/REFERENCE.md` in this skill is a **point-in-time snapshot**. Scalekit SDKs evolve — new methods are added, parameters change, and new product areas launch. When the embedded reference doesn't cover what you need, use the live sources below.

### When to check live sources

- A method the user wrote isn't in the embedded reference (could be newly added, not a typo)
- The user asks about a feature you don't recognize (e.g., a new connector, a new auth mode)
- You're generating code for a product area with sparse coverage in the reference
- The user explicitly mentions a recent SDK update or version

### How to check: fetch the live SDK REFERENCE.md files

Each SDK repo has a maintained `REFERENCE.md` with full, current method signatures. Fetch the one you need:

| SDK | Live reference URL |
|-----|-------------------|
| Node.js | `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-node/main/REFERENCE.md` |
| Python | `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-python/main/REFERENCE.md` |
| Go | `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-go/main/REFERENCE.md` |
| Java | `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-java/main/REFERENCE.md` |
| REST API | `https://docs.scalekit.com/apis.md` |

### Resolution order

1. Check the embedded `references/REFERENCE.md` first (fastest, no network)
2. If the method isn't there, fetch the live SDK REFERENCE.md from the table above
3. If still not found, fetch `https://docs.scalekit.com/apis.md` for REST endpoints
4. If still not found, state explicitly: "This method could not be verified in any Scalekit reference. It may not exist."

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

### Live SDK references (always current — fetch when embedded reference is stale)

| SDK | REFERENCE.md (raw) | Repo |
|-----|--------------------|----|
| Node.js | `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-node/main/REFERENCE.md` | [scalekit-sdk-node](https://github.com/scalekit-inc/scalekit-sdk-node) |
| Python | `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-python/main/REFERENCE.md` | [scalekit-sdk-python](https://github.com/scalekit-inc/scalekit-sdk-python) |
| Go | `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-go/main/REFERENCE.md` | [scalekit-sdk-go](https://github.com/scalekit-inc/scalekit-sdk-go) |
| Java | `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-java/main/REFERENCE.md` | [scalekit-sdk-java](https://github.com/scalekit-inc/scalekit-sdk-java) |

### Scalekit docs

| Resource | URL | When to use |
|----------|-----|-------------|
| REST API reference | `https://docs.scalekit.com/apis.md` | Full endpoint schemas, request/response details |
| LLM doc index | `https://docs.scalekit.com/llms.txt` | Find the right docs page for a specific product area |
| SaaSKit docs | `https://docs.scalekit.com/_llms-txt/saaskit-complete.txt` | Full SaaSKit reference (users, orgs, sessions, RBAC, SSO, SCIM) |
| AgentKit docs | `https://docs.scalekit.com/_llms-txt/agentkit.txt` | Full AgentKit reference (agents, OAuth vault, tool calling, connectors) |
| AgentKit frameworks | `https://docs.scalekit.com/_llms-txt/agentkit-frameworks.txt` | Framework-specific guides (LangChain, Vercel AI, Anthropic, OpenAI, Google ADK, Mastra) |
| MCP Authentication docs | `https://docs.scalekit.com/_llms-txt/mcp-authentication.txt` | MCP server OAuth 2.1, Dynamic Client Registration |

### GitHub repos — working examples

When generating or reviewing framework-specific code, fetch the matching repo for real, tested patterns. Repos are from `scalekit-inc` and `scalekit-developers` GitHub orgs.

**SaaSKit — Auth examples by framework**

| Framework | Repo | What it shows |
|-----------|------|---------------|
| Next.js (App Router) | [scalekit-nextjs-auth-example](https://github.com/scalekit-inc/scalekit-nextjs-auth-example) | SSO, sessions, protected routes, TypeScript |
| Next.js (Pages) | [nextjs-example-apps](https://github.com/scalekit-inc/nextjs-example-apps) | React SSO integration flows |
| Next.js + Auth.js | [scalekit-authjs-example](https://github.com/scalekit-developers/scalekit-authjs-example) | Enterprise SSO with next-auth v5 |
| Express.js | [scalekit-express-auth-example](https://github.com/scalekit-inc/scalekit-express-auth-example) | Node SDK, EJS frontend, sessions |
| Express.js | [scalekit-express-example](https://github.com/scalekit-developers/scalekit-express-example) | SSO with session management, middleware |
| FastAPI | [scalekit-fastapi-auth-example](https://github.com/scalekit-inc/scalekit-fastapi-auth-example) | Python SDK, OAuth 2.0, protected routes |
| FastAPI | [scalekit-fastapi-example](https://github.com/scalekit-developers/scalekit-fastapi-example) | Async auth, Pydantic models |
| Django | [scalekit-django-auth-example](https://github.com/scalekit-inc/scalekit-django-auth-example) | Python SDK, Django auth integration |
| Flask | [scalekit-flask-auth-example](https://github.com/scalekit-inc/scalekit-flask-auth-example) | Python SDK, Flask sessions |
| Spring Boot | [scalekit-springboot-auth-example](https://github.com/scalekit-inc/scalekit-springboot-auth-example) | Java, Spring Security, OIDC |
| Spring Boot | [scalekit-springboot-example](https://github.com/scalekit-developers/scalekit-springboot-example) | Java SDK, enterprise SSO |
| Go (Gin) | [scalekit-go-example](https://github.com/scalekit-developers/scalekit-go-example) | Go SDK, Gin framework, SSO |
| Laravel | [scalekit-laravel-auth-example](https://github.com/scalekit-inc/scalekit-laravel-auth-example) | REST API calls, Laravel HTTPS |
| Astro | [astro-scalekit-auth-example](https://github.com/scalekit-developers/astro-scalekit-auth-example) | Auth, SSO, social login, protected routes |
| .NET | [dotnet-example-apps](https://github.com/scalekit-inc/dotnet-example-apps) | ASP.NET Core, SAML/OIDC |
| Expo (mobile) | [expo-scalekit-sample](https://github.com/scalekit-inc/expo-scalekit-sample) | OAuth 2.0 + PKCE for mobile |

**SaaSKit — Integration examples**

| Integration | Repo | What it shows |
|-------------|------|---------------|
| AWS Cognito | [scalekit-cognito-sso](https://github.com/scalekit-inc/scalekit-cognito-sso) | OIDC SSO with Cognito user pools |
| Firebase | [scalekit-firebase-sso](https://github.com/scalekit-inc/scalekit-firebase-sso) | SAML/OIDC SSO with Firebase Auth |
| Supabase | [scalekit-supabase-example](https://github.com/scalekit-inc/scalekit-supabase-example) | Supabase + Scalekit auth |
| Multi-app SSO | [multiapp-demo](https://github.com/scalekit-inc/multiapp-demo) | Seamless SSO across multiple apps |
| Org switcher | [Nextjs-Django-Org-Switcher-Example](https://github.com/scalekit-inc/Nextjs-Django-Org-Switcher-Example) | Next.js frontend + Django backend, org switching |
| OIDC/SAML/SCIM | [oidc-saml-scim-examples](https://github.com/scalekit-developers/oidc-saml-scim-examples) | Google, Okta integration patterns |
| Passwordless | [passwordless-auth-demos](https://github.com/scalekit-developers/passwordless-auth-demos) | Passwordless authentication flows |
| Managed login | [managed-loginbox-expressjs-demo](https://github.com/scalekit-developers/managed-loginbox-expressjs-demo) | Hosted login UI with Express |
| Full demo app | [coffee-desk-demo](https://github.com/scalekit-inc/coffee-desk-demo) | Workspace creation, user provisioning, RBAC, SSO |

**AgentKit — Agent and MCP examples**

| Framework / Pattern | Repo | What it shows |
|---------------------|------|---------------|
| LangChain | [sample-langchain-agent](https://github.com/scalekit-inc/sample-langchain-agent) | Python LangChain agent with Scalekit auth |
| Google ADK | [google-adk-agent-example](https://github.com/scalekit-inc/google-adk-agent-example) | Google ADK agent with authenticated tools |
| Vercel AI SDK | [vercel-ai-agent-toolkit](https://github.com/scalekit-developers/vercel-ai-agent-toolkit) | Vercel AI SDK + Scalekit connectors |
| Apify Actor | [agentkit-apify-actor-example](https://github.com/scalekit-developers/agentkit-apify-actor-example) | OAuth auth, YouTube → Notion agent |
| LiteLLM | [litellm-agentkit-inbox-triage](https://github.com/scalekit-developers/litellm-agentkit-inbox-triage) | Inbox triage with Gmail, GitHub, Slack |
| MCP Auth (multi-framework) | [mcp-auth-demos](https://github.com/scalekit-inc/mcp-auth-demos) | MCP OAuth 2.1 demos |
| MCP + FastMCP | [fastmcp-scalekit-example](https://github.com/scalekit-inc/fastmcp-scalekit-example) | FastMCP server with Scalekit auth |
| MCP + BYOA | [byoa-demo-mcp](https://github.com/scalekit-inc/byoa-demo-mcp) | Bring your own auth + MCP |
| MCP + Coffee Desk | [coffee-desk-mcp](https://github.com/scalekit-inc/coffee-desk-mcp) | Demo MCP server with roles/permissions |
| Python connections | [python-connect-demos](https://github.com/scalekit-inc/python-connect-demos) | Python connection and identity workflows |
| Agent auth examples | [agent-auth-examples](https://github.com/scalekit-developers/agent-auth-examples) | Official AgentKit examples collection |
| Node.js agents | [agent-node-demos](https://github.com/scalekit-inc/agent-node-demos) | TypeScript agent demos |
| Workflow agents | [workflow-agents-demos](https://github.com/scalekit-developers/workflow-agents-demos) | Multi-step agent workflows |
| Render deploy kit | [render-ai-agent-deploykit](https://github.com/scalekit-developers/render-ai-agent-deploykit) | Render Workflows + Scalekit + Claude |

**Developer tools**

| Tool | Repo | Purpose |
|------|------|---------|
| Dryrun CLI | [scalekit-dryrun](https://github.com/scalekit-inc/scalekit-dryrun) | Test auth flows without writing code |
| Scalekit MCP server | [scalekit-mcp-server](https://github.com/scalekit-inc/scalekit-mcp-server) | Manage orgs, users, connections via AI assistants |
| API collections | [api-collections](https://github.com/scalekit-inc/api-collections) | Postman/Bruno collections for Scalekit endpoints |
| Documentation source | [developer-docs](https://github.com/scalekit-inc/developer-docs) | Docs site source (MDX) |

**Frontend SDKs**

| SDK | Repo | Purpose |
|-----|------|---------|
| React SDK | [scalekit-react-sdk](https://github.com/scalekit-inc/scalekit-react-sdk) | React OIDC authentication |
| Vue SDK | [scalekit-vue-sdk](https://github.com/scalekit-inc/scalekit-vue-sdk) | Vue OIDC authentication |
| Expo SDK | [scalekit-expo-sdk](https://github.com/scalekit-inc/scalekit-expo-sdk) | Expo/React Native OAuth 2.0 + PKCE |

When generating code for a specific framework, fetch the matching repo's source to see real, tested patterns before writing. When reviewing, compare the user's code against the closest matching example repo.