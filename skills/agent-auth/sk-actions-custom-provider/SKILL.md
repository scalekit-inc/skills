---
name: sk-actions-custom-provider
description: Create or review Scalekit custom providers/connectors for proxy-only usage. Use this skill when the task is to gather API docs, infer whether a connector is OAuth, Basic, Bearer, or API Key, determine required tracked fields like domain or version, generate provider JSON, check for existing custom providers, show update diffs, run approved create or update curls, and print resolved delete curls.
---

# Custom Provider

Use this skill for Scalekit custom providers, also called connectors.

This skill is only for proxy-only connectors.

## Execution Policy

- The skill must ask whether the target Scalekit environment is `Dev` or `Production` before doing anything else.
- In `Dev`, the skill may run the token curl to generate `env_access_token`.
- In `Dev`, the skill may run the read-only list providers curl to check existing custom providers.
- In `Dev`, the skill may run the create curl only after explicit user approval.
- In `Dev`, the skill may run the update curl only after the required diff review and explicit user confirmation.
- In `Production`, the skill may run the token curl to generate `env_access_token`.
- In `Production`, the skill may run read-only list providers curls.
- In `Production`, the skill must never run create, update, or delete curls.
- In `Production`, the skill may give the user resolved curls to run themselves after review.
- The skill must never run the delete curl. It should only print the resolved delete command and ask the user to run it from their terminal.
- Whenever the skill executes a curl, label the result with `✅` for success or `❌` for failure.

## Goal

Help the user:
- determine whether they are targeting `Dev` or `Production`
- collect the required Scalekit environment and client credentials before any provider action
- define a valid custom provider JSON
- identify the correct auth type
- discover required auth details from docs when possible
- determine whether extra tracked fields like `domain`, `version`, or named path parameters are needed
- determine whether auth header customization is needed through `auth_header_key_override` or `auth_field_mutations`
- run create only after explicit user approval in `Dev`
- run update only after diff review and explicit confirmation in `Dev`
- reuse the `Dev` provider JSON as the source of truth when the user wants a `Production` provider
- print the correct delete curl after resolving the provider identifier from the list providers response

## Interaction Flow

Follow this sequence.

1. At skill start, send this opening message once and only once:

```text
Share:
- Is this Scalekit environment Dev or Production?

This skill is only for proxy-only connectors.
```

Do not restate or paraphrase this startup request again in the same reply.
2. Read the user's answer and branch:
   - if target is `Dev`, ask for `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, custom provider name, API docs link, auth docs link if separate, and base API URL if already known
   - if target is `Production`, ask for `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, `DEV_SCALEKIT_ENVIRONMENT_URL`, `DEV_SCALEKIT_CLIENT_ID`, `DEV_SCALEKIT_CLIENT_SECRET`, and custom provider name
   - if target is `Production`, do not generate provider JSON from scratch for production; first fetch the matching provider JSON from `Dev` and use that as the source of truth
3. Use `SCALEKIT_ENVIRONMENT_URL` as `env_url`.
4. In `Dev`, generate `env_access_token` with:

```bash
curl --location '{{SCALEKIT_ENVIRONMENT_URL}}/oauth/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id={{SCALEKIT_CLIENT_ID}}' \
--data-urlencode 'client_secret={{SCALEKIT_CLIENT_SECRET}}'
```

5. In `Dev`, after the user provides the custom provider name, list existing custom providers with:

```bash
curl --location '{{SCALEKIT_ENVIRONMENT_URL}}/api/v1/providers?filter.provider_type=CUSTOM&page_size=1000' \
--header 'Authorization: Bearer {{env_access_token}}'
```

