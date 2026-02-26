# Argo CD Layout

This directory contains Argo CD projects, root bootstrap, and ApplicationSets for Day-1+ workloads.

## Bootstrap

- `bootstrap/main-root.yaml`: root `Application` that points to `argocd/`
- `kustomization.yaml`: lists all Argo-managed project and ApplicationSet manifests

## Projects

- `projects/platform-project.yaml`: platform workloads (ClusterIssuer, Cinder CSI)
- `projects/data-project.yaml`: data workloads (JupyterHub, Dask Gateway)

## ApplicationSets

- `applicationsets/platform-cluster-issuer.main.yaml`
- `applicationsets/platform-cinder-csi.main.yaml`
- `applicationsets/data-jupyterhub.main.yaml`
- `applicationsets/data-dask-gateway.main.yaml`

Each ApplicationSet currently uses a list generator with one cluster (`main`). Add generator entries to scale to more clusters.

## Workloads

- `workloads/platform/cluster-issuer/`: cert-manager ClusterIssuer manifest
- `workloads/platform/cinder-csi/`: Cinder CSI values and required secret examples
- `workloads/data/`: JupyterHub and Dask Gateway values

## Repository URL Convention

- HTTPS: `https://github.com/CMCC-Foundation/protocoast-infra`
- SSH: `git@github.com:CMCC-Foundation/protocoast-infra.git`

## Important Behavior

Argo CD only deploys files included by `argocd/kustomization.yaml`. A file present under `argocd/` but missing from that kustomization is not applied by the root app.

If a previously managed resource is removed from `argocd/kustomization.yaml`, Argo may prune it when automated pruning is enabled.
