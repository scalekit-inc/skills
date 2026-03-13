---
name: sk-actions-custom-provider
description: Create or review Scalekit custom providers/connectors for proxy-only usage. Use this skill when the task is to gather API docs, infer whether a connector is OAuth, Basic, Bearer, or API Key, determine required tracked fields like domain or version, generate provider JSON, check for existing custom providers, show update diffs, run approved create or update curls, and print resolved delete curls.
---

# Custom Provider

Use this skill for Scalekit custom providers, also called connectors.

This skill is only for proxy-only connectors.

## Execution Policy

- The skill may run the token curl to generate `env_access_token`.
- The skill may run the read-only list providers curl to check existing custom providers.
- The skill may run the create curl only after explicit user approval.
- The skill may run the update curl only after the required diff review and explicit user confirmation.
- The skill must never run the delete curl. It should only print the resolved delete command and ask the user to run it from their terminal.
- Whenever the skill executes a curl, label the result with `✅` for success or `❌` for failure.

## Goal

Help the user:
- collect the required Scalekit environment and client credentials before any provider action
- define a valid custom provider JSON
- identify the correct auth type
- discover required auth details from docs when possible
- determine whether extra tracked fields like `domain`, `version`, or named `path_variables` are needed
- run create only after explicit user approval
- run update only after diff review and explicit confirmation
- print the correct delete curl after resolving the provider identifier from the list providers response

## Interaction Flow

Follow this sequence.

1. At skill start, send this opening message once and only once:

```text
Share:
- SCALEKIT_ENVIRONMENT_URL
- SCALEKIT_CLIENT_ID
- SCALEKIT_CLIENT_SECRET
- Custom provider name
- API docs link
- Auth docs link if separate
- Base API URL if you already know it

This skill is only for proxy-only connectors.
```

Do not restate or paraphrase this startup request again in the same reply.
2. Use `SCALEKIT_ENVIRONMENT_URL` as `env_url`.
3. Generate `env_access_token` with:

```bash
curl --location '{{SCALEKIT_ENVIRONMENT_URL}}/oauth/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id={{SCALEKIT_CLIENT_ID}}' \
--data-urlencode 'client_secret={{SCALEKIT_CLIENT_SECRET}}'
```

4. After the user provides the custom provider name, list existing custom providers with:

```bash
curl --location '{{SCALEKIT_ENVIRONMENT_URL}}/api/v1/providers?filter.provider_type=CUSTOM&page_size=1000' \
--header 'Authorization: Bearer {{env_access_token}}'
```

5. Compare the provided name against the returned custom providers.
6. If the user says they want to delete the custom provider at any point, switch to delete mode:
   - read `providers[]`
   - find the matching provider object
   - use its `identifier` field, not its `id` field
   - print the delete curl with the resolved `identifier`, the actual `SCALEKIT_ENVIRONMENT_URL`, and the actual `env_access_token`
   - ask the user to run that delete curl from their terminal
   - if delete fails due to existing connections, tell the user to go to Scalekit Dashboard, delete associated connections and connected accounts if any, and then retry deleting the custom provider
   - stop and do not continue into create or update
7. If a provider with the same name already exists, ask:
   - This provider already exists. Do you want me to update the existing provider, or create a new one?
8. If the user wants to update the existing provider, continue in update mode and reuse that provider.
9. If the user wants to create a new provider, continue in create mode.
10. Tell the user this skill is for proxy-only connectors.
11. Read the docs and infer which auth type it is:
   - `OAUTH`
   - `BASIC`
   - `BEARER`
   - `API_KEY`
12. If auth type is unclear, ask the user to choose one.
13. Give a one-line explanation for the auth type:
   - `OAUTH`: standard OAuth 2.0 flow with authorize/token endpoints and user authorization
   - `BASIC`: proxy sends `Authorization: Basic base64(username:password)`
   - `BEARER`: proxy sends `Authorization: Bearer <token>`
   - `API_KEY`: proxy sends `Authorization: <api_key>` as-is
14. If auth type is `OAUTH`, try to discover:
   - `authorize_uri`
   - `token_uri`
   - `user_info_uri`
   - visible scopes
15. If any required OAuth values are missing, ask only for the missing values.
16. Inspect docs for concrete extra tracked fields from this known set:
   - `token`
   - `api_key`
   - `username`
   - `password`
   - `domain`
   - `version`
   - `path_variables`
