# ProtoCoast JupyterHub + Dask Gateway Deployment

## Overview

This Helm chart deploys a JupyterHub environment with integrated Dask Gateway for distributed computing on Kubernetes. The deployment is configured for the ProtoCoast project running on the EGI Federated Cloud infrastructure.

### Key Features

- OAuth2 authentication via EGI AAI (Check-In)
- Dask Gateway for scalable distributed computing
- Multiple notebook image profiles (main and develop branches)
- Persistent storage with OpenStack Cinder volumes
- TLS-secured ingress with Let's Encrypt certificates
- Resource limits and quotas 
---

## Architecture

The deployment consists of three main components:

1. **JupyterHub**: Central hub for user authentication, spawning notebook servers, and resource management
2. **Dask Gateway**: Manages Dask clusters for distributed computing with resource limits and security controls
3. **Single-user Notebook Servers**: Individual Jupyter environments with persistent storage and configurable resources

---

## Prerequisites

### Infrastructure Requirements

- Kubernetes cluster (version 1.24 or higher recommended)
- OpenStack Cinder CSI driver configured (storage class: csi-cinder-sc-delete)
- NGINX Ingress Controller installed
- cert-manager with letsencrypt-prod cluster issuer configured
- DNS record pointing to your ingress controller (protocoast.vm.fedcloud.eu)

### OAuth Application Setup

