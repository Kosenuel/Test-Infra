# Cinder CSI Secrets

OpenStack credentials are intentionally not stored in Git.

Before syncing the Argo CD ApplicationSet `platform-cinder-csi-main`, create these secrets in `kube-system` from the provided examples:

1. `examples/cinder-csi-cloud-config.secret.example.yaml`
2. `examples/openstack-ca-cert.secret.example.yaml`

Apply:

```bash
kubectl apply -f argocd/workloads/platform/cinder-csi/examples/cinder-csi-cloud-config.secret.example.yaml
kubectl apply -f argocd/workloads/platform/cinder-csi/examples/openstack-ca-cert.secret.example.yaml
```

Then sync:

```bash
argocd app sync platform-cinder-csi-main
```
