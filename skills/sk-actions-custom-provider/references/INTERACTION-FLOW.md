# Interaction Flow

Follow this sequence exactly.

## Step 1 — Opening

Send this message once:

```text
Share:
- Is this Scalekit environment Dev or Production?

This skill is only for proxy-only connectors.
```

## Step 2 — Branch on environment

**Dev:** Ask for `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`, custom provider name, whether this is an MCP provider, API docs link, auth docs link if separate, and base API URL or full MCP URL (this becomes `proxy_url`).

**Production:** Ask for both Dev and Production credentials (`PROD_SCALEKIT_ENVIRONMENT_URL`, `PROD_SCALEKIT_CLIENT_ID`, `PROD_SCALEKIT_CLIENT_SECRET`, `DEV_SCALEKIT_ENVIRONMENT_URL`, `DEV_SCALEKIT_CLIENT_ID`, `DEV_SCALEKIT_CLIENT_SECRET`) and the provider name to replicate.

## Steps 3-6 — Dev setup

3. Use `SCALEKIT_ENVIRONMENT_URL` as `env_url`
4. Generate `env_access_token`:
```bash
curl --location '{{env_url}}/oauth/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id={{client_id}}' \
--data-urlencode 'client_secret={{client_secret}}'
```
5. List existing custom providers:
```bash
curl --location '{{env_url}}/api/v1/providers?filter.provider_type=CUSTOM&page_size=1000' \
--header 'Authorization: Bearer {{env_access_token}}'
```
6. Compare the provided name against existing providers

## Step 7 — Production flow

- Collect Dev + Production credentials if not already provided
- Generate Dev token, list Dev providers, find matching provider
- If no matching Dev provider: stop — cannot prepare Production curl without Dev source of truth
- Use Dev provider JSON as source of truth (never regenerate from scratch)
- Ask user to review the Dev provider JSON
- Generate Production token, list Production providers
- If exists in Production: resolve `identifier`, build diff table (`Dev` | `Current Production` | `Proposed`), print update curl
- If new: print create curl
- Tell user to run the printed curl from their terminal
- Never execute create/update/delete in Production

## Step 8 — Delete mode

If user requests deletion at any point:
- Find matching provider in list response
- Use `identifier` field (not `id`)
- Print resolved delete curl with actual env URL and token
- Ask user to run it from their terminal
- If delete fails due to existing connections: tell user to remove connections/connected accounts from Dashboard first
- Stop — do not continue into create or update

## Steps 9-11 — Existing provider handling

9. If provider already exists: ask "update existing or create new?"
10. Update → reuse existing provider, continue in update mode
11. Create → continue in create mode

## Steps 12-17 — Auth type inference

12. Read docs, infer auth type: `OAUTH`, `BASIC`, `BEARER`, `API_KEY`
13. If unclear, ask user to choose
14. For non-MCP OAuth: discover `authorize_uri`, `token_uri`, `user_info_uri`, scopes
15. For MCP OAuth: skip — only needs `oauth_config: {"pkce_enabled": true}`
16. Ask for any missing OAuth values

## Steps 18-20 — Tracked fields and auth customization

18. Inspect docs for tracked fields: `token`, `api_key`, `username`, `password`, `domain`, `version`, named path parameters
19. Inspect docs for auth header behavior: `auth_header_key_override` and `auth_field_mutations`
20. For named path parameters, ask for exact field names if unclear

## Steps 21-22 — Generate

21. Determine correct `proxy_url`
22. Generate final provider JSON

## Steps 23-24 — Finalize

**Update mode:** Show diff table, call out scope changes, warn about connection recreation, resolve `identifier` from list response, ask for confirmation, run update curl after confirmation.

**Create mode:** Ask for explicit approval, run create curl after approval.

After any mutation: tell user to refresh Scalekit Dashboard.