17. For `path_variables`, ask for exact names if they are not clear from docs.
18. Determine the correct `proxy_url`.
19. Generate the final provider JSON.
20. If the user asks to leave `proxy_url` empty or set `proxy_enabled` to `false`, tell them that tool calling will not work in that configuration because custom providers support tool calling only through the tool proxy feature.
21. Do not leave `proxy_url` empty and do not set `proxy_enabled` to `false`.
22. If the workflow is in update mode:
   - compare the previous provider JSON and the new provider JSON in a table that includes only `display_name`, `description`, `auth_patterns`, `proxy_url`, and `proxy_enabled`
   - if OAuth scopes were removed or added, tell the user to carefully verify those scope changes
   - tell the user this update might require creating a new connection because older connections will not have the new settings
   - tell the user the same applies to connected accounts, or they can update the connected account by reauthorizing it
   - resolve the provider identifier from `providers[] -> matching object -> identifier`, not `id`
   - ask the user to confirm the updated values
   - only after explicit confirmation, run the update curl
   - after update, tell the user: Refresh the page on Scalekit Dashboard to see the new provider.
23. If the workflow is in create mode:
   - ask for explicit approval before running the create curl
   - only after explicit approval, run the create curl
   - after create, tell the user: Refresh the page on Scalekit Dashboard to see the new provider.

## What To Ask

Prefer short, concrete questions.

The initial request for required inputs is defined in `Interaction Flow` step 1. Do not repeat that opening block again.

Ask later only if needed:
- I found this custom provider in the list response. Do you want me to delete it?
- This provider already exists. Do you want me to update the existing provider, or create a new one?
- Carefully verify the scope changes. Some earlier scopes were removed or new scopes were added. Do you want to proceed with these updated values?
- If you leave `proxy_url` empty or set `proxy_enabled` to `false`, tool calling will not work because custom providers support tool calling only through the tool proxy feature.
- I believe this auth type is `X` because of `Y`. Confirm or correct me.
- I could not find `authorize_uri` or `token_uri`. Please provide the missing OAuth endpoints.
- I see the API host is tenant-specific. What field should be tracked for that host value?
- I see a required URL placeholder like `cloud_id`. Confirm that `path_variables.cloud_id` should be tracked.

Do not ask broad, open-ended questions when the docs already imply the answer.

## Display Name Rules

The server derives the identifier from `display_name`.

When generating JSON:
- keep `display_name` under 200 characters
- prefer alphanumeric and hyphen-friendly names
- spaces are acceptable
- if the user gives a risky or overly long name, propose a safer `display_name` before generating JSON

Do not ask the user to choose the identifier.

## Provider Shape

Common top-level fields:
- `display_name`
- `description`
- `auth_patterns`
- `proxy_url`
- `proxy_enabled`

Common `auth_patterns[]` fields:
- `type`
- `display_name`
- `description`
- `fields`
- `oauth_config` for OAuth only

Supported field input types:
- `text`
- `password`
- `select`

Default assumptions:
- `proxy_enabled` should be `true`
- `proxy_url` must not be empty

If a user asks to leave `proxy_url` empty or set `proxy_enabled` to `false`, tell them that tool calling will not work because custom providers support tool calling only through the tool proxy feature.

## The 4 Provider Types

### OAuth Provider

Use when the upstream service uses OAuth 2.0.

Required shape:
- `auth_patterns[].type = "OAUTH"`
- `oauth_config` present

Usually includes:
- `authorize_uri`
- `token_uri`
- `user_info_uri`
- `available_scopes`

Optional OAuth config fields supported by the backend:
- `allow_use_scalekit_credentials`
- `custom_scope_name`
- `pkce_enabled`

OAuth `fields` are usually auth-time options, not long-lived secrets.

Example:

```json
{
  "display_name": "My Asana",
  "description": "Connect to Asana. Manage tasks, projects, teams, and workflow automation",
  "auth_patterns": [
    {
      "description": "Authenticate with Asana using OAuth 2.0",
      "display_name": "OAuth 2.0",
      "fields": [],
      "oauth_config": {
        "authorize_uri": "https://app.asana.com/-/oauth_authorize",
        "available_scopes": [
          {
            "description": "Read user profile and basic data",
            "display_name": "Default Access",
            "required": false,
            "scope": "default"
          }
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

### Basic Provider

Use when the upstream API expects HTTP Basic auth.

Required shape:
- `auth_patterns[].type = "BASIC"`
- `fields` collects the values needed for Basic auth

Typical fields:
- `username`
- `password`
- `domain` if the API host varies per customer

Runtime behavior:
- proxy sends `Authorization: Basic base64(username:password)`

Example:

```json
{
  "display_name": "My Freshdesk",
  "description": "Connect to Freshdesk. Manage tickets, contacts, companies, and customer support workflows",
  "auth_patterns": [
    {
      "description": "Authenticate with Freshdesk using Basic Auth",
      "display_name": "Basic Auth",
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
      "type": "BASIC"
    }
  ],
  "proxy_url": "https://{{domain}}/api",
  "proxy_enabled": true
}
```

### Bearer Provider

Use when the upstream API expects:

```text
Authorization: Bearer <token>
```

Required shape:
- `auth_patterns[].type = "BEARER"`
- `fields` usually includes `token`

Example:

```json
{
  "display_name": "My Tavily",
  "description": "Use Tavily to connect your agent to the web and search for information across the internet",
  "auth_patterns": [
    {
      "description": "Authenticate with Tavily using your API Key",
      "display_name": "Bearer Auth",
      "fields": [
        {
          "field_name": "token",
          "hint": "Your Tavily API Key",
          "input_type": "password",
          "label": "API Key",
          "required": true
        }
      ],
      "type": "BEARER"
    }
  ],
  "proxy_url": "https://api.tavily.com",
  "proxy_enabled": true
}
```

### API Key Provider

Use when the upstream API expects the raw API key in `Authorization` with no prefix.

Required shape:
- `auth_patterns[].type = "API_KEY"`
- `fields` usually includes `api_key`

Runtime behavior:
- proxy sends `Authorization: <api_key>`

Example:

```json
{
  "display_name": "My Klaviyo",
  "description": "Use Klaviyo to connect your agent to the AI marketing platform",
  "auth_patterns": [
    {
      "description": "Authenticate with Klaviyo private API Key",
      "display_name": "API Key",
      "fields": [
        {
          "field_name": "api_key",
          "hint": "Your Klaviyo API Key",
          "input_type": "password",
          "label": "API Key",
          "required": true
        }
      ],
      "type": "API_KEY"
    }
  ],
  "proxy_url": "https://a.klaviyo.com",
  "proxy_enabled": true
}
```

## Tracked Fields

Work from this known set first:
- `token`
- `api_key`
- `username`
- `password`
- `domain`
- `version`
- `path_variables`

Use only the fields the provider actually needs.

Examples:
- tenant-specific hostnames:
  - track `domain`
  - use `proxy_url` like `https://{{domain}}/api/v2`
- versioned APIs:
  - track `version`
  - use `proxy_url` like `https://api.example.com/{{version}}`
- path placeholders discovered from docs:
  - track named `path_variables`
  - example keys: `cloud_id`, `tenant`, `workspace_id`

For `path_variables`, be concrete:
- `path_variables.cloud_id`
- `path_variables.workspace_id`

If the exact key names are unclear, ask the user to confirm them.

## Supported Placeholders

The backend supports:
- `{{domain}}`
- `{{version}}`
- named placeholders for path variables like `{{cloud_id}}` or `{{tenant}}`

Use placeholders only when the API contract requires them.

## How To Decide Proxy URL

Pick one of these patterns:

1. Fixed base URL

```json
"proxy_url": "https://api.example.com"
```

2. Tenant-specific domain

```json
"proxy_url": "https://{{domain}}/api"
```

3. Versioned URL

```json
"proxy_url": "https://api.example.com/{{version}}"
```

4. URL with named path variable

```json
"proxy_url": "https://api.atlassian.com/ex/{{cloud_id}}"
```

When responding, state why the chosen shape is correct.

## Missing Info And Assumptions

Before generating the final JSON, summarize:
- values confirmed from docs
- values provided by the user
- values assumed by you
- values still missing

If critical auth details are missing, stop and ask only for those missing values.

If the provided docs are too vague, say so directly and ask for the API auth reference.

## Output Format

When ready, respond in this order:

1. short summary
   - inferred auth type
   - tracked fields
   - proxy URL choice