Register an OAuth2 application with EGI Check-In (https://aai-demo.egi.eu):

- Redirect URI: `https://protocoast.vm.fedcloud.eu/hub/oauth_callback`
- Obtain `client_id` and `client_secret`
- Request scopes: `openid`, `profile`, `email`, `entitlements`

---

## Configuration Details

### Dask Gateway Configuration

Dask Gateway provides secure, multi-tenant access to Dask clusters with resource controls and authentication.

#### Cluster Resource Limits

| Parameter | Value |
|-----------|-------|
| `cluster_max_cores` | 4 cores |
| `cluster_max_memory` | 16 GiB (25,769,803,776 bytes) |
| `cluster_max_workers` | 3 workers |
| `idle_timeout` | 1200 seconds (20 minutes) |

#### Worker Options

Users can customize worker resources when creating a Dask cluster:

- **Worker Cores**: 1-2 cores per worker (default: 1)
- **Worker Memory**: 4-6 GiB per worker (default: 4 GiB)
- **Image**: `quay.io/globalcoast/protocoast-notebook:main` (must include tag)

### Authentication Configuration

The deployment uses EGI Check-In for OAuth2 authentication with the GenericOAuthenticator.

#### OAuth Endpoints

| Endpoint | URL |
|----------|-----|
| Authorization | `https://aai-demo.egi.eu/auth/realms/egi/protocol/openid-connect/auth` |
| Token | `https://aai-demo.egi.eu/auth/realms/egi/protocol/openid-connect/token` |
| Userinfo | `https://aai-demo.egi.eu/auth/realms/egi/protocol/openid-connect/userinfo` |
| Callback | `https://protocoast.vm.fedcloud.eu/hub/oauth_callback` |

### Storage Configuration

#### Hub Database Storage

JupyterHub uses SQLite with persistent volume claims:

- **Storage Class**: csi-cinder-sc-delete
- **Access Mode**: ReadWriteOnce
- **Size**: 1 GiB

#### User Notebook Storage

Each user receives persistent home directory storage:

- **Type**: Dynamic PVC provisioning
- **Storage Class**: csi-cinder-sc-delete
- **Capacity**: 50 GiB per user

### Notebook Server Profiles

Users can select from two notebook environments at spawn time:

#### ProtoCoast - main (Default)

- **Image**: `quay.io/globalcoast/protocoast-notebook:main`
- **Description**: Stable production version

#### ProtoCoast - develop

- **Image**: `quay.io/globalcoast/protocoast-notebook:develop`
- **Description**: Development version with latest features

### Resource Allocation

#### Single-user Notebook Servers

| Resource | Guarantee | Limit |
|----------|-----------|-------|
| CPU | 1 cores | 2 core |
| Memory | 5 GiB | 10 GiB |
| Ephemeral Storage (helps with pod's tmp dir ops) | 4 GiB | 8 GiB | 

## Security First

Current values files contain sensitive values (`client_secret`, `apiToken`).
Do not keep real credentials in Git.

Recommended approach:

1. Replace secrets in tracked values with placeholders.
2. Put real secrets in a private file such as `values-secrets.yaml` (not committed).
3. Pass both files during `helm upgrade --install`.

Example `values-secrets.yaml`:

```yaml
hub:
  config:
    GenericOAuthenticator:
      client_id: "<CLIENT_ID>"
      client_secret: "<CLIENT_SECRET>"
  services:
    dask-gateway:
      apiToken: "<DASK_GATEWAY_TOKEN>"

gateway:
  auth:
    jupyterhub:
      apiToken: "<DASK_GATEWAY_TOKEN>"
```

## Add Repositories

```bash
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo add dask https://helm.dask.org/
helm repo update
```

## Choose and Pin Chart Versions

Always pin versions explicitly to avoid drift (most especially the case with dask/dask-gateway - `use version 2022.6.1`).

```bash
helm search repo jupyterhub/jupyterhub --versions
helm search repo dask/dask-gateway --versions
```

Select one known-good version pair and pin it in commands below.

## Install JupyterHub

```bash
helm upgrade --install jupyterhub jupyterhub/jupyterhub \
  --namespace daskhub \
  --create-namespace \
  --version <JHUB_CHART_VERSION> \
  -f jhub-values.yaml \
  -f values-secrets.yaml
```

Notes:

- If your chosen JupyterHub chart version does not support `ingress.ingressClassName`, use this annotation instead:
  - `kubernetes.io/ingress.class: nginx`
- Keep `scheduling.userScheduler.enabled: false` unless you intentionally manage scheduler-image compatibility.

## Install Dask Gateway

```bash
helm upgrade --install dask-gateway dask/dask-gateway \
  --namespace daskhub \
  --version 2022.6.1 \
  -f dask-gateway-values.yaml \
  -f values-secrets.yaml
```

Important:

- For standalone `dask/dask-gateway`, the root key must be `gateway:`.
- Do not wrap it in `dask-gateway:` unless installing the `dask/daskhub` meta-chart.

## Validate Before Apply

```bash
helm lint jupyterhub/jupyterhub -f jhub-values.yaml
helm lint dask/dask-gateway -f dask-gateway-values.yaml

helm template jupyterhub jupyterhub/jupyterhub \
  --version <JHUB_CHART_VERSION> \
  -f jhub-values.yaml \
  -f values-secrets.yaml | kubectl apply --dry-run=server -f -

helm template dask-gateway dask/dask-gateway \
  --version 2022.6.1 \
  -f dask-gateway-values.yaml \
  -f values-secrets.yaml | kubectl apply --dry-run=server -f -
```

## Post-Install Checks

```bash
kubectl get pods -n daskhub
kubectl get ingress -n daskhub
kubectl get events -n daskhub --sort-by=.lastTimestamp
```

Logs:

```bash
kubectl logs -n daskhub deploy/hub
kubectl logs -n daskhub deploy/dask-gateway
kubectl logs -n daskhub deploy/traefik
```

## Common Issues

### 1) Helm ownership conflict (resource already owned by another release)

Error example:

- `... exists and cannot be imported ... meta.helm.sh/release-name ...`

Cause:

- Mixing release models (`daskhub` meta-chart and split `jupyterhub`/`dask-gateway`) in the same namespace.

Fix:

- Use one model only.
- For split model, keep releases named `jupyterhub` and `dask-gateway`.

### 2) `gateway.auth.jupyterhub.apiToken must be defined`

Cause:

- Wrong values shape for the chart being installed.

Fix:

- `dask/dask-gateway`: use `gateway.auth.jupyterhub.apiToken`.
- `dask/daskhub`: use `dask-gateway.gateway.auth.jupyterhub.apiToken`.

### 3) Ingress class shows `<none>` and users get 404

Cause:

- Ingress controller not matching your ingress.

Fix:

- Use `kubernetes.io/ingress.class: nginx` annotation (or `ingressClassName` if supported by selected chart).
- Verify controller logs for your host.

### 4) Hub CrashLoop with alembic revision errors

Error example:

- `Can't locate revision identified by ...`

Cause:

- Existing hub DB PVC from incompatible JupyterHub version.

Fix:

- Reuse a compatible chart version for that DB, or reset hub DB PVC if safe for your environment.

### 5) Singleuser error `Missing required environment $JUPYTERHUB_SERVICE_URL`

Cause:

- Notebook image `jupyterhub` package is incompatible with running Hub version.

Fix:

- Align singleuser image `jupyterhub` Python package with deployed Hub major version.

## Upgrade Procedure

1. Backup values and release state.
2. Pin target chart versions.
3. Run `helm diff` (if available).
4. Upgrade JupyterHub first, then Dask Gateway.
5. Validate logs and spawn test notebook + test Dask cluster creation.

## Quick Commands

```bash
# Show releases
helm list -n daskhub

# Show effective values
helm get values jupyterhub -n daskhub
helm get values dask-gateway -n daskhub

# Uninstall split model
helm uninstall dask-gateway -n daskhub
helm uninstall jupyterhub -n daskhub
```
