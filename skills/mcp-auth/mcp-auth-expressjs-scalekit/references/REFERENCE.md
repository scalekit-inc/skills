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
