# Custom Provider Skill

This skill helps you create, review, update, or prepare deletion for a Scalekit custom provider.

It is only for **proxy-only** connectors.

## When To Use It

Use this skill when you want help with any of the following:
- creating a new custom provider in `Dev`
- reviewing an existing custom provider
- updating an existing custom provider
- replicating a provider from `Dev` to `Production`
- preparing the delete curl for a provider

## What The Skill Does

The skill can:
- read API and auth docs in `Dev`
- infer the auth type: `OAUTH`, `BASIC`, `BEARER`, or `API_KEY`
- generate the provider JSON
- list existing custom providers
- show diffs before updates
- prepare create, update, or delete curls

## Dev vs Production

The skill starts by asking whether the target environment is `Dev` or `Production`.

### If you choose `Dev`

The skill will ask you for:
- `SCALEKIT_ENVIRONMENT_URL`
- `SCALEKIT_CLIENT_ID`
- `SCALEKIT_CLIENT_SECRET`
- provider name
- API docs link
- auth docs link if separate
- base API URL if you already know it

Then it will:
- inspect the docs
- generate the provider JSON
- list matching providers if needed
- create only after your approval
- update only after showing a diff and getting your confirmation

### If you choose `Production`

The skill will ask you for:
- `PROD_SCALEKIT_ENVIRONMENT_URL`
- `PROD_SCALEKIT_CLIENT_ID`
- `PROD_SCALEKIT_CLIENT_SECRET`
- `DEV_SCALEKIT_ENVIRONMENT_URL`
- `DEV_SCALEKIT_CLIENT_ID`
- `DEV_SCALEKIT_CLIENT_SECRET`
- the provider name you want to replicate in `Production`

Then it will:
- list providers in `Dev`
- find the matching provider there
- use the `Dev` provider as the source of truth
- list providers in `Production`
- decide whether the `Production` action is create or update
- print the final curl for you to run manually

Important:
- in `Production`, the skill may run token and list-provider curls
- in `Production`, the skill does **not** execute create, update, or delete curls

## What You Should Expect

### For `Dev`

You should expect:
- a short summary of the auth type and proxy shape
- the generated provider JSON
- a diff before updates
- a create or update action only after your approval

### For `Production`

You should expect:
- the provider JSON fetched from `Dev`
- if the provider already exists in `Production`, a three-way diff with:
  - `Dev`
  - `Current Production`
  - `Proposed`
- a resolved create or update curl that you run yourself

## Delete Behavior

If you ask to delete a provider, the skill will:
- list providers
- resolve the correct provider identifier
- print the delete curl for you

It will **not** execute the delete curl for you.

## Example Prompts

```text
Use $sk-actions-custom-provider to create a custom provider in Dev.
```

```text
Use $sk-actions-custom-provider to update the custom provider for <provider-name>.
```

```text
Use $sk-actions-custom-provider to replicate <provider-name> from Dev to Production.
```

```text
Use $sk-actions-custom-provider to prepare the delete curl for <provider-name>.
```

## Provider Payload Reference

This section is a quick reference for the kinds of provider payloads the skill can help you build in `Dev`.

### Common top-level properties

- `display_name`
  Human-readable name for the provider.
- `description`
  Short description shown for the integration.
- `auth_patterns`
  List of supported authentication methods for the provider.
- `proxy_url`
  Base URL used by the tool proxy. This should not be empty for proxy-only connectors.
- `proxy_enabled`
  Should remain `true` for proxy-only connectors.

### Common auth pattern properties

- `type`
  Authentication type. Supported values are `OAUTH`, `BASIC`, `BEARER`, and `API_KEY`.
- `display_name`
  Label shown for that auth option.
- `description`
  Short explanation of how that auth option works.
- `fields`
  Inputs collected for the auth pattern.
- `account_fields`
  Account-scoped inputs. For OAuth path parameters, use this instead of `fields`.
- `oauth_config`
  OAuth-only configuration block.
- `auth_header_key_override`
  Lets you send the auth credential in a header other than `Authorization`.
- `auth_field_mutations`
  Lets you transform `api_key`, `token`, `username`, or `password` before the proxy formats the auth header.

### Supported auth types

#### 1. OAuth

Use this when the upstream service uses OAuth 2.0.

Typical properties:
- `oauth_config.authorize_uri`
  OAuth authorization endpoint.
- `oauth_config.token_uri`
  OAuth token exchange endpoint.
- `oauth_config.user_info_uri`
  Endpoint used to fetch the authenticated user profile, when available.
- `oauth_config.available_scopes`
  List of scopes users can authorize.

Example provider payload:

```json
{
  "display_name": "My Figma",
  "description": "Connect to Figma. Access files, comments, and design metadata through the tool proxy",
  "auth_patterns": [
    {
      "type": "OAUTH",
      "display_name": "OAuth 2.0",
      "description": "Authenticate with Figma using OAuth 2.0",
      "account_fields": [],
      "fields": [],
      "oauth_config": {
        "authorize_uri": "https://www.figma.com/oauth",
        "token_uri": "https://api.figma.com/v1/oauth/token",
        "user_info_uri": "https://api.figma.com/v1/me",
        "available_scopes": [
          {
            "scope": "file_content:read",
            "display_name": "Read file content",
            "description": "Read file content and related metadata",
            "required": false
          }
        ]
      }
    }
  ],
  "proxy_url": "https://api.figma.com/v1",
  "proxy_enabled": true
}
```

