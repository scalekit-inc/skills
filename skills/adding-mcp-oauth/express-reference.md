# Express.js MCP Server Reference

## Choose a mode
Ask: "Are we scaffolding a brand-new MCP server repo, or adding MCP auth into an existing Express app?"
- Mode A: New project scaffold (recommended for demos/POCs)
- Mode B: Retrofit existing Express app (recommended for real products)

## Inputs to collect (ask if missing)
- Server base URL and port; confirm whether trailing slash is required for the audience (example: http://localhost:3002/)
- SK_ENV_URL, SK_CLIENT_ID, SK_CLIENT_SECRET
- PROTECTED_RESOURCE_METADATA JSON (copied from Scalekit dashboard MCP server page)
- EXPECTED_AUDIENCE (must match the Server URL registered in Scalekit)

## Required outcomes
1) Public discovery endpoint: GET /.well-known/oauth-protected-resource (returns PROTECTED_RESOURCE_METADATA as JSON)
2) Public health endpoint: GET /health
3) Auth middleware: validates Authorization: Bearer <token>, returns 401 + WWW-Authenticate with resource_metadata URL on failure
4) MCP endpoint: POST / protected by middleware, handled via MCP SDK StreamableHTTPServerTransport
5) At least one tool registered with server.tool(...)

---

# Mode A — Scaffold a new project

## Steps
1) Create a folder and initialize dependencies using templates in:
- assets/express/new-project/package.json
- assets/express/new-project/tsconfig.json
- assets/express/new-project/src/server.ts

2) Create .env using assets/express/env.example (fill real values).

3) Run:
- npm install
- npm run dev

## Notes
- Ensure EXPECTED_AUDIENCE exactly matches the Scalekit "Server URL" (including trailing slash if used).
- Keep /.well-known/oauth-protected-resource public; MCP clients need it for discovery.

---

# Mode B — Retrofit an existing Express app

## Identify insertion points
Ask for:
- Existing server entrypoint file (e.g., src/index.ts or src/server.ts)
- Current app router structure and whether POST / is already used
- Existing auth middlewares and CORS settings

## Patch plan (minimal diffs)
1) Add env vars (SK_*, EXPECTED_AUDIENCE, PROTECTED_RESOURCE_METADATA).
2) Add routes:
- GET /.well-known/oauth-protected-resource (public)
- GET /health (public)
3) Add auth middleware (public-path exemptions + Bearer extraction + validateToken with audience).
4) Add MCP server + route:
- Create McpServer + tools (assets/express/retrofit/mcp-server.ts)
- Add POST handler (assets/express/retrofit/mcp-route.ts)
5) Route mounting:
- If POST / is free, mount MCP at /
- If POST / is used, mount MCP at /mcp and update RESOURCE_METADATA_URL accordingly (and ensure clients point to correct MCP URL)

## Templates
- Auth middleware: assets/express/retrofit/auth-middleware.ts
- Well-known route: assets/express/retrofit/well-known-route.ts
- MCP server + tool registration: assets/express/retrofit/mcp-server.ts
- MCP POST handler: assets/express/retrofit/mcp-route.ts

---

## Verification checklist
- GET /.well-known/oauth-protected-resource works without Authorization header
- POST MCP endpoint without token -> 401 + WWW-Authenticate (resource_metadata points to the well-known URL)
- Valid token with correct audience -> MCP tool call succeeds
- Wrong-audience token -> 401

See the troubleshooting section below for common misconfigurations.

---

# Express.js MCP OAuth Reference

## Core Concepts

### OAuth 2.1 Flow for MCP
The MCP specification defines a discovery-driven OAuth flow:
1. MCP client fetches `/.well-known/oauth-protected-resource` to find the authorization server
2. MCP client initiates OAuth flow with the authorization server
3. User authenticates and authorizes the client
4. Authorization server issues an access token with `aud` claim containing the resource identifier
5. MCP client includes the token in `Authorization: Bearer <token>` header
6. Resource server validates the token's `aud`, `iss`, `exp`, and `scope` claims
7. If valid, the tool executes; otherwise, returns 401/403 with appropriate error details