6. In `Dev`, compare the provided name against the returned custom providers.
7. If target is `Production`:
   - ask for `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, and `SCALEKIT_CLIENT_SECRET` if the user did not already provide them for Production
   - ask for `DEV_SCALEKIT_ENVIRONMENT_URL`, `DEV_SCALEKIT_CLIENT_ID`, and `DEV_SCALEKIT_CLIENT_SECRET` if the user did not already provide them
   - generate a Dev `env_access_token`
   - list Dev custom providers
   - find the provider that matches the requested provider name
   - if no matching Dev provider exists, stop and tell the user you cannot safely prepare a Production curl without the Dev provider JSON
   - use the Dev provider JSON as the source of truth instead of regenerating it from scratch
   - ask the user to review that provider JSON
   - generate a Production `env_access_token`
   - list Production custom providers to determine whether the action is create or update
   - if the provider already exists in Production, resolve its `identifier`, build a tabular diff with columns `Dev`, `Current Production`, and `Proposed`, and then print the update curl only
   - if the provider does not exist in Production, print the create curl only
   - tell the user to run the printed curl from their terminal
   - stop and do not execute create, update, or delete
8. If the user says they want to delete the custom provider at any point, switch to delete mode:
   - read `providers[]`
   - find the matching provider object
   - use its `identifier` field, not its `id` field
   - print the delete curl with the resolved `identifier`, the actual `SCALEKIT_ENVIRONMENT_URL`, and the actual `env_access_token`
   - ask the user to run that delete curl from their terminal
   - if delete fails due to existing connections, tell the user to go to Scalekit Dashboard, delete associated connections and connected accounts if any, and then retry deleting the custom provider
   - stop and do not continue into create or update
9. If a provider with the same name already exists, ask:
   - This provider already exists. Do you want me to update the existing provider, or create a new one?
10. If the user wants to update the existing provider, continue in update mode and reuse that provider.
11. If the user wants to create a new provider, continue in create mode.
12. Tell the user this skill is for proxy-only connectors.
13. Read the docs and infer which auth type it is:
   - `OAUTH`
   - `BASIC`
   - `BEARER`
   - `API_KEY`
14. If auth type is unclear, ask the user to choose one.
15. Give a one-line explanation for the auth type:
   - `OAUTH`: standard OAuth 2.0 flow with authorize/token endpoints and user authorization
   - `BASIC`: proxy sends `Authorization: Basic base64(username:password)`
   - `BEARER`: proxy sends `Authorization: Bearer <token>`
   - `API_KEY`: proxy sends `Authorization: <api_key>` as-is
16. If auth type is `OAUTH`, try to discover:
   - `authorize_uri`
   - `token_uri`
   - `user_info_uri`
   - visible scopes
17. If any required OAuth values are missing, ask only for the missing values.
18. Inspect docs for concrete extra tracked fields from this known set:
   - `token`
   - `api_key`
   - `username`
   - `password`
   - `domain`
   - `version`
   - named path parameters stored as provider fields with `is_path_param: true`
19. Inspect docs for auth header behavior:
   - if the upstream uses a header key other than `Authorization`, set `auth_header_key_override`
   - if the upstream requires a prefix, suffix, or fallback value on `api_key`, `token`, `username`, or `password`, set `auth_field_mutations`
   - apply those mutations only when the docs clearly require them
20. For named path parameters, ask for exact field names if they are not clear from docs.
21. Determine the correct `proxy_url`.
22. Generate the final provider JSON.
23. If the user asks to leave `proxy_url` empty or set `proxy_enabled` to `false`, tell them that tool calling will not work in that configuration because custom providers support tool calling only through the tool proxy feature.
24. Do not leave `proxy_url` empty and do not set `proxy_enabled` to `false`.
25. If the workflow is in update mode:
   - compare the previous provider JSON and the new provider JSON in a table that includes only `display_name`, `description`, `auth_patterns`, `proxy_url`, and `proxy_enabled`
   - if OAuth scopes were removed or added, tell the user to carefully verify those scope changes
   - tell the user this update might require creating a new connection because older connections will not have the new settings
   - tell the user the same applies to connected accounts, or they can update the connected account by reauthorizing it
   - resolve the provider identifier from `providers[] -> matching object -> identifier`, not `id`
   - ask the user to confirm the updated values
   - only after explicit confirmation, run the update curl
   - after update, tell the user: Refresh the page on Scalekit Dashboard to see the new provider.
26. If the workflow is in create mode:
   - ask for explicit approval before running the create curl
   - only after explicit approval, run the create curl
   - after create, tell the user: Refresh the page on Scalekit Dashboard to see the new provider.

## What To Ask

Prefer short, concrete questions.

The initial request for required inputs is defined in `Interaction Flow` step 1. Do not repeat that opening block again.

Ask later only if needed:
- Is this Scalekit environment `Dev` or `Production`?
- I found this custom provider in the list response. Do you want me to delete it?
- This provider already exists. Do you want me to update the existing provider, or create a new one?
- Carefully verify the scope changes. Some earlier scopes were removed or new scopes were added. Do you want to proceed with these updated values?
- If you leave `proxy_url` empty or set `proxy_enabled` to `false`, tool calling will not work because custom providers support tool calling only through the tool proxy feature.
- I believe this auth type is `X` because of `Y`. Confirm or correct me.
- I could not find `authorize_uri` or `token_uri`. Please provide the missing OAuth endpoints.
- I see the API host is tenant-specific. What field should be tracked for that host value?
- I see a required path placeholder in the API URL. Confirm the exact field name that should be stored on the connected account and substituted into `proxy_url`.
- The docs use a non-standard auth header key. Confirm that I should set `auth_header_key_override` to `X`.
- The docs show the credential needs a prefix, suffix, or fallback value before it is sent. Confirm that I should add `auth_field_mutations` for `X`.
- I found this provider in Dev. Review this provider JSON carefully. If this is a Production update, I will also show a table comparing Dev, current Production, and the proposed payload before printing the curl for you to run yourself.

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
- `account_fields` for account-scoped values when needed
- `oauth_config` for OAuth only
- `auth_header_key_override` when the upstream auth header key is not `Authorization`
- `auth_field_mutations` when the upstream requires a prefix, suffix, or default on `api_key`, `token`, `username`, or `password`

Supported field input types:
- `text`
- `password`
- `select`

Default assumptions:
- `proxy_enabled` should be `true`
- `proxy_url` must not be empty
- the auth header key should stay `Authorization` unless docs require an override
- do not add `auth_field_mutations` unless docs require them

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

For OAuth providers:
- path parameters that must be stored on the connected account should go in `account_fields`, not `fields`

OAuth auth patterns may still use:
- `auth_header_key_override` if the upstream expects the token in a different header name
- `auth_field_mutations.token` if the docs require prefix, suffix, or default handling before the proxy adds `Bearer `

Example:

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
- `auth_field_mutations.username` and `auth_field_mutations.password` are applied before the Basic value is base64-encoded

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
      "auth_field_mutations": {
        "password": {
          "default": "X"
        },
        "username": {
          "suffix": "/token"
        }
      },
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

Runtime behavior:
- proxy applies `auth_field_mutations.token` first if present
- proxy then sends `<header key>: Bearer <mutated token>`

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
- proxy applies `auth_field_mutations.api_key` first if present
- if `auth_header_key_override` is set, proxy sends that header key instead of `Authorization`

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
      "auth_header_key_override": "x-api-key",
      "auth_field_mutations": {
        "api_key": {
          "prefix": "Klaviyo-API-Key "
        }
      },
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
- named path parameters stored with `is_path_param: true`

Use only the fields the provider actually needs.

Examples:
- tenant-specific hostnames:
  - track `domain`
  - use `proxy_url` like `https://{{domain}}/api/v2`
