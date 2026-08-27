# Troubleshooting

## Quick diagnostics

```bash
NAMESPACE=${NAMESPACE:-scalekit}

kubectl get pods -n $NAMESPACE
kubectl describe pod <pod-name> -n $NAMESPACE
kubectl logs <pod-name> -n $NAMESPACE -c scalekit --tail=100 --previous
kubectl get events -n $NAMESPACE --sort-by=.lastTimestamp
```

## Common issues

### ImagePullBackOff / ErrImagePull
Missing or expired `artifact-registry-secret`.

Recreate it with the token from the distribution portal.

### Migration hook fails
Databases do not exist or wrong connection string in `db-migrations` secret.

The setup script prints the exact `CREATE DATABASE` commands.

### CrashLoopBackOff
Usually bad hostnames, missing secret keys, or wrong `domain` vs actual gateway hostname.

Check previous logs on the scalekit container.

### Gateway has no external IP
- Wrong `gateway.className`
- GatewayClass not installed on the cluster
- For GKE: Gateway controller not enabled

### DNS not resolving
Wildcard record not created or not propagated. Use `dig app.<your-domain>`.

## Support information to gather

- Namespace
- `kubectl get pods -n $NAMESPACE`
- Relevant logs
- Redacted sections of `values.yaml`
- Steps to reproduce

Channels: self-hosted dashboard support ticket, or the Scalekit community Slack.

See also the official troubleshooting page for the latest.
