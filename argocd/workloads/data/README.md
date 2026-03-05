# Data Workloads: JupyterHub and Dask Gateway

This directory contains values files consumed by Argo CD ApplicationSets:

- `jhub-values.yaml`
- `dask-gateway-values.yaml`
- `examples/daskhub-oauth-secrets.example.yaml`
- `examples/daskhub-gateway-secrets.example.yaml`

These values are applied through:

- `argocd/applicationsets/data-jupyterhub.main.yaml`
- `argocd/applicationsets/data-dask-gateway.main.yaml`

## Operational Intent

- OAuth authentication via EGI AAI
- Persistent storage via OpenStack Cinder
- Resource controls for notebook pods and Dask clusters
- Shared ingress/TLS model with cert-manager and nginx ingress

## Security Notes

- We should not commit real OAuth secrets or gateway tokens.
- This workload expects Kubernetes Secrets in namespace `daskhub`:
  - `daskhub-oauth-secrets` with keys `client_id` and `client_secret`
  - `daskhub-gateway-secrets` with key `api_token`
- We could implement them via: SOPS + age.
- `dask-gateway` values use `apiTokenFromSecretName` and `apiTokenFromSecretKey` to read the token from `daskhub-gateway-secrets`.

## Required Secret Setup

Before syncing `data-jupyterhub-main` and `data-dask-gateway-main`, create the Secrets in the same namespace where the apps deploy (`daskhub`):

```bash
kubectl apply -f argocd/workloads/data/examples/daskhub-oauth-secrets.example.yaml -n daskhub
kubectl apply -f argocd/workloads/data/examples/daskhub-gateway-secrets.example.yaml -n daskhub
kubectl apply -f argocd/workloads/data/examples/dask-gateway-secrets.example.yaml -n daskhub
```

If you wrote  `namespace: daskhub` inside the files, `-n daskhub` is optional.

After changing these values and pushing them to github, Argo CD would detect it and auto apply them.

## Runtime Checks

```bash
kubectl get pods -n daskhub
kubectl get ingress -n daskhub
kubectl logs -n daskhub deploy/hub
kubectl logs -n daskhub deploy/dask-gateway
```
