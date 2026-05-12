---
name: production-readiness-saaskit
description: Walks through a structured production readiness checklist for Scalekit SaaSKit implementations covering authentication, SSO, SCIM, MCP server auth, and API security. Use when going live, launching to production, or doing a pre-launch review.
---

# SaaSKit Production Readiness

Unified checklist for all SaaSKit domains. Work through in order — skip sections that don't apply.

## Quick checks (run first)

- [ ] Production env URL, client ID, and client secret set (not dev/staging)
- [ ] HTTPS enforced; CORS restricted to your domains only
- [ ] All credentials in environment variables — never committed to code
- [ ] Webhook secret stored in environment variables (if using webhooks)
- [ ] Only enabled auth methods active in production

## Customization

- [ ] Login page branded; email templates customized
- [ ] Email provider configured in **Dashboard > Customization > Emails**
- [ ] Custom domain configured (if applicable); email deliverability tested
- [ ] Webhooks configured with signature validation

## Core auth flows

- [ ] Login initiation, code exchange, and redirect URLs match dashboard exactly
- [ ] `state` parameter validated in callbacks (CSRF); tokens stored with `httpOnly`, `secure`, `sameSite`
- [ ] Token lifetimes configured for your security requirements
- [ ] Token refresh and session timeout working; logout calls Scalekit end-session
- [ ] Each enabled auth method tested; errors handled gracefully
- [ ] Complete end-to-end flow validated in staging before production

**Test each enabled auth method:**
- [ ] Email/password: sign-up, login, password reset
- [ ] Magic links: initiation, delivery, redemption, expiry
- [ ] Social logins: each configured provider (Google, Microsoft, GitHub, etc.)
  → Provider setup guides: https://docs.scalekit.com/guides/integrations/social-connections/
- [ ] Passkeys: registration, authentication, fallback
- [ ] Auth method selection UI renders correctly
- [ ] Fallback scenarios when an auth method fails

**Error handling:**
- [ ] Expired tokens handled gracefully
- [ ] Invalid authorization codes rejected
- [ ] Network failures show user-friendly messages

## SSO (if applicable)

- [ ] SSO tested with target IdPs (Okta, Azure AD, Google Workspace)
  → IT admin setup guides per IdP: https://docs.scalekit.com/guides/integrations/sso-integrations/
- [ ] Configure user attribute mapping (email, name, groups)
- [ ] SP-initiated and IdP-initiated flows both working
- [ ] Verify SSO error handling for misconfigured connections
- [ ] Test SSO with: new users, existing users, deactivated users
- [ ] Admin portal configured for self-serve SSO setup
- [ ] JIT provisioning: domains registered, default roles set, attribute sync enabled
- [ ] Configure consistent user identifiers across SSO connections (email or userPrincipalName)
- [ ] Plan manual invitation process for contractors/external users with non-matching domains
- [ ] Set up review process for automatically provisioned users

## SCIM provisioning (if applicable)

- [ ] Webhook endpoints receiving events with signature validation
- [ ] User provisioning, deprovisioning, and profile updates tested
- [ ] Group-based role sync working; idempotent handling verified
- [ ] Test error cases: duplicate users, invalid data, missing required fields
- [ ] Deactivation preferred over hard deletion for `user_deleted` events
- [ ] Webhook endpoint returns 2xx quickly — offload heavy processing to a queue if needed
- [ ] Scalekit retries on non-2xx with exponential backoff (up to 8 attempts over ~10 hours)
- [ ] Tested webhook delivery end-to-end with a real IdP or Scalekit's test tool

## MCP authentication (if applicable)

- [ ] MCP auth flow tested end-to-end; resource metadata published at `/.well-known/oauth-protected-resource`
- [ ] Verify OAuth consent screen displays correctly for MCP clients
- [ ] Scopes enforced per tool; client reconnection after token expiry working
- [ ] Test MCP session management (session creation, expiry, refresh)
- [ ] Verify custom auth handlers behave correctly (if using)

## RBAC (if applicable)

- [ ] Roles and permissions defined; default roles set for new users
- [ ] Test role assignment to users and org members
- [ ] Permission enforcement verified at API endpoints
- [ ] Test access control across all role levels

## User and organization management (if applicable)

- [ ] Configure profile fields collected at sign-up
- [ ] Test invitation flow and email templates
- [ ] Test user deletion flow
- [ ] Test organization creation and domain assignment
- [ ] Test adding and removing users from organizations
- [ ] Set allowed email domains for org sign-ups (if applicable)
- [ ] Verify organization switching for users in multiple orgs

## Network / firewall

Enterprise VPN customers must whitelist: `<your-env>.scalekit.com`, `cdn.scalekit.com`, `fonts.googleapis.com`.

- [ ] Customer firewalls allow Scalekit domains
- [ ] SSO and SCIM tested from customer's network environment

## Monitoring

- [ ] Auth logs monitoring active; alerts for suspicious activity configured
- [ ] Webhook monitoring active; error tracking for auth and provisioning failures
- [ ] Log retention policies configured
- [ ] Webhook delivery and retry mechanism tested
- [ ] Incident response runbook written; rollback plan ready (feature flag)
- **Key metrics:** login success/failure rates, sign-up conversion, session duration, token refresh frequency, webhook delivery rate, SSO completion rate, MCP auth success rate, provisioning/deprovisioning latency
