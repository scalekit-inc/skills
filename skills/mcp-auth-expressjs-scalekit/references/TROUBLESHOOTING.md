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
