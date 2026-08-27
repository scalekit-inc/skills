---
name: deploy-self-hosted
description: >
  Deploys self-hosted Scalekit so an agent can install
  Helm or on-prem.
  Use when the user wants self-hosted Scalekit or Helm.
  It does not write SaaSKit login (that's `implement-saaskit`).
---

# Deploy self-hosted Scalekit

Install Scalekit on Kubernetes with Helm. Then stop.

## Guardrails

- **MUST** use an enterprise license and the distribution portal for the chart and registry token.
- **MUST** use external PostgreSQL 15+ and Redis 6.2+ in production. Bundled DBs are eval only.
- **MUST** set `app.domain` with no scheme and no trailing slash.
- **MUST NOT** commit registry tokens, SMTP passwords, or DB passwords.
- **MUST NOT** write SaaSKit login. Name `implement-saaskit` instead.
- **MUST** point the app at `SCALEKIT_ENVIRONMENT_URL=https://app.<domain>`. Never `SCALEKIT_ENV_URL`. Never `app.scalekit.com`.

## Gotchas

- Default path is production (external DBs). Eval or bundled DBs hop to [references/quickstart.md](references/quickstart.md).
- Helm + Kubernetes Gateway API.
- Three Postgres DBs: `scalekit`, `webhooks`, `openfga`.
- Portal flow: Deployments → Scalekit Onprem → paste values → `kubectl apply` the connect command.
- DNS: wildcard A record to the Gateway ADDRESS. Verify at `https://app.<domain>`.
- The plugin MCP (`https://mcp.scalekit.com`) stays cloud. The app uses the self-hosted env URL.
- Field dumps live in `references/`. Open one hop. Do not paste them here.

## Step 1 — Pick the path

- Evaluation, bundled DBs, or a Minikube proof of concept → open [references/quickstart.md](references/quickstart.md). Stop reading this file.
- Production or on-prem → stay here.

Need: `kubectl` 1.27+, Helm 3.12+, a GatewayClass, TLS, SMTP, a domain, a registry token, external PostgreSQL 15+ with those three databases, and Redis 6.2+.

**Done when:** this is the production path, or the eval file is open and this file is closed.

## Step 2 — Secrets and values

Open [references/production-deployment.md](references/production-deployment.md) for `setup-secrets.sh`. Run it. Apply the generated secrets script. Then stop reading that file.

Confirm:

```bash
kubectl get secrets -n <namespace>
```

Write `values.yaml`. `scalekit.config.app.domain` is `example.com`, not `https://example.com` and not `example.com/`.

`postgresql.enabled: false`. `redis.enabled: false`.

Open [references/configuration.md](references/configuration.md) only for field names. Then stop reading it.

**Done when:** secrets exist in the namespace, and `app.domain` has no scheme and no slash.

## Step 3 — Portal and connect

1. Create the namespace if it is missing: `kubectl create namespace <namespace>`
2. Distribution portal → Deployments → + New Deployment → Scalekit Onprem
3. Set Deployment Name and the same Kubernetes Namespace
4. Paste the full `values.yaml`
5. Create the deployment
6. Copy the `kubectl apply` connect command. Run it.

The portal agent delivers the chart and runs migrations. Databases must exist before this apply.

**Done when:** the connect command has been applied.

## Step 4 — DNS

```bash
kubectl get gateway -n <namespace>
```

Create a wildcard A record: `*.<domain>` → Gateway ADDRESS.

```bash
dig app.<domain>
```

**Done when:** `dig` returns that ADDRESS.

## Step 5 — Verify

```bash
kubectl get pods -n <namespace>
```

All pods are `Running`. Open `https://app.<domain>` and sign in with the seeded admin user.

```bash
export SCALEKIT_ENVIRONMENT_URL="https://app.<domain>"
```

If pods fail, open [references/troubleshooting.md](references/troubleshooting.md). Later version bumps: [references/upgrades.md](references/upgrades.md).

**Done when:** the dashboard loads at `https://app.<domain>` and the env URL is that origin.

## Step 6 — Stop

Name `implement-saaskit` for login against this env. Do not write login here.

**Done when:** the instance is up, the env URL is set, and this skill has stopped.

## Reach for

- [references/quickstart.md](references/quickstart.md) for bundled-DB eval
- [references/production-deployment.md](references/production-deployment.md) for the setup script
- [references/configuration.md](references/configuration.md) for values.yaml fields
- [references/troubleshooting.md](references/troubleshooting.md) when a pod is not Running
- [references/upgrades.md](references/upgrades.md) for a version bump
- `implement-saaskit` to write login
- `review-scalekit-code` to review a snippet

## Live lookups

- Overview: https://docs.scalekit.com/self-hosted/overview/
- Quickstart: https://docs.scalekit.com/self-hosted/quickstart/
- Installation: https://docs.scalekit.com/self-hosted/installation/
- Configuration: https://docs.scalekit.com/self-hosted/configuration/
- MCP: https://mcp.scalekit.com
