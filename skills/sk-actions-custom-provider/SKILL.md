---
name: sk-actions-custom-provider
description: Create or review Scalekit custom providers/connectors for proxy-only usage, including MCP providers. Use this skill when the task is to gather API docs, infer whether a connector is OAuth, Basic, Bearer, or API Key, determine if it is an MCP provider, determine required tracked fields like domain or version, generate provider JSON, check for existing custom providers, show update diffs, run approved create or update curls, and print resolved delete curls.
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

See `references/INTERACTION-FLOW.md` for the full step-by-step sequence. Key points:

1. **Start**: Ask `Dev` or `Production`
2. **Dev**: Collect credentials + provider name → generate token → list existing providers → infer auth type from docs → generate JSON → create/update after approval
3. **Production**: Collect both Dev + Production credentials → fetch Dev provider as source of truth → compare with Production → print curl for user to run (never execute)
4. **Delete**: Resolve `identifier` from list response → print delete curl for user to run
5. If provider exists, ask update vs create
6. Infer auth type (`OAUTH`/`BASIC`/`BEARER`/`API_KEY`) from docs; for MCP OAuth, `oauth_config: {"pkce_enabled": true}` only
7. Inspect docs for tracked fields, auth header overrides, and `auth_field_mutations`
8. Generate final JSON

### Update mode:
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
- `oauth_config` for OAuth only; for MCP OAuth providers, always set to `{"pkce_enabled": true}` with no other fields
- `is_mcp` set to `true` for MCP providers; omit for non-MCP providers
- `auth_header_key_override` when the upstream auth header key is not `Authorization`
- `auth_field_mutations` when the upstream requires a prefix, suffix, or default on `api_key`, `token`, `username`, or `password`

Supported field input types:
- `text`
- `password`
- `select`

Defaults: `proxy_enabled: true`, `proxy_url` must not be empty (tool calling requires it), auth header stays `Authorization` unless docs require override, no `auth_field_mutations` unless docs require them.

## Provider Types and Examples

See `references/PROVIDER-EXAMPLES.md` for complete JSON examples of all 4 provider types (OAuth, Basic, Bearer, API Key) and MCP variants.

**Quick reference:**

| Type | `auth_patterns[].type` | Key fields | Runtime |
|------|----------------------|------------|---------|
| OAuth | `OAUTH` | `oauth_config` with endpoints and scopes | Standard OAuth 2.0 flow |
| Basic | `BASIC` | `username`, `password` | `Authorization: Basic base64(u:p)` |
| Bearer | `BEARER` | `token` | `Authorization: Bearer <token>` |
| API Key | `API_KEY` | `api_key` | `Authorization: <key>` (raw) |

**MCP rules:** Set `is_mcp: true` in all `auth_patterns[]`. For MCP OAuth, `oauth_config` must be `{"pkce_enabled": true}` only — no `authorize_uri`/`token_uri`/`user_info_uri` (uses DCR).

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

If the exact key names are unclear, ask the user to confirm them. For connected account payload structures with `path_variables`, see `references/PROVIDER-EXAMPLES.md`.

## Auth Header Customization

Only add when upstream docs require it. See `references/PROVIDER-EXAMPLES.md` for full details.

- `auth_header_key_override`: when upstream uses a header key other than `Authorization` (e.g., `x-api-key`)
- `auth_field_mutations`: when upstream needs `prefix`, `suffix`, or `default` on `api_key`/`token`/`username`/`password`
- Mutation order: apply `default` → prepend `prefix` → append `suffix` → then proxy adds its format (`Bearer ` or base64)

## Supported Placeholders

The backend supports:
- `{{domain}}`
- `{{version}}`
- named placeholders for path parameters, where the placeholder name matches a provider field marked with `is_path_param: true`

Use placeholders only when the API contract requires them.

## Proxy URL Patterns

| Pattern | Example |
|---------|---------|
| Fixed | `https://api.example.com` |
| Tenant domain | `https://{{domain}}/api` |
| Versioned | `https://api.example.com/{{version}}` |
| Path param | `https://api.example.com/resources/{{path_param_1}}` |

State why the chosen shape is correct. For `path_variables` payload structures, see `references/PROVIDER-EXAMPLES.md`.

## Missing Info

Before generating JSON, summarize confirmed/assumed/missing values. If critical auth details are missing, stop and ask. If docs are too vague, ask for the API auth reference.

## Output Format

Respond in order: (1) summary (environment, auth type, tracked fields, proxy URL), (2) provider JSON, (3) diff table for updates, (4) action (run curl in Dev; print curl in Production), (5) assumptions note.

## Curl Templates

```bash
# Token (run first)
curl --location '{{env_url}}/oauth/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id={{client_id}}' \
--data-urlencode 'client_secret={{client_secret}}'

# List providers
curl -X GET '{{env_url}}/api/v1/providers?filter.provider_type=CUSTOM&page_size=1000' \
-H 'Authorization: Bearer {{token}}'

# Create (POST) — Dev only, after explicit approval
curl -X POST '{{env_url}}/api/v1/custom-providers' \
-H 'Content-Type: application/json' -H 'Authorization: Bearer {{token}}' \
-d '{ ...json... }'

# Update (PUT) — Dev only, after diff review + confirmation
curl -X PUT '{{env_url}}/api/v1/custom-providers/{{identifier}}' \
-H 'Content-Type: application/json' -H 'Authorization: Bearer {{token}}' \
-d '{ ...json... }'

# Delete — NEVER execute; print resolved curl for user to run
curl -X DELETE '{{env_url}}/api/v1/custom-providers/{{identifier}}' \
-H 'Authorization: Bearer {{token}}'
```

**Key rules:** Always use `identifier` (not `id`) from the list response. In Production, never execute create/update/delete — print the resolved curl. Label executed curls with `✅`/`❌`. After any mutation, tell user to refresh Scalekit Dashboard.

**Update flow:** Show diff table (`display_name`, `description`, `auth_patterns`, `proxy_url`, `proxy_enabled`). Warn about scope changes and that existing connections/connected accounts may need recreation.

**Delete failures:** If delete fails due to existing connections, tell user to remove connections and connected accounts from Dashboard first.

## Review Checklist

- [ ] `display_name` safe and under 200 chars
- [ ] Auth type matches upstream docs
- [ ] MCP providers: `is_mcp: true` in all auth patterns
- [ ] MCP OAuth: `oauth_config` is `{"pkce_enabled": true}` only
- [ ] `oauth_config` exists only for OAuth providers
- [ ] `proxy_url` not empty; `proxy_enabled: true`
- [ ] Tracked fields are concrete and minimal
- [ ] Placeholders used only when needed
- [ ] For updates: diff table shown; scope changes called out; connection recreation warning given
- [ ] For Production: Dev provider JSON used as source of truth (never regenerated from scratch)
- [ ] For Production: create/update/delete curls printed, never executed
- [ ] `identifier` from list response used (not `id`); never fabricated
