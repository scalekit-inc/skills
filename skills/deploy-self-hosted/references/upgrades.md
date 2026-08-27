# Upgrades and Maintenance

## Upgrade

1. In the distribution portal:
   - Deployments → select your deployment
   - Edit deployment → choose new version → Update deployment

2. The in-cluster deployment agent picks up the change automatically.

Monitor progress:

```bash
kubectl logs -l app=distr-agent -n <namespace> --tail=100 -f
kubectl get pods -n <namespace>
kubectl rollout status deployment/scalekit -n <namespace>
```

## Rollback

```bash
helm history scalekit -n <namespace>
helm rollback scalekit -n <namespace>
```

## Routine tasks

- Rotate registry token before it expires (update `artifact-registry-secret`, restart pods)
- Rotate other secrets by editing the K8s secret directly then restarting pods
- Regular PostgreSQL backups of the three databases
- Review auth logs in the self-hosted dashboard

TLS certificates are renewed by your cert provider; the Gateway picks them up automatically.
