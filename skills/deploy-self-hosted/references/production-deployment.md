# Production Deployment (External Services)

For real workloads, use external PostgreSQL and Redis with proper secret management. The bundled subcharts are evaluation-only.

## Prerequisites

- External PostgreSQL 15+ with three databases (`scalekit`, `webhooks`, `openfga`)
- External Redis 6.2+
- GatewayClass + TLS annotation ready
- Registry token from the distribution portal
- Domain + wildcard DNS planned

## Step 1: Run the setup script (strongly recommended)

The official interactive script generates cryptographic values, a secrets creation script, and a ready-to-use `values.yaml`.

Download/copy the current `setup-secrets.sh` from the self-hosted docs, make it executable, and run:

```bash
chmod +x setup-secrets.sh
bash setup-secrets.sh [--enable-openfga] [--change-defaults]
```

Choose your environment when prompted:
- 1 = Minikube (local)
- 2 = GCP/GKE
- 3 = Other Kubernetes
- 4 = Evaluation (use quickstart instead)

The script will ask for:
- Namespace
- PostgreSQL host/port/user/password + database names
- Redis host/port/password + db indexes
- SMTP settings
- Registry token and server URL
- Domain, region, replica count
- Admin user details
- GatewayClass / cert map (GKE)

It outputs two files, e.g.:
- `scalekit-secrets-gke-....sh`
- `values-gke-....yaml`

Review both files carefully.

## Step 2: Apply secrets

```bash
bash scalekit-secrets-....sh
```

Verify:

```bash
kubectl get secrets -n <namespace>
```

Expected secrets include `authentication-secret`, `db-migrations`, `svix-secrets`, `artifact-registry-secret`, etc.

## Step 3: Create the deployment in the portal

1. In the distribution portal:
   - Deployments → + New Deployment → Scalekit Onprem
   - Deployment Name + Kubernetes Namespace (must match)
   - Paste the full contents of the generated `values-*.yaml`
   - Select version and create

2. Copy the `kubectl apply -n <namespace> -f "<url>"` command and run it.

The deployment agent will pull the chart and start the rollout.

## Step 4: DNS + verification

Same as quickstart:

```bash
kubectl get gateway -n <namespace>
```

Wildcard A record: `*.<your-domain>` → external IP

```bash
kubectl get pods -n <namespace>
```

Open `https://app.<your-domain>` and log in with the seeded admin user.

## Important notes

- Databases must exist before the `kubectl apply` (the script prints the CREATE DATABASE commands).
- For GKE use `provider: gcp` and the appropriate GatewayClass + certmap annotation.
- After first boot, use the self-hosted dashboard to create environments/clients.

See `references/configuration.md` for the full field reference and production `values.yaml` example.

Next: `references/troubleshooting.md` if anything fails.
