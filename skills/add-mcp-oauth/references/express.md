# Express extras

Stay on `SKILL.md` for the default path. Use this file for CORS, a health route, Zod tools, or a 403 scope check.

Install only what this file imports and the repo is missing:

```bash
npm install cors zod
```

`@scalekit-sdk/node`, `@modelcontextprotocol/sdk`, and `express` are already on the default path.

## Middleware order

CORS → `express.json()` → well-known + health → Bearer middleware → MCP `POST`. Always `return` after a 401.

`EXPECTED_AUDIENCE` must match the dashboard Server URL exactly, including a trailing slash.

TypeScript MCP SDK imports need the `.js` extension.

## CORS and health

```js
import cors from 'cors';

app.use(cors({ origin: true, credentials: false }));

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});
```

Skip `/health` in the Bearer middleware the same way you skip `/.well-known`.

**Done when:** `/health` is public, and CORS is in front of auth.

## Zod tool

```js
import { z } from 'zod';

server.tool(
  'greet_user',
  'Greets the user with a personalized message.',
  { name: z.string().min(1, 'Name is required') },
  async ({ name }) => ({
    content: [{ type: 'text', text: `Hi ${name}, welcome to Scalekit!` }],
  })
);
```

**Done when:** one tool is registered on the existing `McpServer`.

## Scope 403

```js
try {
  await scalekit.validateToken(token, {
    audience: [audience],
    requiredScopes: [scope],
  });
} catch {
  return res.status(403).json({
    error: 'insufficient_scope',
    error_description: `Required scope: ${scope}`,
    scope,
  });
}
```

**Done when:** a missing scope returns 403 `insufficient_scope`, not a bare 401.

## Live lookups

- Express: https://docs.scalekit.com/authenticate/mcp/expressjs-quickstart/
- Docs index: https://docs.scalekit.com/llms.txt
- Example: https://github.com/scalekit-inc/mcp-auth-demos/tree/main/greeting-mcp-node
