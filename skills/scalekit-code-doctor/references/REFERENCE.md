# Scalekit API Reference — Compact Lookup

This file contains every correct SDK method signature and REST endpoint. Use it as ground truth when generating or reviewing Scalekit code. If a method isn't listed here, do NOT assume it exists — verify against the live SDK source or `https://docs.scalekit.com/apis.md`.

---

## Client Initialization

### Node.js (`@scalekit-sdk/node`)

```typescript
import { ScalekitClient } from '@scalekit-sdk/node';

const scalekit = new ScalekitClient(
  process.env.SCALEKIT_ENV_URL!,       // string — environment URL
  process.env.SCALEKIT_CLIENT_ID!,     // string — client ID
  process.env.SCALEKIT_CLIENT_SECRET!  // string — client secret
);
```

### Python (`scalekit-sdk-python`)

```python
from scalekit import ScalekitClient

scalekit_client = ScalekitClient(
    os.environ.get('SCALEKIT_ENV_URL'),       # str — environment URL
    os.environ.get('SCALEKIT_CLIENT_ID'),     # str — client ID
    os.environ.get('SCALEKIT_CLIENT_SECRET')  # str — client secret
)
```

### Go (`github.com/scalekit-inc/scalekit-sdk-go`)

```go
import scalekit "github.com/scalekit-inc/scalekit-sdk-go/v2"

client := scalekit.NewScalekitClient(
    os.Getenv("SCALEKIT_ENV_URL"),       // string — environment URL
    os.Getenv("SCALEKIT_CLIENT_ID"),     // string — client ID
    os.Getenv("SCALEKIT_CLIENT_SECRET"), // string — client secret
)
```

### Java (`com.scalekit:scalekit-sdk-java`)

```java
import com.scalekit.ScalekitClient;

ScalekitClient client = new ScalekitClient(
    System.getenv("SCALEKIT_ENV_URL"),       // String — environment URL
    System.getenv("SCALEKIT_CLIENT_ID"),     // String — client ID
    System.getenv("SCALEKIT_CLIENT_SECRET")  // String — client secret
);
```

---

## Environment Variables

| Variable | Purpose | Format |
|----------|---------|--------|
| `SCALEKIT_ENV_URL` | Environment URL | `https://<subdomain>.scalekit.com` (prod) or `https://<subdomain>.scalekit.dev` (dev) |
| `SCALEKIT_CLIENT_ID` | Client ID | String from dashboard |
| `SCALEKIT_CLIENT_SECRET` | Client secret | String from dashboard |
| `SCALEKIT_REDIRECT_URI` | OAuth callback URL | Must exactly match dashboard config |
| `SCALEKIT_WEBHOOK_SECRET` | Webhook signing secret | Format: `whsec_...` |

Note: The REST API docs use `SCALEKIT_ENVIRONMENT_URL` in some examples. Both `SCALEKIT_ENV_URL` and `SCALEKIT_ENVIRONMENT_URL` are acceptable — just be consistent within a project.

---

## Auth Methods (called directly on the client)

### Node.js

| Method | Signature | Returns |
|--------|-----------|---------|
| `getAuthorizationUrl` | `(redirectUri: string, options?: AuthorizationUrlOptions) → string` | Authorization URL string |
| `authenticateWithCode` | `(code: string, redirectUri: string, options?: AuthenticationOptions) → Promise<AuthenticationResponse>` | Tokens + user info |
| `getIdpInitiatedLoginClaims` | `(idpInitiatedLoginToken: string, options?: TokenValidationOptions) → Promise<IdpInitiatedLoginClaims>` | IDP login claims |
| `validateAccessToken` | `(token: string, options?: TokenValidationOptions) → Promise<boolean>` | Boolean |
| `validateToken` | `(token: string, options?: TokenValidationOptions) → Promise<T>` | Decoded JWT payload |
| `verifyScopes` | `(token: string, requiredScopes: string[]) → boolean` | Boolean |
| `getLogoutUrl` | `(options?: LogoutUrlOptions) → string` | Logout URL string |
| `refreshAccessToken` | `(refreshToken: string) → Promise<RefreshTokenResponse>` | New tokens |
| `verifyWebhookPayload` | `(secret: string, headers: Record<string, string>, payload: string) → boolean` | Boolean |
| `verifyInterceptorPayload` | `(secret: string, headers: Record<string, string>, payload: string) → boolean` | Boolean |

