# Argo CD Layout

## Bootstrap

- `bootstrap/main-root.yaml`: root `Application` entrypoint
- `bootstrap/main/kustomization.yaml`: bundles projects and ApplicationSets

## Projects

- `projects/platform-project.yaml`: platform workloads (issuer, cinder-csi, rancher)
- `projects/data-project.yaml`: data workloads (jupyterhub, dask-gateway)

## ApplicationSets

- `applicationsets/platform-cluster-issuer.main.yaml`
- `applicationsets/platform-cinder-csi.main.yaml`
- `applicationsets/platform-rancher.main.yaml`
- `applicationsets/data-jupyterhub.main.yaml`
- `applicationsets/data-dask-gateway.main.yaml`

Each ApplicationSet uses a list generator. Add cluster entries there to scale to
more clusters.

## Workloads

- `workloads/platform/cluster-issuer/`: `ClusterIssuer letsencrypt-prod`
- `workloads/platform/cinder-csi/examples/`: manual secret templates

Bootstrap and recovery flow is documented in `docs/GITOPS_BOOTSTRAP.md`.

Notes:

- Git repo URL: `https://github.com/Kosenuel/Test-Infra`
- Add SSH credentials in Argo CD before syncing the root app.