- versioned APIs:
  - track `version`
  - use `proxy_url` like `https://api.example.com/{{version}}`
- path placeholders discovered from docs:
  - add one field per placeholder
  - set `is_path_param` to `true` on that field
  - for `OAUTH`, put that field in `account_fields`
  - for static auth (`BASIC`, `BEARER`, `API_KEY`), put that field in `fields`
  - use the same field name in `proxy_url`

Example field for a path placeholder:

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

If a path parameter appears in `proxy_url`, tell the user where to send its runtime value when creating or updating a connected account:
- for static auth (`BASIC`, `BEARER`, `API_KEY`), put it in `connected_account.authorization_details.static_auth.details.path_variables`
- for `OAUTH`, put it in `connected_account.api_config.path_variables`

If the exact key names are unclear, ask the user to confirm them.

## Auth Header Customization

Only add these fields when the upstream docs require them.

### `auth_header_key_override`

Use this when the upstream expects the auth credential in a header other than `Authorization`.

Example:

```json
"auth_header_key_override": "x-api-key"
```

### `auth_field_mutations`

Use this when the upstream expects the raw credential to be transformed before proxy formatting:
- `prefix`: prepend text to the stored value
- `suffix`: append text to the stored value
- `default`: use this value when the stored value is empty

Supported mutation targets:
- `api_key`
- `token`
- `username`
- `password`

Mutation order:
- apply `default` if the stored value is empty
- then prepend `prefix`
- then append `suffix`
- for `BEARER`, the proxy adds `Bearer ` after mutation
- for `BASIC`, the proxy base64-encodes `username:password` after mutation

Examples:

Zendesk-style Basic auth:

```json
"auth_field_mutations": {
  "username": {
    "suffix": "/token"
  }
}
```

Freshdesk-style Basic auth:

```json
"auth_field_mutations": {
  "password": {
    "default": "X"
  }
}
```

Klaviyo-style API key auth:

```json
"auth_field_mutations": {
  "api_key": {
    "prefix": "Klaviyo-API-Key "
  }
}
```

Harvest-style API key auth:

```json
{
  "auth_header_key_override": "x-api-key"
}
```

## Supported Placeholders

The backend supports:
- `{{domain}}`
- `{{version}}`
- named placeholders for path parameters, where the placeholder name matches a provider field marked with `is_path_param: true`

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

4. URL with named path parameter

```json
"proxy_url": "https://api.example.com/resources/{{path_param_1}}"
```

When responding, state why the chosen shape is correct.

If you use named path placeholders in `proxy_url`, also tell the user how to pass `path_variables` during connected account create or update.

For static auth, the structure is:

```json
{
  "identifier": "some-identifier",
  "connector": "mycustomprovider",
  "connected_account": {
    "authorization_details": {
      "static_auth": {
        "details": {
          "...": "...",
          "path_variables": {
            "path_param_1": "value_1"
          }
        }
      }
    }
  }
}
```

