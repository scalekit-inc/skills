# Opaque API keys — other languages

Same default path as `SKILL.md`: create an org-scoped key → show `token` once → store `token_id` → validate on every request → list / invalidate.

Use this file when the repo is Python, Go, or Java. Do not run the Node samples in `SKILL.md`.

Env names: `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`. Never `SCALEKIT_ENV_URL`. Copy the organization ID from the dashboard. Do not invent `org_…` or `usr_…` values.

## Python

Install `scalekit-sdk-python` only when the repo has no Scalekit SDK yet:

```sh
pip install scalekit-sdk-python
```

Constructor arg is `env_url`. Env name is still `SCALEKIT_ENVIRONMENT_URL`. Client is `scalekit_client.tokens` (plural).

```python
import os
from scalekit import ScalekitClient
from scalekit.common.exceptions import ScalekitValidateTokenFailureException

scalekit_client = ScalekitClient(
    env_url=os.environ["SCALEKIT_ENVIRONMENT_URL"],
    client_id=os.environ["SCALEKIT_CLIENT_ID"],
    client_secret=os.environ["SCALEKIT_CLIENT_SECRET"],
)

response = scalekit_client.tokens.create_token(
    organization_id=organization_id,
    description="CI/CD pipeline token",
)
opaque_token = response.token
token_id = response.token_id

try:
    result = scalekit_client.tokens.validate_token(token=opaque_token)
    org_id = result.token_info.organization_id
except ScalekitValidateTokenFailureException:
    raise  # return 401

listed = scalekit_client.tokens.list_tokens(
    organization_id=organization_id,
    page_size=10,
)
scalekit_client.tokens.invalidate_token(token=token_id)
```

User-scoped: pass `user_id=` from the dashboard, plus optional `custom_claims={"team": "engineering"}`.

## Go

Install `scalekit-sdk-go/v2` only when the repo has no Scalekit SDK yet:

```sh
go get github.com/scalekit-inc/scalekit-sdk-go/v2
```

```go
scalekitClient := scalekit.NewScalekitClient(
  os.Getenv("SCALEKIT_ENVIRONMENT_URL"),
  os.Getenv("SCALEKIT_CLIENT_ID"),
  os.Getenv("SCALEKIT_CLIENT_SECRET"),
)

response, err := scalekitClient.Token().CreateToken(
  ctx, organizationId, scalekit.CreateTokenOptions{
    Description: "CI/CD pipeline token",
  },
)
opaqueToken := response.GetToken()
tokenId := response.GetTokenId()

result, err := scalekitClient.Token().ValidateToken(ctx, opaqueToken)
if errors.Is(err, scalekit.ErrTokenValidationFailed) {
  // return 401
}
orgId := result.GetTokenInfo().GetOrganizationId()

_, _ = scalekitClient.Token().ListTokens(ctx, organizationId, scalekit.ListTokensOptions{PageSize: 10})
_ = scalekitClient.Token().InvalidateToken(ctx, tokenId)
```

User-scoped: set `UserId` on `CreateTokenOptions`. Optional `CustomClaims`.

## Java

Add `com.scalekit:scalekit-sdk-java` only when the repo has no Scalekit SDK yet:

```xml
<dependency>
    <groupId>com.scalekit</groupId>
    <artifactId>scalekit-sdk-java</artifactId>
</dependency>
```

```java
ScalekitClient scalekitClient = new ScalekitClient(
    System.getenv("SCALEKIT_ENVIRONMENT_URL"),
    System.getenv("SCALEKIT_CLIENT_ID"),
    System.getenv("SCALEKIT_CLIENT_SECRET")
);

CreateTokenResponse response = scalekitClient.tokens().create(organizationId);
String opaqueToken = response.getToken();
String tokenId = response.getTokenId();

try {
    ValidateTokenResponse result = scalekitClient.tokens().validate(opaqueToken);
    String orgId = result.getTokenInfo().getOrganizationId();
} catch (TokenInvalidException e) {
    // return 401
}

scalekitClient.tokens().list(organizationId, 10, null);
scalekitClient.tokens().invalidate(tokenId);
```

User-scoped: `tokens().create(organizationId, userId, claims, null, "label")`.

## Live lookups

- API keys: https://docs.scalekit.com/authenticate/m2m/api-keys/
- Docs index: https://docs.scalekit.com/llms.txt