#### 2. Basic

Use this when the upstream expects:

```text
Authorization: Basic base64(username:password)
```

Typical properties:
- `fields[].field_name = "username"`
  Username or API-key-like username portion of Basic auth.
- `fields[].field_name = "password"`
  Password or static companion value used with Basic auth.
- `fields[].field_name = "domain"`
  Customer-specific hostname if the API base URL changes per tenant.

Example provider payload:

```json
{
  "display_name": "My Freshdesk",
  "description": "Connect to Freshdesk. Manage tickets, contacts, companies, and support workflows",
  "auth_patterns": [
    {
      "type": "BASIC",
      "display_name": "Basic Auth",
      "description": "Authenticate with Freshdesk using Basic Auth",
      "fields": [
        {
          "field_name": "domain",
          "hint": "yourcompany.freshdesk.com",
          "input_type": "text",
          "label": "Freshdesk Domain",
          "required": true
        },
        {
          "field_name": "username",
          "hint": "Your Freshdesk API Key",
          "input_type": "password",
          "label": "API Key",
          "required": true
        }
      ],
      "auth_field_mutations": {
        "password": {
          "default": "X"
        }
      }
    }
  ],
  "proxy_url": "https://{{domain}}/api",
  "proxy_enabled": true
}
```

#### 3. Bearer

Use this when the upstream expects:

```text
Authorization: Bearer <token>
```

Typical properties:
- `fields[].field_name = "token"`
  The bearer token or API token to send.

Example provider payload:

```json
{
  "display_name": "My Tavily",
  "description": "Use Tavily to connect your agent to the web and search for information across the internet",
  "auth_patterns": [
    {
      "type": "BEARER",
      "display_name": "Bearer Auth",
      "description": "Authenticate with Tavily using your API Key",
      "fields": [
        {
          "field_name": "token",
          "hint": "Your Tavily API Key",
          "input_type": "password",
          "label": "API Key",
          "required": true
        }
      ]
    }
  ],
  "proxy_url": "https://api.tavily.com",
  "proxy_enabled": true
}
```

#### 4. API Key

Use this when the upstream expects the raw API key in `Authorization` or in a custom header.

Typical properties:
- `fields[].field_name = "api_key"`
  API key stored for the provider.
- `auth_header_key_override`
  Optional header name override such as `x-api-key`.
- `auth_field_mutations.api_key`
  Optional mutation block to add a prefix, suffix, or default.

Example provider payload:

```json
{
  "display_name": "My Klaviyo",
  "description": "Use Klaviyo to connect your agent to the marketing automation platform",
  "auth_patterns": [
    {
      "type": "API_KEY",
      "display_name": "API Key",
      "description": "Authenticate with Klaviyo private API Key",
      "fields": [
        {
          "field_name": "api_key",
          "hint": "Your Klaviyo API Key",
          "input_type": "password",
          "label": "API Key",
          "required": true
        }
      ],
      "auth_header_key_override": "x-api-key",
      "auth_field_mutations": {
        "api_key": {
          "prefix": "Klaviyo-API-Key "
        }
      }
    }
  ],
  "proxy_url": "https://a.klaviyo.com",
  "proxy_enabled": true
}
```

### Auth header mutations

The skill can configure auth credential transformations when upstream APIs need special formatting.

Supported mutation properties:
- `prefix`
  Prepends text before the stored value.
- `suffix`
  Appends text after the stored value.
- `default`
  Uses a fallback value if the stored value is empty.

Examples:
- Zendesk-style username suffix:
  `"/token"` added to the username before Basic auth is encoded.
- Freshdesk-style default password:
  `"X"` used as the password when the API only needs an API key plus static password.
- Klaviyo-style API key prefix:
  `"Klaviyo-API-Key "` added before the stored API key.

### Path parameter fields

If the upstream URL needs path placeholders, the skill can add fields with `is_path_param: true`.

Example path-param field:

```json
{
  "field_name": "path_param_1",
  "hint": "Path Param 1",
  "input_type": "text",
  "is_path_param": true,
  "label": "Path Param 1",
  "required": true
}
```

Rules:
- for `OAUTH`, put path-param fields in `account_fields`
- for `BASIC`, `BEARER`, and `API_KEY`, put path-param fields in `fields`
- the `proxy_url` placeholder must match the field name

Example `proxy_url`:

```json
"proxy_url": "https://api.example.com/resources/{{path_param_1}}"
```

### Connected account note for path variables

Only when the provider uses path variables, the connected account must send runtime values for those placeholders.

For static auth:

```json
{
  "identifier": "some-identifier",
  "connector": "mycustomprovider",
  "connected_account": {
    "authorization_details": {
      "static_auth": {
        "details": {
          "path_variables": {
            "path_param_1": "value_1"
          }
        }
      }
    }
  }
}
```

For OAuth:

```json
{
  "identifier": "some-identifier",
  "connector": "myoauthcustomconnector",
  "connected_account": {
    "authorization_details": {
      "oauth_token": {}
    },
    "api_config": {
      "path_variables": {
        "path_param_1": "value_1"
      }
    }
  }
}
```
