---
name: migrating-to-saaskit
description: Audits the existing auth system, exports users and orgs, imports them into Scalekit via SDK, configures redirects and roles, and deploys with a gradual rollout behind a feature flag. Use when a user mentions migrating, switching, or moving away from their current auth provider (Auth0, Firebase, Cognito, custom).
---

# Scalekit Auth Migration Planner

Guides an incremental, reversible migration from an existing auth system to Scalekit. Follow these phases in order—do not skip phases.

## Migration checklist

Copy and track progress:

```
Migration Progress:
- [ ] Phase 1: Audit and export existing auth data
- [ ] Phase 2: Import organizations and users into Scalekit
- [ ] Phase 3: Configure redirects and roles
- [ ] Phase 4: Update application code
- [ ] Phase 5: Deploy and monitor
```

---

## Phase 1: Audit and export

Conduct a code audit covering:
- Sign-up/login flows, session middleware, token validation
- RBAC logic, email verification, logout/session termination

Export the following data:
- User records (email, name, `email_verified`)
- Org/tenant structure
- Role assignments and permissions
- SSO/IdP provider configs

**Backup checklist before proceeding:**
- [ ] Export a sample JWT or session cookie (understand current format)
- [ ] Set up a feature flag to roll back to old auth system
- [ ] Document rollback procedure

Minimum user schema:

| Field | Required |
|---|---|
| `email` | Required |
| `first_name` | Optional |
| `last_name` | Optional |
| `email_verified` | Optional (defaults `false`) |

See [AUDIT-CHECKLIST.md](AUDIT-CHECKLIST.md) for full code audit patterns.

---

## Phase 2: Import organizations and users

`external_id` is critical—store original PKs here to preserve system-to-system mappings.

**Step 1: Create organizations first**

Node.js example:
```javascript
const result = await scalekit.organization.createOrganization(
  org.display_name,
  { externalId: org.external_id, metadata: org.metadata }
);
```

**Step 2: Create users within organizations**

```javascript
const { user } = await scalekit.user.createUserAndMembership("org_scalekit_id", {
  email: "user@example.com",
  externalId: "usr_987",
  userProfile: { firstName: "John", lastName: "Doe" },
});
```

**Rules:**
- Set `sendInvitationEmail: false` during import to skip invite emails; membership auto-activates and email is marked verified
- Batch imports in parallel; respect Scalekit rate limits
- Validate `external_id` mappings match source data exactly

For language-specific samples (Python, Go, Java, cURL): See [IMPORT-SAMPLES.md](IMPORT-SAMPLES.md).

---

## Phase 3: Configure redirects and roles

**Redirects:**
- Register callback URLs in **Settings → Redirects** in Scalekit dashboard
- Add post-logout URLs to control destination after logout

**Roles:**
- Define roles under **User Management → Roles** or via SDK
- During user import, include `roles` array inside the `membership` object
- Verify role claims are readable from the token after login

---

## Phase 4: Update application code

**Session middleware:** Replace legacy JWT validation with Scalekit SDK or JWKS endpoint.

Verify:
- [ ] Access tokens accepted on all protected routes
- [ ] Refresh token renewal works seamlessly
- [ ] `roles` claim from Scalekit tokens used for RBAC checks

**Login page:** Update logo, colors, copy, and legal links in Scalekit dashboard under Branding.

**Secondary flows to update:**
- Email verification prompt
- Logout redirect destination

---

## Phase 5: Deploy and monitor

**Pre-deployment:**
- [ ] Test login with a subset of migrated users
- [ ] Verify session creation, validation, and expiry
- [ ] Confirm role-based access works end-to-end

**Deployment sequence:**
1. Deploy updated application code
2. Enable feature flag → route traffic to Scalekit
3. Start at 5–10% of users; expand after stability confirmed
4. Monitor auth success rates and error logs
5. Keep rollback plan active for first 48 hours

**Post-deployment verification:**

```bash
# Verify token endpoint works with Scalekit credentials
curl -s -o /dev/null -w "%{http_code}" -X POST "$SCALEKIT_ENV_URL/oauth/token" \
  -d "client_id=$SCALEKIT_CLIENT_ID&client_secret=$SCALEKIT_CLIENT_SECRET&grant_type=client_credentials"
# Expected: 200

# Verify a migrated user can be looked up
curl -s -H "Authorization: Bearer $TOKEN" "$SCALEKIT_ENV_URL/api/v1/organizations/<org_id>/users?email=migrated-user@example.com" | jq .
# Should return the user with correct external_id
```

Monitor: auth error rates, session creation/validation, SSO connection health, user-reported issues.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Users can't log in | Verify callback URLs registered; check `external_id` mappings; ensure emails match exactly |
| Session validation fails | Switch JWT validation to Scalekit JWKS endpoint; verify token expiry/refresh logic |
| SSO not working | Confirm org has SSO enabled; verify IdP config; test IdP-initiated login |

> **Note:** Password migration support is coming. If required, contact Scalekit's Solutions team.