### Streamable HTTP Transport
Unlike stdio transport, HTTP transport:
- Exposes endpoints for MCP protocol over HTTP
- Uses SSE (Server-Sent Events) for server-to-client messages
- Uses POST requests for client-to-server messages
- Supports authentication headers
- Required for OAuth 2.1 flows

### WWW-Authenticate Header
This header is critical for MCP clients to discover the auth flow:
```
WWW-Authenticate: Bearer realm="OAuth", resource_metadata="https://your-server/.well-known/oauth-protected-resource"
```
Without this header, clients fail silently because they don't know how to authenticate.

## Scalekit Integration

### Resource Registration
When registering your MCP server in Scalekit:
1. Enable "Dynamic Client Registration" (DCR) for public clients like Claude/Cursor
2. Enable "Client ID Metadata Document" (CIMD) for automatic client metadata
3. Set "Server URL" to your MCP server's base URL (becomes the expected `aud` value)
4. Configure scopes as `resource:action` patterns (e.g., `todo:read`, `todo:write`)
5. Set access token lifetime (300-3600 seconds recommended)

### Token Validation
The Scalekit SDK validates tokens by:
1. Verifying the signature using the authorization server's public keys
2. Checking `aud` claim includes your resource identifier
3. Checking `iss` claim matches the authorization server URL
4. Checking `exp` claim (token hasn't expired)
5. Checking `nbf` claim (token is not before time)
6. Optionally checking `scope` claim for required permissions

## Architecture

### Express Server Structure
```
Express App
├── Public Routes
│   ├── GET /.well-known/oauth-protected-resource (discovery)
│   └── GET /health (health check)
├── Auth Middleware
│   ├── Public path exemptions
│   ├── Bearer token extraction
│   └── Scalekit token validation
└── Protected Routes
    └── POST / (MCP endpoint)
```

### MCP Server Integration
The `StreamableHTTPServerTransport` handles:
- SSE connection establishment for server-initiated messages
- JSON-RPC request/response parsing
- Tool call dispatching to registered tools
- Error formatting according to MCP spec

## Security Considerations

### Audience Validation
Always validate the `aud` claim matches your expected audience:
- Prevents token reuse across different resources
- Ensures tokens are used for their intended resource
- Configure in Scalekit dashboard as "Server URL"

### Scope-Based Authorization
Define and enforce scopes per tool:
- Read operations: `<resource>:read`
- Write operations: `<resource>:write`
- Admin operations: `<resource>:admin`
- Validate both in middleware and at tool execution

### Error Responses
Return OAuth-compliant errors:
- 401: Missing or invalid token
- 403: Insufficient scope
- Always include `WWW-Authenticate` header on 401
- Use standard error codes: `invalid_token`, `insufficient_scope`

### CORS Configuration
Allow necessary origins:
- MCP client domains (Claude, Cursor, VS Code)
- Include `Authorization` header in allowed headers
- Handle preflight OPTIONS requests

---

# Troubleshooting Express.js MCP OAuth

## Common Issues

### MCP Client Fails Silently
**Symptom**: Claude Desktop, Cursor, or VS Code shows connection error without helpful message.

**Cause**: Missing or incorrect `WWW-Authenticate` header on 401 response.

**Solution**:
```typescript
// Ensure your 401 response includes WWW-Authenticate
res
  .status(401)
  .set('WWW-Authenticate', `Bearer realm="OAuth", resource_metadata="${METADATA_URL}"`)
  .end();
```

**Verify**:
```bash
curl -i -X POST http://localhost:3002/ -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```
Check for `WWW-Authenticate` in response headers.

### Token Validation Always Fails
**Symptom**: All requests return 401 even with valid tokens.

**Cause 1**: Audience mismatch
- Your `EXPECTED_AUDIENCE` doesn't match the "Server URL" in Scalekit dashboard.

**Solution**:
1. Copy Server URL from Scalekit dashboard (including trailing slash if present)
2. Set `EXPECTED_AUDIENCE` in .env exactly as shown
3. Restart server

**Cause 2**: Token extraction fails
- Authorization header missing or malformed.

**Solution**:
```typescript
const authHeader = req.headers['authorization'];
const token = authHeader?.startsWith('Bearer ')
  ? authHeader.split('Bearer ')[1]?.trim()
  : null;
```

### Discovery Endpoint Not Found
**Symptom**: `curl http://localhost:3002/.well-known/oauth-protected-resource` returns 404.

**Cause**: Route not defined or defined with wrong path.

**Solution**:
```typescript
// Must be exactly this path
app.get('/.well-known/oauth-protected-resource', (req, res) => {
  res.json(JSON.parse(process.env.PROTECTED_RESOURCE_METADATA));
});
```

### CORS Errors
**Symptom**: Browser console shows CORS errors.

**Solution**:
```typescript
import cors from 'cors';

app.use(cors({
  origin: '*', // Or specific origins in production
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
```

### MCP Inspector Can't Connect
**Symptom**: `npx @modelcontextprotocol/inspector` shows connection errors.

**Cause 1**: Wrong endpoint URL
- Inspector default is `http://localhost:3002/` - verify your port.

**Cause 2**: Missing SSE headers
- Streamable HTTP transport requires proper SSE headers.

**Solution**:
```typescript
app.use(express.json());
app.use(cors());
```

### Tool Calls Return "Invalid Request"
**Symptom**: Tool registration succeeds but calls fail with JSON-RPC error.

**Cause**: JSON-RPC format mismatch or tool handler error.

**Solution**:
1. Ensure tool handlers return proper JSON-RPC response format
2. Check console for uncaught errors in tool handlers
3. Use MCP Inspector to see raw JSON-RPC messages

## Debugging Tips

### Enable Debug Logging
```typescript
const DEBUG = process.env.DEBUG === 'true';

function debugLog(...args: any[]) {
  if (DEBUG) console.log('[DEBUG]', ...args);
}
```

Set `DEBUG=true` in .env.

### Verify Token Contents
Decode your access token (JWT format) to check claims:
```bash
# Get token from MCP client logs
echo "<your-token>" | jq -R 'split(".") | .[1] | @base64d | fromjson'
```

Check `aud`, `iss`, `exp`, and `scope` claims.

### Test Scalekit Connection
```typescript
import { Scalekit } from '@scalekit-sdk/node';

const scalekit = new Scalekit(
  process.env.SK_ENV_URL,
  process.env.SK_CLIENT_ID,
  process.env.SK_CLIENT_SECRET
);

// Test connection
scalekit.discoverAuthorizationServer()
  .then(info => console.log('Connected:', info))
  .catch(err => console.error('Connection failed:', err));
```

### Test Each Component Isolated

1. **Discovery endpoint**:
```bash
curl http://localhost:3002/.well-known/oauth-protected-resource
```

2. **Health endpoint**:
```bash
curl http://localhost:3002/health
```

3. **Auth middleware** (should return 401):
```bash
curl -i -X POST http://localhost:3002/ -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

4. **With valid token** (use token from MCP client):
```bash
curl -X POST http://localhost:3002/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

## Common Environment Variable Mistakes

| Variable | Common Mistake | Correct Value |
|----------|----------------|---------------|
| `SK_ENV_URL` | Missing protocol | `https://your-env.scalekit.com` |
| `EXPECTED_AUDIENCE` | Wrong casing | Must match Scalekit "Server URL" exactly |
| `PROTECTED_RESOURCE_METADATA` | Not JSON-escaped | Must be valid JSON string |
| `PORT` | Already in use | Choose unused port (3002, 8080, etc.) |

## Getting Help

If issues persist:
1. Check Scalekit dashboard for server status
2. Review Scalekit logs for authentication attempts
3. Enable DEBUG mode and capture full request/response
4. Verify MCP client configuration (server URL, auth settings)
5. Test with MCP Inspector to isolate client vs server issues