**AuthorizationUrlOptions**: `scopes?: string[]`, `state?: string`, `nonce?: string`, `loginHint?: string`, `domainHint?: string`, `connectionId?: string`, `organizationId?: string`, `provider?: string`, `codeChallenge?: string`, `codeChallengeMethod?: string`, `prompt?: string`

**LogoutUrlOptions**: `idTokenHint?: string`, `postLogoutRedirectUri?: string`, `state?: string`

**AuthenticationOptions**: `codeVerifier?: string`

### Python

| Method | Signature | Returns |
|--------|-----------|---------|
| `get_authorization_url` | `(redirect_uri: str, options?: AuthorizationUrlOptions) → str` | Authorization URL string |
| `authenticate_with_code` | `(code: str, redirect_uri: str, options?: CodeAuthenticationOptions) → dict` | Tokens + user info |
| `get_idp_initiated_login_claims` | `(idp_initiated_login_token: str, options?: TokenValidationOptions) → IdpInitiatedLoginClaims` | IDP login claims |
| `validate_access_token` | `(token: str, options?: TokenValidationOptions) → bool` | Boolean |
| `get_logout_url` | `(options?: LogoutUrlOptions) → str` | Logout URL string |
| `refresh_access_token` | `(refresh_token: str) → dict` | New tokens |
| `verify_webhook_payload` | `(secret: str, headers: Dict[str, str], payload: str\|bytes) → bool` | Boolean |

**AuthorizationUrlOptions** (Python): `scopes`, `state`, `nonce`, `login_hint`, `domain_hint`, `connection_id`, `organization_id`, `provider`, `prompt` — all `Optional[str]` (scopes is `Optional[list[str]]`)

**LogoutUrlOptions** (Python): `id_token_hint`, `post_logout_redirect_uri`, `state` — all `Optional[str]`

### Go

| Method | Signature | Returns |
|--------|-----------|---------|
| `GetAuthorizationUrl` | `(redirectUri string, options AuthorizationUrlOptions) → (*url.URL, error)` | URL + error |
| `AuthenticateWithCode` | `(ctx context.Context, code string, redirectUri string, options AuthenticationOptions) → (*AuthenticationResponse, error)` | Response + error |
| `GetIdpInitiatedLoginClaims` | `(ctx context.Context, idpInitiatedLoginToken string) → (*IdpInitiatedLoginClaims, error)` | Claims + error |
| `GetAccessTokenClaims` | `(ctx context.Context, accessToken string) → (*AccessTokenClaims, error)` | Claims + error |
| `ValidateAccessToken` | `(ctx context.Context, accessToken string) → (bool, error)` | Boolean + error |
| `RefreshAccessToken` | `(ctx context.Context, refreshToken string) → (*TokenResponse, error)` | Tokens + error |
| `GetLogoutUrl` | `(options LogoutUrlOptions) → string` | Logout URL string |
| `VerifyWebhookPayload` | `(secret string, headers map[string][]string, payload []byte) → bool` | Boolean |

**Go AuthorizationUrlOptions fields**: `Scopes []string`, `State string`, `Nonce string`, `LoginHint string`, `DomainHint string`, `ConnectionId string`, `OrganizationId string`, `Provider string`, `CodeChallenge string`, `CodeChallengeMethod string`, `Prompt string`