2. for create or update, provider JSON
3. for updates, a field diff table covering only `display_name`, `description`, `auth_patterns`, `proxy_url`, and `proxy_enabled`
4. create, update, or delete action
5. short note about assumptions or placeholders

## Curl Instructions

Before listing, creating, updating, or deleting providers, generate `env_access_token` with:

```bash
curl --location '{{SCALEKIT_ENVIRONMENT_URL}}/oauth/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id={{SCALEKIT_CLIENT_ID}}' \
--data-urlencode 'client_secret={{SCALEKIT_CLIENT_SECRET}}'
```

Use this list providers curl when checking for existing custom providers:

```bash
curl --location '{{SCALEKIT_ENVIRONMENT_URL}}/api/v1/providers?filter.provider_type=CUSTOM&page_size=1000' \
--header 'Authorization: Bearer {{env_access_token}}'
```

### Create

Only after explicit user approval, run:

```bash
curl --location '{{SCALEKIT_ENVIRONMENT_URL}}/api/v1/custom-providers' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{env_access_token}}' \
--data '{
  ...generated-json...
}'
```

After create, tell the user: Refresh the page on Scalekit Dashboard to see the new provider.

### Update

Before running the update curl:
- read `providers[]`
- find the matching provider object
- use its `identifier` field, not its `id` field
- show the required diff table for `display_name`, `description`, `auth_patterns`, `proxy_url`, and `proxy_enabled`
- tell the user to carefully verify scope removals or additions if OAuth scopes changed
- tell the user this update might require creating a new connection because older connections will not have the new settings
- tell the user the same applies to connected accounts, or they can update the connected account by reauthorizing it
- wait for explicit confirmation

After confirmation, run:

```bash
curl --location '{{SCALEKIT_ENVIRONMENT_URL}}/api/v1/custom-providers/{{identifier}}' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{env_access_token}}' \
--data '{
  ...generated-json...
}'
```

After update, tell the user: Refresh the page on Scalekit Dashboard to see the new provider.

Do not fabricate identifiers.

### Delete

If the user asks to delete the custom provider:
- run the list providers curl
- read `providers[]`
- find the matching provider object
- use its `identifier` field, not its `id` field
- print the delete curl only and never execute it
- when printing it, replace `SCALEKIT_ENVIRONMENT_URL` and `env_access_token` with the actual values already available in the conversation
- ask the user to run that delete curl from their terminal
- tell the user: Refresh the page on Scalekit Dashboard to see the provider removed.
- if the delete API fails due to existing connections, tell the user:
  Go to Scalekit Dashboard, delete the associated connections and connected accounts if any, and only then delete the custom provider.

```bash
curl --location --request DELETE 'https://actual-environment-url/api/v1/custom-providers/{{provider_identifier_from_list_custom_provider_api}}' \
--header 'Authorization: Bearer actual-env-access-token'
```

Do not fabricate identifiers.

## Review Checklist

Before finalizing:
- `display_name` is safe and under 200 chars
- auth type matches the upstream docs
- `oauth_config` exists only for OAuth providers
- tracked fields are concrete and minimal
- `proxy_url` matches the upstream host pattern
- `proxy_url` is not empty
- placeholders are used only when needed
- `proxy_enabled` is `true`
- if the user requested empty `proxy_url` or `proxy_enabled: false`, they were told tool calling would not work because custom providers support tool calling only through the tool proxy feature
- for updates, a diff table exists for `display_name`, `description`, `auth_patterns`, `proxy_url`, and `proxy_enabled`
- for updates, OAuth scope removals or additions are called out explicitly when present
- for updates, the user is warned that existing connections may need to be recreated and connected accounts may need reauthorization
- create runs only after explicit user approval
- update runs only after explicit user confirmation
- after create or update, the user is told to refresh the Scalekit Dashboard page to see the new provider
- for updates, the provider identifier comes from `providers[] -> matching object -> identifier`
- for deletes, the provider identifier comes from `providers[] -> matching object -> identifier`
- delete curl is printed with the resolved provider identifier
- delete curl is never executed
- for deletes, the user is told to run the printed delete curl from their terminal
- after delete, the user is told to refresh the Scalekit Dashboard page to see the provider removed
- if delete fails due to existing connections, the user is told to remove associated connections and connected accounts from Scalekit Dashboard before retrying
- executed curl results are labeled with `✅` or `❌`
- printed delete curl uses the actual environment URL and actual access token values instead of placeholders
