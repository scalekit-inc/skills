# Configuration Reference (values.yaml)

This is a focused extract of the most important fields for integrators and deployers. See the full official reference for every option.

## App

```yaml
scalekit:
  config:
    app:
      domain: "auth.example.com"
      protocol: "https"
      region: "us"
```

| Field | Description |
|-------|-------------|
| `domain` | Base domain. Derives `app.<domain>` and `auth.<domain>`. |
| `protocol` | `https` in production. Use `http` + `oidc.allow_insecure: true` only for local testing. |
| `region` | Data residency label. Set once. |

## Database (external)

```yaml
scalekit:
  config:
    database:
      host: "pg.internal.example.com"
      name: "scalekit"
      user: "scalekit"
      port: 5432
```

When `postgresql.enabled: false`, the password lives in the `authentication-secret` K8s secret.

## Redis (external)

```yaml
scalekit:
  config:
    redis:
      host: "redis.internal.example.com"
      port: 6379
      db: 0
```

Separate db indexes are used for main app, Asynq jobs, and Svix.

## Seed Data

```yaml
scalekit:
  config:
    seedData:
      adminUser:
        firstName: "Admin"
        lastName: "User"
        email: "admin@example.com"
      emailServer:
        serverType: "SMTP"
        provider: "POSTMARK"   # POSTMARK, SENDGRID, or OTHER
        enabled: true
        settings:
          fromEmail: "noreply@example.com"
          fromName: "Your Company"
          host: "smtp.postmarkapp.com"
          port: 587
          username: "..."
```

The SMTP password goes in secrets (see below).

## Gateway

```yaml
gateway:
  enabled: true
  className: "gke-l7-global-external-managed"
  provider: "gcp"          # gcp or other
  annotations:
    networking.gke.io/certmap: "your-cert-map"
  redirectToHttps: true
```

Common GatewayClasses:
- GKE external: `gke-l7-global-external-managed`
- Istio: `istio`
- Envoy Gateway: `eg`

## Secrets (when using `secrets.create: true`)

```yaml
secrets:
  create: true
  svix:
    jwtSecret: "..."
    apiToken: "..."
  registry:
    password: "<your portal token>"
  # database.password, redis password, smtp password, etc.
```

When `secrets.create: false`, the setup script generates a shell script that creates the secrets.

## Optional

- `sidecars.openfga.enabled: true` (needs its own DB)
- `scalekit.config.directoryServer.enabled: true` for SCIM

For complete production and quickstart examples, see `references/production-deployment.md` and `references/quickstart.md`.