Note: Go methods take `context.Context` as the first parameter for network calls. `GetAuthorizationUrl` and `GetLogoutUrl` do NOT take context (they're local-only operations).

### Java

| Method | Signature | Returns |
|--------|-----------|---------|
| `getAuthorizationUrl` | `(redirectUri: String, options: AuthorizationUrlOptions) → String` | Authorization URL string |
| `authenticateWithCode` | `(code: String, redirectUri: String, options: AuthenticationOptions) → AuthenticationResponse` | Tokens + user info |
| `getIdpInitiatedLoginClaims` | `(idpInitiatedLoginToken: String) → IdpInitiatedLoginClaims` | Claims |
| `validateToken` | `(token: String) → Claims` | JWT Claims |
| `getLogoutUrl` | `(options: LogoutUrlOptions) → String` | Logout URL string |

---

## Sub-client Methods

### Node.js sub-clients (accessed via `client.<subclient>.<method>`)

**client.organization**
| Method | Signature |
|--------|-----------|
| `createOrganization` | `(name: string, options?) → Promise<CreateOrganizationResponse>` |
| `getOrganization` | `(id: string) → Promise<GetOrganizationResponse>` |
| `getOrganizationByExternalId` | `(externalId: string) → Promise<GetOrganizationResponse>` |
| `listOrganizations` | `(options?) → Promise<ListOrganizationsResponse>` |
| `updateOrganization` | `(id: string, organization) → Promise<UpdateOrganizationResponse>` |
| `deleteOrganization` | `(id: string) → Promise<void>` |
| `generatePortalLink` | `(organizationId: string, features?) → Promise<GeneratePortalLinkResponse>` |
| `updateOrganizationSettings` | `(id: string, settings) → Promise<UpdateOrganizationSettingsResponse>` |

**client.connection**
| Method | Signature |
|--------|-----------|
| `getConnection` | `(id: string) → Promise<GetConnectionResponse>` |
| `listConnections` | `(options?) → Promise<ListConnectionsResponse>` |
| `listConnectionsByDomain` | `(domain: string, options?) → Promise<ListConnectionsResponse>` |
| `enableConnection` | `(connectionId: string) → Promise<void>` |
| `disableConnection` | `(connectionId: string) → Promise<void>` |

**client.domain**
| Method | Signature |
|--------|-----------|
| `createDomain` | `(domain: string) → Promise<CreateDomainResponse>` |
| `getDomain` | `(domain: string) → Promise<GetDomainResponse>` |
| `listDomains` | `(options?) → Promise<ListDomainsResponse>` |
| `deleteDomain` | `(domain: string) → Promise<void>` |

**client.user**
| Method | Signature |
|--------|-----------|
| `createUser` | `(organizationId: string, user) → Promise<CreateUserResponse>` |
| `createUserAndMembership` | `(organizationId: string, request) → Promise<CreateUserAndMembershipResponse>` |
| `getUser` | `(id: string) → Promise<GetUserResponse>` |
| `listUsers` | `(options?) → Promise<ListUsersResponse>` |
| `listOrganizationUsers` | `(organizationId: string, options?) → Promise<ListOrganizationUsersResponse>` |
| `updateUser` | `(id: string, user) → Promise<UpdateUserResponse>` |
| `deleteUser` | `(id: string) → Promise<void>` |
| `searchUsers` | `(options) → Promise<SearchUsersResponse>` |
| `searchOrganizationUsers` | `(organizationId: string, options) → Promise<SearchOrganizationUsersResponse>` |

**client.directory**
| Method | Signature |
|--------|-----------|
| `listDirectories` | `(organizationId: string) → Promise<ListDirectoriesResponse>` |
| `getDirectory` | `(organizationId: string, directoryId: string) → Promise<GetDirectoryResponse>` |
| `listDirectoryUsers` | `(organizationId: string, directoryId: string, options?) → Promise<ListDirectoryUsersResponse>` |
| `listDirectoryGroups` | `(organizationId: string, directoryId: string, options?) → Promise<ListDirectoryGroupsResponse>` |
| `enableDirectory` | `(organizationId: string, directoryId: string) → Promise<void>` |
| `disableDirectory` | `(organizationId: string, directoryId: string) → Promise<void>` |

**client.role**
| Method | Signature |
|--------|-----------|
| `createRole` | `(role) → Promise<CreateRoleResponse>` |
| `getRole` | `(roleId: string) → Promise<GetRoleResponse>` |
| `listRoles` | `(options?) → Promise<ListRolesResponse>` |
| `updateRole` | `(roleId: string, role) → Promise<UpdateRoleResponse>` |
| `deleteRole` | `(roleId: string) → Promise<void>` |

**client.permission**
| Method | Signature |
|--------|-----------|
| `createPermission` | `(permission) → Promise<CreatePermissionResponse>` |
| `listPermissions` | `(options?) → Promise<ListPermissionsResponse>` |
| `updatePermission` | `(permissionId: string, permission) → Promise<UpdatePermissionResponse>` |
| `deletePermission` | `(permissionId: string) → Promise<void>` |

**client.session**
| Method | Signature |
|--------|-----------|
| `getSession` | `(sessionId: string) → Promise<GetSessionResponse>` |
| `getUserSessions` | `(userId: string, options?) → Promise<GetUserSessionsResponse>` |
| `revokeSession` | `(sessionId: string) → Promise<void>` |
| `revokeAllUserSessions` | `(userId: string) → Promise<void>` |

**client.connectedAccounts**
| Method | Signature |
|--------|-----------|
| `listConnectedAccounts` | `(options?) → Promise<ListConnectedAccountsResponse>` |
| `getConnectedAccountAuth` | `(options) → Promise<GetConnectedAccountAuthResponse>` |
| `createConnectedAccount` | `(request) → Promise<CreateConnectedAccountResponse>` |
| `updateConnectedAccount` | `(request) → Promise<UpdateConnectedAccountResponse>` |
| `deleteConnectedAccount` | `(request) → Promise<void>` |

**client.tools**
| Method | Signature |
|--------|-----------|
| `executeTool` | `(request) → Promise<ExecuteToolResponse>` |

### Python sub-clients (accessed via `client.<subclient>.<method>`)

Python follows the same structure but with `snake_case` method names:
- `client.organization.create_organization(organization)`
- `client.organization.get_organization(organization_id)`
- `client.organization.list_organizations(page_size, page_token?)`
- `client.organization.update_organization(organization_id, organization)`
- `client.organization.delete_organization(organization_id)`
- `client.organization.generate_portal_link(organization_id, features?)`
- `client.connection.list_connections(organization_id, include?)`
- `client.connection.get_connection(organization_id, connection_id)`
- `client.connection.enable_connection(organization_id, connection_id)`
- `client.connection.disable_connection(organization_id, connection_id)`
- `client.domain.create_domain(organization_id, domain_name)`
- `client.domain.list_domains(organization_id)`
- `client.domain.delete_domain(organization_id, domain_id)`
- `client.directory.list_directories(organization_id)`
- `client.directory.get_directory(organization_id, directory_id)`
- `client.directory.list_directory_users(organization_id, directory_id, options?)`
- `client.directory.list_directory_groups(organization_id, directory_id, options?)`
- `client.user.create_user(organization_id, user)`
- `client.user.get_user(user_id)`
- `client.user.list_users(options?)`
- `client.user.update_user(user_id, user)`
- `client.user.delete_user(user_id)`
- `client.role.create_role(role)`
- `client.role.list_roles(options?)`
- `client.role.update_role(role_id, role)`
- `client.role.delete_role(role_id)`
- `client.permission.create_permission(permission)`
- `client.permission.list_permissions(options?)`
- `client.session.get_session(session_id)`
- `client.session.get_user_sessions(user_id, options?)`
- `client.session.revoke_session(session_id)`
- `client.session.revoke_all_user_sessions(user_id)`

Note: Python connection/domain/directory methods often require `organization_id` as the first parameter, unlike Node which uses option objects.

### Go sub-clients

Go uses `PascalCase` and typed request/response objects:
- `client.Organization().CreateOrganization(ctx, request)`
- `client.Organization().GetOrganization(ctx, organizationId)`
- `client.Organization().ListOrganizations(ctx, pageSize, pageToken)`
- `client.Organization().UpdateOrganization(ctx, organizationId, request)`
- `client.Organization().DeleteOrganization(ctx, organizationId)`
- `client.Organization().GeneratePortalLink(ctx, organizationId, features)`
- `client.Connection().GetConnection(ctx, organizationId, connectionId)`
- `client.Connection().ListConnections(ctx, organizationId)`
- `client.Connection().EnableConnection(ctx, organizationId, connectionId)`
- `client.Connection().DisableConnection(ctx, organizationId, connectionId)`
- `client.Domain().CreateDomain(ctx, organizationId, domainName)`
- `client.Domain().ListDomains(ctx, organizationId)`
- `client.Domain().DeleteDomain(ctx, organizationId, domainId)`
- `client.Directory().ListDirectories(ctx, organizationId)`
- `client.Directory().GetDirectory(ctx, organizationId, directoryId)`
- `client.Directory().ListDirectoryUsers(ctx, organizationId, directoryId, options)`
- `client.Directory().ListDirectoryGroups(ctx, organizationId, directoryId, options)`
- `client.User().CreateUser(ctx, organizationId, request)`
- `client.User().GetUser(ctx, userId)`
- `client.User().ListUsers(ctx, options)`
- `client.User().UpdateUser(ctx, userId, request)`
- `client.User().DeleteUser(ctx, userId)`
- `client.Role().ListRoles(ctx)`
- `client.Role().CreateRole(ctx, request)`
- `client.Session().GetSession(ctx, sessionId)`
- `client.Session().RevokeSession(ctx, sessionId)`
- `client.Session().RevokeAllUserSessions(ctx, userId)`

### Java sub-clients

Java uses accessor methods that return typed clients:
- `client.organizations().create(request) → CreateOrganizationResponse`
- `client.organizations().getById(organizationId) → Organization`
- `client.organizations().getByExternalId(externalId) → Organization`
- `client.organizations().list(pageSize, pageToken) → ListOrganizationsResponse`
- `client.organizations().update(organizationId, request) → Organization`
- `client.organizations().delete(organizationId)`
- `client.organizations().generatePortalLink(organizationId, features) → Link`
- `client.connections().listConnectionsByOrganization(organizationId) → ListConnectionsResponse`
- `client.connections().getConnection(organizationId, connectionId) → GetConnectionResponse`
- `client.connections().enableConnection(organizationId, connectionId)`
- `client.connections().disableConnection(organizationId, connectionId)`
- `client.domains().listDomainsByOrganizationId(organizationId) → ListDomainsResponse`
- `client.domains().createDomain(organizationId, domainName) → CreateDomainResponse`
- `client.domains().deleteDomain(organizationId, domainId)`
- `client.directories().listDirectories(organizationId) → ListDirectoriesResponse`
- `client.directories().getDirectory(organizationId, directoryId) → GetDirectoryResponse`
- `client.directories().listDirectoryUsers(organizationId, directoryId) → ListDirectoryUsersResponse`
- `client.directories().listDirectoryGroups(organizationId, directoryId) → ListDirectoryGroupsResponse`
- `client.users().getUser(userId) → GetUserResponse`
- `client.users().listUsers(options) → ListUsersResponse`
- `client.users().createUser(organizationId, request) → CreateUserResponse`
- `client.users().createUserAndMembership(organizationId, request) → CreateUserAndMembershipResponse`
- `client.users().updateUser(userId, request) → UpdateUserResponse`
- `client.users().deleteUser(userId)`
- `client.roles().listRoles() → ListRolesResponse`
- `client.roles().createRole(request) → CreateRoleResponse`
- `client.roles().updateRole(roleId, request) → UpdateRoleResponse`
- `client.roles().deleteRole(roleId)`
- `client.permissions().listPermissions() → ListPermissionsResponse`
- `client.permissions().createPermission(request) → CreatePermissionResponse`
- `client.sessions().getSession(sessionId) → SessionDetails`
- `client.sessions().getUserSessions(userId, filter) → UserSessionDetails`
- `client.sessions().revokeSession(sessionId)`
- `client.sessions().revokeAllUserSessions(userId)`

Note: Java does NOT yet support Connected Accounts, Tools, or Actions in the public API.

---

## REST API Endpoints

Base URL: `https://<subdomain>.scalekit.com` (production) or `https://<subdomain>.scalekit.dev` (development)

Authentication: Bearer token from `POST /oauth/token` with `client_credentials` grant.

### Token endpoint
```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

client_id={client_id}&client_secret={client_secret}&grant_type=client_credentials
```

### Connected Accounts
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/connected_accounts` | List connected accounts |
| POST | `/api/v1/connected_accounts` | Create a connected account |
| PUT | `/api/v1/connected_accounts` | Update connected account credentials |
| POST | `/api/v1/connected_accounts:delete` | Delete a connected account |
| GET | `/api/v1/connected_accounts/auth` | Get connected account auth details |
| GET | `/api/v1/connected_accounts:search` | Search connected accounts |
| POST | `/api/v1/connected_accounts/magic_link` | Generate authentication magic link |
| POST | `/api/v1/connected_accounts/user/verify` | Verify connected account user |

### Connections
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/connections` | List connections |

### Organizations
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/organizations` | List organizations |
| POST | `/api/v1/organizations` | Create an organization |
| GET | `/api/v1/organizations/{id}` | Get organization details |
| PATCH | `/api/v1/organizations/{id}` | Update organization |
| DELETE | `/api/v1/organizations/{id}` | Delete an organization |
| PUT | `/api/v1/organizations/{id}/portal_links` | Generate admin portal link |
| PATCH | `/api/v1/organizations/{id}/settings` | Toggle organization settings |

### Roles
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/organizations/{org_id}/roles` | List organization roles |
| POST | `/api/v1/organizations/{org_id}/roles` | Create organization role |
| GET | `/api/v1/organizations/{org_id}/roles/{role_name}` | Get role details |
| PUT | `/api/v1/organizations/{org_id}/roles/{role_name}` | Update role |
| DELETE | `/api/v1/organizations/{org_id}/roles/{role_name}` | Delete role |
| PATCH | `/api/v1/organizations/{org_id}/roles:set_defaults` | Set default roles |

### Users & Memberships
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/users` | List users |
| POST | `/api/v1/users` | Create a user |
| GET | `/api/v1/users/{id}` | Get user details |
| PATCH | `/api/v1/users/{id}` | Update user |
| DELETE | `/api/v1/users/{id}` | Delete user |
| GET | `/api/v1/users:search` | Search users |
| GET | `/api/v1/organizations/{org_id}/users` | List organization users |
| GET | `/api/v1/organizations/{org_id}/users:search` | Search organization users |
| POST | `/api/v1/memberships/organizations/{organization_id}/users/{id}` | Add user to organization |
| DELETE | `/api/v1/memberships/organizations/{organization_id}/users/{id}` | Remove user from organization |
| PATCH | `/api/v1/memberships/organizations/{organization_id}/users/{id}` | Update membership |
| PATCH | `/api/v1/invites/organizations/{organization_id}/users/{id}/resend` | Resend invitation |

### Sessions
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/users/{user_id}/sessions` | Get user sessions |
| POST | `/api/v1/users/{user_id}/sessions:revoke_all` | Revoke all user sessions |
| POST | `/api/v1/sessions/{session_id}:revoke` | Revoke a session |

### Tools
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/execute_tool` | Execute a tool using a connected account |

### Organization API Clients (M2M)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/organizations/{organization_id}/clients` | List org API clients |
| POST | `/api/v1/organizations/{organization_id}/clients` | Create org API client |
| GET | `/api/v1/organizations/{organization_id}/clients/{client_id}` | Get org API client |
| DELETE | `/api/v1/organizations/{organization_id}/clients/{client_id}` | Delete org API client |
| PATCH | `/api/v1/organizations/{organization_id}/clients/{client_id}` | Update org API client |

---

## Error Handling

### Node.js exception hierarchy
```
ScalekitException (base)
├── ScalekitValidateTokenFailureException
├── ScalekitServerException (HTTP 400-599)
│   ├── properties: httpStatus, errorCode, message, errDetails
│   └── Specific subclasses for 400, 401, 403, 404, 409, 422, 429, 500, 502, 503, 504
└── WebhookVerificationError
```

Import: `import { ScalekitServerException } from '@scalekit-sdk/node'`

### Python exceptions
```
ScalekitException (base)
```

### Go errors
All methods return `(result, error)`. Check `err != nil` for all network calls.

### Java exceptions
All methods may throw checked exceptions. Wrap in try-catch.

---

## Common Token Claims

Access tokens from Scalekit contain these standard claims:
- `sub` — User ID
- `email` — User email
- `name` — Display name
- `org_id` — Organization ID
- `roles` — Array of role names
- `permissions` — Array of permission strings (also available at `https://scalekit.com/permissions` or `scalekit:permissions` claim paths)

Permission claims should be checked in this priority order:
1. `permissions` claim
2. `https://scalekit.com/permissions` claim
3. `scalekit:permissions` claim