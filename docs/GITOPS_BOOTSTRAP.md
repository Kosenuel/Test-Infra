# GitOps Bootstrap Model

This repository uses a two-layer model:

- Day-0 bootstrap (Helmfile): `ingress-nginx`, `cert-manager`, `argo-cd`
- Day-1+ GitOps (Argo CD): `ClusterIssuer`, `cinder-csi`, `rancher`

This avoids the Argo CD bootstrap chicken-and-egg problem while keeping
platform components under GitOps after bootstrap.

## Ownership

Helmfile-managed:

- `helmfile/helmfile.yaml` release `ingress-nginx`
- `helmfile/helmfile.yaml` release `cert-manager`
- `helmfile/helmfile.yaml` release `argo-cd`

You manually setup 
- `cluster-issuer.yaml`

Argo CD-managed:

- `argocd/platform/cluster-issuer/prod-issuer.yaml`
- `openstack-cinder-csi` chart via `argocd/apps/platform/20-cinder-csi-app.yaml`
- `rancher` chart via `argocd/apps/platform/30-rancher-app.yaml`

## First bootstrap

```bash
cd helmfile
helmfile --selector name=ingress-nginx apply
helmfile --selector name=cert-manager apply
helmfile --selector name=argo-cd apply

# Or Run

cd helmfile/
helmfile sync
```

Create Cluster Issuer resource
```bash
kubectl apply -f helmfile/values/cluster-issuer.yaml
```
And wait for a while for the cluster issuer to sync with the ingress, then check the status of the cluster-issuer `kubectl get cluster-issuer` and the status of the certificate `kubectl get certificate -n argocd`

Create CSI secrets (edit placeholders before apply):

```bash
kubectl apply -f argocd/platform/cinder-csi/examples/cinder-csi-cloud-config.secret.example.yaml
kubectl apply -f argocd/platform/cinder-csi/examples/openstack-ca-cert.secret.example.yaml
```

Register the Git repo in Argo CD (SSH):

```bash
argocd repo add git@github.com:CMCC-Foundation/protocoast-infra.git \
  --ssh-private-key-path ~/.ssh/id_rsa
```

Install app-of-apps root:

```bash
kubectl apply -f argocd/apps/platform-root.yaml
```

Then verify:

```bash
kubectl get applications -n argocd
kubectl get clusterissuer letsencrypt-prod
kubectl get pods -n kube-system | grep -i cinder
kubectl get pods -n cattle-system
```

## Disaster recovery

After cluster rebuild:

1. Re-run the Day-0 Helmfile bootstrap.
2. Re-create CSI secrets from secure source.
3. Re-apply `argocd/apps/platform-root.yaml`.

Argo CD then reconciles ClusterIssuer, CSI, and Rancher automatically.

## Version pinning policy

- Git repo `targetRevision` is pinned to `main` (never `HEAD`).
- External charts are pinned explicitly (`openstack-cinder-csi: 2.34.3`, `rancher: 2.13.0`).
- Keep the cinder chart minor aligned with cluster minor (K8s `1.34.x` -> chart `2.34.x`).
- Upgrade by PR only: test in non-prod, then bump chart version in Argo app manifest.
