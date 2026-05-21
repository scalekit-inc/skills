# Provider Type Examples

## OAuth Provider (Asana)

```json
{
  "display_name": "My Asana",
  "description": "Connect to Asana. Manage tasks, projects, teams, and workflow automation",
  "auth_patterns": [
    {
      "description": "Authenticate with Asana using OAuth 2.0",
      "display_name": "OAuth 2.0",
      "account_fields": [],
      "fields": [],
      "oauth_config": {
        "authorize_uri": "https://app.asana.com/-/oauth_authorize",
        "available_scopes": [
          { "description": "Read user profile and basic data", "display_name": "Default Access", "required": false, "scope": "default" }
        ],
        "token_uri": "https://app.asana.com/-/oauth_token",
        "user_info_uri": "https://app.asana.com/api/1.0/users/me"
      },
      "type": "OAUTH"
    }
  ],
  "proxy_url": "https://app.asana.com/api",
  "proxy_enabled": true
}
```

Notes: OAuth `fields` are auth-time options, not secrets. Path params go in `account_fields`. Optional `oauth_config` fields: `allow_use_scalekit_credentials`, `custom_scope_name`, `pkce_enabled`.

## Basic Provider (Freshdesk)

```json
{
  "display_name": "My Freshdesk",
  "description": "Connect to Freshdesk. Manage tickets, contacts, companies, and customer support workflows",
  "auth_patterns": [
    {
      "description": "Authenticate with Freshdesk using Basic Auth",
      "display_name": "Basic Auth",
      "fields": [
        { "field_name": "domain", "hint": "yourcompany.freshdesk.com", "input_type": "text", "label": "Freshdesk Domain", "required": true },
        { "field_name": "username", "hint": "Your Freshdesk API Key", "input_type": "password", "label": "API Key", "required": true }
      ],
      "auth_field_mutations": {
        "password": { "default": "X" },
        "username": { "suffix": "/token" }
      },
      "type": "BASIC"
    }
  ],
  "proxy_url": "https://{{domain}}/api",
  "proxy_enabled": true
}
```

Runtime: proxy sends `Authorization: Basic base64(username:password)`. Mutations applied before encoding.

## Bearer Provider (Tavily)

```json
{
  "display_name": "My Tavily",
  "description": "Use Tavily to connect your agent to the web",
  "auth_patterns": [
    {
      "description": "Authenticate with Tavily using your API Key",
      "display_name": "Bearer Auth",
      "fields": [
        { "field_name": "token", "hint": "Your Tavily API Key", "input_type": "password", "label": "API Key", "required": true }
      ],
      "type": "BEARER"
    }
  ],
  "proxy_url": "https://api.tavily.com",
  "proxy_enabled": true
}
```

Runtime: proxy sends `Authorization: Bearer <token>`. `auth_field_mutations.token` applied first if present.

## API Key Provider (Klaviyo)

```json
{
  "display_name": "My Klaviyo",
  "description": "Use Klaviyo to connect your agent to the AI marketing platform",
  "auth_patterns": [
    {
      "description": "Authenticate with Klaviyo private API Key",
      "display_name": "API Key",
      "fields": [
        { "field_name": "api_key", "hint": "Your Klaviyo API Key", "input_type": "password", "label": "API Key", "required": true }
      ],
      "auth_header_key_override": "x-api-key",
      "auth_field_mutations": { "api_key": { "prefix": "Klaviyo-API-Key " } },
      "type": "API_KEY"
    }
  ],
  "proxy_url": "https://a.klaviyo.com",
  "proxy_enabled": true
}
```

Runtime: proxy sends `Authorization: <api_key>` (raw, no prefix). `auth_header_key_override` changes the header key.

## MCP OAuth Provider (GitHub)

```json
{
  "display_name": "Github MCP",
  "description": "Connect to Github MCP",
  "auth_patterns": [
    {
      "description": "Authenticate with Github MCP using browser OAuth.",
      "display_name": "OAuth 2.1/DCR",
      "fields": [],
      "is_mcp": true,
      "oauth_config": { "pkce_enabled": true },
      "type": "OAUTH"
    }
  ],
  "proxy_url": "https://api.githubcopilot.com/mcp/",
  "proxy_enabled": true
}
```

MCP OAuth: `oauth_config` must be `{"pkce_enabled": true}` only. No `authorize_uri`/`token_uri`/`user_info_uri` — uses DCR.

## MCP Bearer Provider (Apify)

```json
{
  "display_name": "Apify MCP",
  "description": "Connect to Apify MCP for web scraping and data extraction",
  "auth_patterns": [
    {
      "description": "Authenticate with Apify using your API Token.",
      "display_name": "Apify Token",
      "fields": [
        { "field_name": "token", "hint": "Your Apify API Token", "input_type": "password", "label": "Apify Token", "required": true }
      ],
      "is_mcp": true,
      "type": "BEARER"
    }
  ],
  "proxy_url": "https://mcp.apify.com",
  "proxy_enabled": true
}
```

## Auth Header Customization

### `auth_header_key_override`
When upstream expects credentials in a non-`Authorization` header: `"auth_header_key_override": "x-api-key"`

### `auth_field_mutations`
Transform credentials before proxy formatting. Supported targets: `api_key`, `token`, `username`, `password`.

| Mutation | Effect | Example |
|----------|--------|---------|
| `prefix` | Prepend text | `"prefix": "Klaviyo-API-Key "` |
| `suffix` | Append text | `"suffix": "/token"` |
| `default` | Use when empty | `"default": "X"` |

Order: `default` → `prefix` → `suffix` → proxy format (`Bearer ` or base64).

## Connected Account Path Variables

For static auth (`BASIC`, `BEARER`, `API_KEY`):
```json
{ "connected_account": { "authorization_details": { "static_auth": { "details": { "path_variables": { "param": "value" } } } } } }
```

For OAuth:
```json
{ "connected_account": { "api_config": { "path_variables": { "param": "value" } } } }
```