For OAuth, the structure is:

```json
{
  "identifier": "some-identifier",
  "connector": "myoauthcustomconnector",
  "connected_account": {
    "authorization_details": {
      "oauth_token": {}
    },
    "api_config": {
      "...": "...",
      "path_variables": {
        "path_param_1": "value_1"
      }
    }
  }
}
```

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
   - target environment: `Dev` or `Production`
   - inferred auth type
   - tracked fields
   - proxy URL choice
2. for `Dev`, the generated provider JSON; for `Production`, the provider JSON fetched from `Dev`
3. for updates:
   - in `Dev`, a field diff table covering only `display_name`, `description`, `auth_patterns`, `proxy_url`, and `proxy_enabled`
   - in `Production`, a tabular diff covering only `display_name`, `description`, `auth_patterns`, `proxy_url`, and `proxy_enabled` with columns `Dev`, `Current Production`, and `Proposed`
4. action
   - in `Dev`, say whether you will run create or update after approval
   - in `Production`, print the create or update curl and tell the user to run it themselves; mention that you used Production credentials only for token generation, provider lookup, and curl construction, and that the printed curl includes the Production access token after `Bearer `
5. short note about assumptions, placeholders, or missing Dev access

## Curl Instructions

HTTP method rules:
- create is always `POST`
- update is always `PUT`
- get or list is always `GET`
- delete is always `DELETE`

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
curl --location --request GET '{{SCALEKIT_ENVIRONMENT_URL}}/api/v1/providers?filter.provider_type=CUSTOM&page_size=1000' \
--header 'Authorization: Bearer {{env_access_token}}'
```

### Create

In `Dev`, only after explicit user approval, run:

```bash
curl --location --request POST '{{SCALEKIT_ENVIRONMENT_URL}}/api/v1/custom-providers' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{env_access_token}}' \
--data '{
  ...generated-json...
}'
```

After create, tell the user: Refresh the page on Scalekit Dashboard to see the new provider.

In `Production`, never run the create curl. Print the fully resolved curl and tell the user to run it from their terminal. The printed curl must use the Production access token in `Authorization: Bearer <production-env-access-token>`.

### Update

In `Dev`, before running the update curl:
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
curl --location --request PUT '{{SCALEKIT_ENVIRONMENT_URL}}/api/v1/custom-providers/{{identifier}}' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer {{env_access_token}}' \
--data '{
  ...generated-json...
}'
```

After update, tell the user: Refresh the page on Scalekit Dashboard to see the new provider.

In `Production`:
- never regenerate the provider JSON from scratch when the matching `Dev` provider exists
- fetch the matching provider from `Dev` and use that provider JSON as the payload
- use Production credentials to generate a Production token and list Production providers
- list Production providers to determine whether the action is create or update
- if update is needed, resolve the provider identifier from `providers[] -> matching object -> identifier`
- if update is needed, show a tabular diff with columns `Dev`, `Current Production`, and `Proposed` for `display_name`, `description`, `auth_patterns`, `proxy_url`, and `proxy_enabled`
- print the fully resolved create or update curl only and never execute it
- ensure the printed create or update curl uses the Production access token in `Authorization: Bearer <production-env-access-token>`
- tell the user to review the provider JSON and run the printed curl from their terminal

Do not fabricate identifiers.

### Delete

If the user asks to delete the custom provider:
- run the list providers curl
- read `providers[]`
- find the matching provider object
- use its `identifier` field, not its `id` field
- print the delete curl only and never execute it
- when printing it, replace `SCALEKIT_ENVIRONMENT_URL` and `env_access_token` with the actual values already available in the conversation
- for Production deletes, use the Production access token in `Authorization: Bearer <production-env-access-token>`
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
- for `Production` updates, the diff table includes `Dev`, `Current Production`, and `Proposed` columns
- for updates, OAuth scope removals or additions are called out explicitly when present
- for updates, the user is warned that existing connections may need to be recreated and connected accounts may need reauthorization
- in `Production`, the skill asks for Dev credentials if they were not provided
- in `Production`, the skill asks for Production credentials if they were not provided
- in `Production`, the skill fetches the matching Dev provider before preparing the Production curl
- in `Production`, the skill does not regenerate the provider JSON from scratch when the Dev provider exists
- in `Production`, the skill may run token and list-provider curls but never create, update, or delete curls
- printed Production create, update, and delete curls include the Production access token after `Bearer `
- printed create curls use `POST`, printed update curls use `PUT`, printed list curls use `GET`, and printed delete curls use `DELETE`
- create runs only after explicit user approval
- update runs only after explicit user confirmation
- in `Production`, create and update curls are printed but never executed
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
