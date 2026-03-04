# Helmfile Operations Guide

This directory manages Day-0 platform components on the management cluster.

## Documentation Index

- [Helmfile Operations Guide](./README.md)
- [Install Helm](./install-helm.md)
- [Install Helmfile](./install-helmfile.md)
- [DNS/IPv6 workaround script](./fix-helmfile-issue.sh)
- [Helmfile release definition](./helmfile.yaml)
- Values:
  - [argocd values](./values/argocd.yaml)
  - [cert-manager values](./values/cert-manager.yaml)
  - [ingress-nginx values](./values/nginx-values.yaml)
  - [rancher values](./values/rancher.yaml)
  - [cluster issuer manifest](./values/cluster-issuer.yaml)

## Scope and Ownership

Helmfile in this folder manages:

- `ingress-nginx` (ingress controller)
- `cert-manager` (certificate management, CRDs installed)
- `rancher` (management UI/API)
- `argo-cd` (GitOps control plane)

Source of truth:

- Helmfile definition: `helmfile.yaml`
- Values: `values/*.yaml`

## Prerequisites

- Kubernetes access to the management cluster (`kubectl config current-context` should be correct)
- `helm` installed
- `helmfile` installed
- Network access to chart repositories

Recommended tools:

- `helm-diff` plugin

Install plugin:

```bash
helm plugin install https://github.com/databus23/helm-diff
```

## Environment Fix for DNS/IPv6 Issue

If Helmfile fails due to DNS resolution issues on your host, run:

For Bash:

```bash
source fix-helmfile-issue.sh
```

For PowerShell:

```powershell
bash -lc "source fix-helmfile-issue.sh && env | grep GODEBUG"
```

This sets:

```bash
GODEBUG=netdns=go,ipv6=0
```

## Managed Releases

Current release set from `helmfile.yaml`:

- `ingress-nginx` -> `ingress-nginx/ingress-nginx` `4.11.3`
- `cert-manager` -> `jetstack/cert-manager` `v1.15.0`
- `rancher` -> `rancher-latest/rancher` `2.13.2`
- `argo-cd` -> `argo/argo-cd` `9.3.0`

## Values Files

- `values/nginx-values.yaml`: ingress controller mode and service behavior
- `values/cert-manager.yaml`: cert-manager settings (`installCRDs: true`)
- `values/rancher.yaml`: Rancher hostname/replicas/bootstrap password/ingress
- `values/argocd.yaml`: Argo CD ingress and server params
- `values/cluster-issuer.yaml`: cert-manager `ClusterIssuer` (applied manually)

## Security Notes

- Do not keep real production secrets in Git.
- `values/rancher.yaml` contains `bootstrapPassword`; rotate immediately in live clusters.
- Keep TLS and DNS hostnames environment-specific where applicable.

## Operational Order

Apply in this order on first bootstrap:

1. `ingress-nginx`
2. `cert-manager`
3. `rancher`
4. `argo-cd`

Then apply `ClusterIssuer`:

```bash
kubectl apply -f values/cluster-issuer.yaml
```

## Common Commands

From `Test-Infra/helmfile` directory:

### 1. Validate and preview

```bash
helmfile repos
helmfile lint
helmfile diff
```

### 2. Apply all releases

```bash
helmfile sync
```

### 3. Apply release

#### Apply one after the other
```bash
helmfile --selector app=ingress apply
helmfile --selector app=cert-manager apply
helmfile --selector app=rancher apply
helmfile --selector app=argocd apply
```

#### Or Apply by label
```bash
helmfile -l tier=platform apply
```

### 4. Check status

```bash
helmfile status
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager
kubectl get pods -n cattle-system
kubectl get pods -n argocd
```

### 5. Inspect effective manifests

```bash
helmfile template > rendered-manifests.yaml
```

## First-Time Bootstrap Runbook

```bash
cd Test-Infra/helmfile
source fix-helmfile-issue.sh
helmfile repos
helmfile sync
kubectl apply -f values/cluster-issuer.yaml
```

PowerShell variant:

```powershell
cd Test-Infra/helmfile
bash -lc "source fix-helmfile-issue.sh && helmfile repos && helmfile sync"
kubectl apply -f values/cluster-issuer.yaml
```

Verify:

```bash
kubectl get clusterissuer letsencrypt-prod
kubectl get ingress -A
kubectl get certificate -A
```

## Upgrade Procedure

1. Create a branch and pin new chart version in `helmfile.yaml`.
2. Update corresponding values if needed.
3. Run:

```bash
helmfile repos
helmfile lint
helmfile diff
```

4. Apply in non-prod first.
5. Validate workloads and ingress TLS.
6. Promote to higher environments.

## Rollback Procedure

If a release upgrade fails:

1. Revert chart/value changes in Git and re-run `helmfile sync`.
2. Or use Helm rollback directly for urgent recovery:

```bash
helm -n <namespace> history <release>
helm -n <namespace> rollback <release> <revision>
```

Then re-align Git and Helmfile state.

## Troubleshooting

### `helmfile diff` fails

- Ensure `helm-diff` is installed.
- Run `helm plugin list` and confirm `diff` is present.

### DNS lookup errors during Helmfile operations

- Run `source fix-helmfile-issue.sh`.

### cert-manager resources fail to reconcile

- Confirm CRDs were installed (`installCRDs: true`).
- Check:

```bash
kubectl get crd | grep cert-manager
kubectl logs -n cert-manager deploy/cert-manager
```

### Ingress/TLS not issuing certificates

- Verify `ClusterIssuer` exists and is Ready.
- Confirm DNS resolves to ingress endpoint.
- Check cert-manager events:

```bash
kubectl describe clusterissuer letsencrypt-prod
kubectl get events -n cert-manager --sort-by=.metadata.creationTimestamp
```

### Argo CD or Rancher unreachable

- Check ingress objects and hostnames in values files.
- Verify service/pod readiness in `argocd` and `cattle-system` namespaces.

## Recommended Improvements

- Move sensitive values (for example Rancher bootstrap password) to secure secret management.
- Add CI checks for `helmfile lint` + `helmfile diff` on pull requests.
- Keep chart versions pinned and updated via controlled PR workflow.
