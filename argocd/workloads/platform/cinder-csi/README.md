# Cinder CSI Secrets (manual for now)

This repo intentionally keeps OpenStack credentials out of Git.

Before syncing the Argo CD app `platform-cinder-csi`, create the required
secrets in `kube-system` from the example manifests in `examples/`:

1. `examples/cinder-csi-cloud-config.secret.example.yaml`
2. `examples/openstack-ca-cert.secret.example.yaml`

Apply flow:

```bash
kubectl apply -f argocd/workloads/platform/cinder-csi/examples/cinder-csi-cloud-config.secret.example.yaml
kubectl apply -f argocd/workloads/platform/cinder-csi/examples/openstack-ca-cert.secret.example.yaml
```

Then sync:

```bash
argocd app sync platform-cinder-csi
```
