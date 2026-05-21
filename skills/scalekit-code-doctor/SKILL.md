---
name: scalekit-code-doctor
description: Use when a user asks to generate, review, validate, or fix any code snippet that uses Scalekit APIs or SDKs. Generates illustration-quality snippets and reviews existing code to catch wrong method names, missing parameters, security anti-patterns, and broken auth flows. Covers all four SDKs (Node, Python, Go, Java), raw REST API calls, and both product suites — SaaSKit (SSO, login, sessions, RBAC, SCIM) and AgentKit (connections, tool calling, MCP auth). Use when the user says review my Scalekit code, generate a Scalekit example, validate this auth flow, check my SDK usage, fix my Scalekit integration, or write a code sample for docs.
---

# Scalekit Code Doctor

**Before doing anything else**, read the reference files:
- `references/REFERENCE.md` — Every correct SDK method signature and REST endpoint
- `references/COMMON-MISTAKES.md` — Known anti-patterns with wrong → right corrections
- `references/EXAMPLE-REPOS.md` — GitHub repos with working examples by framework

Never hallucinate a method name, parameter, or import — if it's not in the reference, verify against live sources before using it.

## Step 1 — Detect mode

**Generate mode** — User describes what they want but has no code yet.
**Review mode** — User provides existing code for validation.

If unclear, ask: "Do you want me to generate a fresh code example, or review existing code?"

## Step 2 — Identify context

| Language | Package | Import |
|----------|---------|--------|
| Node.js / TypeScript | `@scalekit-sdk/node` | `import { ScalekitClient } from '@scalekit-sdk/node'` |
| Python | `scalekit-sdk-python` | `from scalekit import ScalekitClient` |
| Go | `scalekit-sdk-go` | `import scalekit "github.com/scalekit-inc/scalekit-sdk-go/v2"` |
| Java | `scalekit-sdk-java` | `import com.scalekit.ScalekitClient;` |

Product area: **SaaSKit** (SSO, login, sessions, RBAC, SCIM) or **AgentKit** (connections, tool calling, MCP auth).

## Step 3 — Generate mode

Output should be illustration-ready: self-contained, essential path only, correct imports, framework-idiomatic, 1–2 pages max.

**Correct SaaSKit login+callback example (Node.js/Express):**

```typescript
import { ScalekitClient } from '@scalekit-sdk/node';
import crypto from 'crypto';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENV_URL!,
  process.env.SCALEKIT_CLIENT_ID!,
  process.env.SCALEKIT_CLIENT_SECRET!
);

const REDIRECT_URI = 'https://yourapp.com/auth/callback';

// Login — generate auth URL with CSRF state
app.get('/auth/login', (req, res) => {
  const state = crypto.randomBytes(32).toString('base64url');
  res.cookie('oauth_state', state, { httpOnly: true, sameSite: 'lax', secure: true });
  const authUrl = scalekit.getAuthorizationUrl(REDIRECT_URI, { state });
  res.redirect(authUrl);
});

// Callback — validate state, exchange code, store session
app.get('/auth/callback', async (req, res) => {
  const { code, state } = req.query;
  if (state !== req.cookies.oauth_state) return res.status(403).send('CSRF mismatch');

  const result = await scalekit.authenticateWithCode(code as string, REDIRECT_URI);
  req.session.user = { id: result.user.id, email: result.user.email };
  req.session.idToken = result.idToken;
  res.redirect('/dashboard');
});

// Logout — clear local + end IdP session
app.post('/auth/logout', (req, res) => {
  const logoutUrl = scalekit.getLogoutUrl({
    idTokenHint: req.session.idToken,
    postLogoutRedirectUri: 'https://yourapp.com',
  });
  req.session.destroy(() => res.redirect(logoutUrl));
});
```

**Mandatory checks before outputting generated code** — cross-reference every SDK call against `references/REFERENCE.md`:
- [ ] Method names exist for the target SDK
- [ ] Parameters match in name, order, and type
- [ ] Import path is exactly correct
- [ ] Environment variable names follow Scalekit conventions

## Step 4 — Review mode

Check these categories in order:

**1. SDK correctness** — Every method name, parameter, import, and return type matches `references/REFERENCE.md`.

**2. Auth flow completeness** — Login has a callback. Callback validates `state`. Logout calls `getLogoutUrl()`. Token refresh exists if `offline_access` is used. IdP-initiated login handled if applicable.

**3. Security** — Cookies: `httpOnly`, `secure`, `sameSite: 'lax'`. State: cryptographically random. Redirects: only relative paths. Secrets: from env vars. Webhooks: signature verified before processing.

**4. Environment** — `SCALEKIT_ENV_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`. Redirect URI matches dashboard. Domain format: `https://<subdomain>.scalekit.com`.

**5. Best practices** — Client is singleton. Error handling uses typed exceptions. `window.location.href` for OAuth redirects (not `router.push`).

**Output for each finding:** What's wrong → Why it matters → Corrected code.

## Step 5 — Unknown methods

Resolution order when a method isn't in `references/REFERENCE.md`:

| Priority | Source |
|----------|--------|
| 1 | Embedded `references/REFERENCE.md` |
| 2 | Live SDK reference: `https://raw.githubusercontent.com/scalekit-inc/scalekit-sdk-{node,python,go,java}/main/REFERENCE.md` |
| 3 | REST API: `https://docs.scalekit.com/apis.md` |
| 4 | State explicitly: "This method could not be verified." |

Never output code containing an unverified method call.

## Documentation

| Resource | URL |
|----------|-----|
| REST API reference | `https://docs.scalekit.com/apis.md` |
| LLM doc index | `https://docs.scalekit.com/llms.txt` |
| SaaSKit docs | `https://docs.scalekit.com/_llms-txt/saaskit-complete.txt` |
| AgentKit docs | `https://docs.scalekit.com/_llms-txt/agentkit.txt` |
| MCP Auth docs | `https://docs.scalekit.com/_llms-txt/mcp-authentication.txt` |

For framework-specific example repos, see `references/EXAMPLE-REPOS.md`.