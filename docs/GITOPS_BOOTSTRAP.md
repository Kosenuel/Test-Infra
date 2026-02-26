# GitOps Bootstrap and Recovery

This runbook defines ownership and bootstrap steps for the management cluster.

## Ownership Model

Helmfile-managed (Day-0):

- ingress-nginx
- cert-manager
- argo-cd
- rancher

Argo CD-managed (Day-1+):

- `argocd/workloads/platform/cluster-issuer/prod-issuer.yaml`
- `openstack-cinder-csi` via `argocd/applicationsets/platform-cinder-csi.main.yaml`
- `jupyterhub` via `argocd/applicationsets/data-jupyterhub.main.yaml`
- `dask-gateway` via `argocd/applicationsets/data-dask-gateway.main.yaml`

## Canonical Repository URLs

- HTTPS: `https://github.com/CMCC-Foundation/protocoast-infra`
- SSH: `git@github.com:CMCC-Foundation/protocoast-infra.git`

## First Bootstrap

1. Install Day-0 components.

```bash
cd helmfile
helmfile --selector name=ingress-nginx apply
helmfile --selector name=cert-manager apply
helmfile --selector name=argo-cd apply
helmfile --selector name=rancher apply
```

2. Create Cinder CSI secrets (edit placeholders first).

```bash
kubectl apply -f argocd/workloads/platform/cinder-csi/examples/cinder-csi-cloud-config.secret.example.yaml
kubectl apply -f argocd/workloads/platform/cinder-csi/examples/openstack-ca-cert.secret.example.yaml
```

3. Register repository in Argo CD (SSH auth).

```bash
argocd repo add git@github.com:CMCC-Foundation/protocoast-infra.git \
  --ssh-private-key-path ~/.ssh/id_rsa
```

4. Apply root app.

```bash
kubectl apply -f argocd/bootstrap/main-root.yaml
```

5. Verify state.

```bash
kubectl get applications -n argocd
kubectl get clusterissuer letsencrypt-prod
kubectl get pods -n kube-system | grep -i cinder
kubectl get pods -n daskhub
kubectl get pods -n cattle-system
```

## Disaster Recovery

After rebuilding the management cluster:

1. Re-run Helmfile Day-0 bootstrap.
2. Recreate CSI secrets from secure source.
3. Re-apply `argocd/bootstrap/main-root.yaml`.

Argo CD then reconciles issuer, CSI, and data workloads automatically.

## Version Pinning Policy

Current pinned versions in repo:

- openstack-cinder-csi: `2.34.3`
- jupyterhub chart: `3.3.8`
- dask-gateway chart: `2022.6.1`
- rancher chart (Helmfile): `2.13.2`

Use PR-based upgrades, validate in non-prod, then promote.
