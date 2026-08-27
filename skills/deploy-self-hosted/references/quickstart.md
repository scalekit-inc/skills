# Quickstart: Evaluation Deployment (Bundled Databases)

Use this to get a working Scalekit instance fast for testing or proof-of-concept. **Not suitable for production**.

The Helm chart includes optional PostgreSQL and Redis subcharts. They have no backups, replication, or persistence guarantees.

## Before you start

| Requirement | Notes |
|-------------|-------|
| `kubectl` 1.27+ | Configured against target cluster |
| Helm 3.12+ | Verified with `helm version` |
| Domain | Subdomains `app.<domain>` and `auth.<domain>` must resolve |
| GatewayClass | Installed on the cluster |
| TLS certificate | Attached via gateway annotation (cert-manager, GCP cert map, etc.) |
| SMTP credentials | Postmark/SendGrid preferred |
| Registry token | From Scalekit distribution portal |
| `openssl` + `python3` | For generating webhook credentials |

## Step 1: Get registry token

Log into the Scalekit distribution portal and create a Personal Access Token.

Copy it immediately (shown only once). Note the expiry date.

## Step 2: Generate webhook credentials

```bash
export JWT_SECRET=$(openssl rand -base64 32)
echo "jwtSecret: $JWT_SECRET"

python3 << 'EOF'
import base64, hashlib, hmac as _hmac, json, os, secrets, string, time

secret = os.environ['JWT_SECRET']
chars = string.ascii_letters + string.digits
sub = 'org_' + ''.join(secrets.choice(chars) for _ in range(22))
now = int(time.time())
exp = now + 315360000

h = base64.urlsafe_b64encode(json.dumps({'alg':'HS256','typ':'JWT'}, separators=(',',':')).encode()).rstrip(b'=').decode()
p = base64.urlsafe_b64encode(json.dumps({'iat':now,'exp':exp,'nbf':now,'iss':'svix-server','sub':sub}, separators=(',',':')).encode()).rstrip(b'=').decode()
msg = f'{h}.{p}'
sig = base64.urlsafe_b64encode(_hmac.new(secret.encode(), msg.encode(), hashlib.sha256).digest()).rstrip(b'=').decode()
print(f'apiToken: {msg}.{sig}')
EOF
```

## Step 3: Create values.yaml

Use this template (replace placeholders):

```yaml
scalekit:
  config:
    app:
      domain: "<your-domain>"            # e.g. scalekit.example.com (no scheme)
    seedData:
      adminUser:
        firstName: "<firstname>"
        lastName: "<lastname>"
        email: "<admin-email>"
      emailServer:
        settings:
          fromEmail: "hi@<your-domain>"
          fromName: "Team <Your Company>"
          host: "<smtp-host>"
          port: <smtp-port>
          username: "<smtp-username>"

postgresql:
  enabled: true

redis:
  enabled: true

secrets:
  create: true
  svix:
    jwtSecret: "<jwtSecret from step 2>"
    apiToken: "<apiToken from step 2>"
  registry:
    password: "<registry token from step 1>"

gateway:
  enabled: true
  provider: "<provider>"                # gcp for GKE; other otherwise
  className: "<gateway-class-name>"
  annotations:
    <annotation-key>: "<annotation-value>"
  redirectToHttps: true
  healthCheckPolicy:
    enabled: true                       # GKE only — set false for others
```

Key fields explained in `references/configuration.md`.

## Step 4: Create deployment in the portal

1. Create the namespace:
   ```bash
   kubectl create namespace <namespace>
   ```

2. In the distribution portal:
   - Deployments → + New Deployment → Scalekit Onprem
   - Set Deployment Name (recommend `scalekit`) and the Kubernetes Namespace
   - Leave "Enable cluster-scoped permissions" checked
   - Select version
   - Paste the full `values.yaml` under Helm values
   - Create Deployment

3. Copy the `kubectl apply` command shown and run it.

The portal + agent will deliver the chart and run migrations.

## Step 5: Update DNS

Get the gateway external IP:

```bash
kubectl get gateway -n <namespace>
```

Create a wildcard A record in your DNS provider:

```
*.<your-domain> → <external-ip>
```

Verify:

```bash
dig app.<your-domain>
```

## Step 6: Verify

```bash
kubectl get pods -n <namespace>
```

All pods should be `Running`.

Open `https://app.<your-domain>` and sign in with the admin email from `values.yaml`.

## Next steps

- For production (external DBs + full secret management) see `references/production-deployment.md`
- Full configuration reference: `references/configuration.md`
- Troubleshooting: `references/troubleshooting.md`

**Important**: Switch to external databases and proper secret management before going to production.
