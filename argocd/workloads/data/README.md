# Data Workloads: JupyterHub and Dask Gateway

This directory contains values files consumed by Argo CD ApplicationSets:

- `jhub-values.yaml`
- `dask-gateway-values.yaml`

These values are applied through:

- `argocd/applicationsets/data-jupyterhub.main.yaml`
- `argocd/applicationsets/data-dask-gateway.main.yaml`

## Operational Intent

- OAuth authentication via EGI AAI
- Persistent storage via OpenStack Cinder
- Resource controls for notebook pods and Dask clusters
- Shared ingress/TLS model with cert-manager and nginx ingress

## Security Notes

- Do not commit real OAuth secrets or gateway tokens.
- Replace static placeholders/tokens with managed secrets.
- Preferred approaches: SOPS, Vault, or External Secrets.

## Validation Workflow

Before changing values in production:

```bash
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo add dask https://helm.dask.org/
helm repo update

helm lint jupyterhub/jupyterhub -f argocd/workloads/data/jhub-values.yaml
helm lint dask/dask-gateway -f argocd/workloads/data/dask-gateway-values.yaml
```

Render checks:

```bash
helm template jupyterhub jupyterhub/jupyterhub \
  --version 3.3.8 \
  -f argocd/workloads/data/jhub-values.yaml | kubectl apply --dry-run=server -f -

helm template dask-gateway dask/dask-gateway \
  --version 2022.6.1 \
  -f argocd/workloads/data/dask-gateway-values.yaml | kubectl apply --dry-run=server -f -
```

## Runtime Checks

```bash
kubectl get pods -n daskhub
kubectl get ingress -n daskhub
kubectl logs -n daskhub deploy/hub
kubectl logs -n daskhub deploy/dask-gateway
```
