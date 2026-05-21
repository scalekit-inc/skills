---
name: production-readiness-agentkit
description: Validates OAuth token flows, audits token storage security, verifies per-connector authorization, and checks monitoring configuration for Scalekit AgentKit implementations before production launch. Use when going live, doing a pre-launch review, or verifying AgentKit authorization and tool-calling setup is production-ready.
---

# Scalekit AgentKit Production Readiness

Work through each section in order — earlier sections are blockers for later ones.

---

## Quick checks (run first)

```bash
# Confirm production credentials are set (not dev/staging)
echo $SCALEKIT_ENV_URL    # should be https://<subdomain>.scalekit.com (not .scalekit.dev)
echo $SCALEKIT_CLIENT_ID  # should be set
echo $SCALEKIT_CLIENT_SECRET  # should be set

# Verify token endpoint works
curl -s -o /dev/null -w "%{http_code}" -X POST "$SCALEKIT_ENV_URL/oauth/token" \
  -d "client_id=$SCALEKIT_CLIENT_ID&client_secret=$SCALEKIT_CLIENT_SECRET&grant_type=client_credentials"
# Expected: 200
```

- [ ] HTTPS enforced on all auth endpoints
- [ ] API credentials in environment variables — `grep -r "skc_" src/` returns nothing
- [ ] Redirect URIs registered in dashboard match exactly what the app sends

---

## OAuth token flows

- [ ] Test authorization URL generation with correct scopes
- [ ] Validate `state` parameter in callbacks (CSRF protection)
- [ ] Test authorization code exchange for access + refresh tokens
- [ ] Verify access tokens are stored securely (not in localStorage or logs)
- [ ] Test automatic token refresh before expiry
- [ ] Verify token refresh handles concurrent requests correctly (no race conditions)
- [ ] Test behavior when refresh token expires — user prompted to re-authorize
- [ ] Verify revocation on logout clears stored tokens

**Per connected service:**
- [ ] Test OAuth flow end-to-end for each service (Gmail, Slack, Notion, etc.)
- [ ] Verify correct scopes requested — request minimum required
- [ ] Test API calls with valid access token succeed
- [ ] Test API calls with expired token trigger refresh correctly
- [ ] Test behavior on permission denied (user revoked access in the third-party app)

---

## Security

- [ ] Access tokens never logged or exposed in error messages
- [ ] Refresh tokens stored encrypted at rest
- [ ] Token storage scoped per user — no cross-user token access possible
- [ ] Webhook/callback endpoint validates signatures (if applicable)

---

## Monitoring and incident readiness

- [ ] Auth logs monitoring configured in **Dashboard > Auth Logs**
- [ ] Error tracking configured for OAuth failures and token refresh errors
- [ ] Alerts configured for repeated authorization failures
- [ ] Log retention policies configured
- [ ] Incident response runbook written (who to contact, how to revoke compromised tokens)

**Key metrics:** Token refresh success/failure rate, OAuth completion rate (initiated vs completed), per-service API error rates, token expiry distribution.

## Final smoke test

Run the full cycle in staging with production credentials:
1. Create a connected account for a test user → verify status returned
2. Generate auth link → complete OAuth → verify status is `ACTIVE`
3. Fetch access token → make a downstream API call → verify success
4. Wait for token expiry → re-fetch → verify auto-refresh works
5. Revoke access in the third-party app → verify graceful error handling
