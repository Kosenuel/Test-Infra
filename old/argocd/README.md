# Argo CD Layout

## Root app

- `apps/platform-root.yaml`: app-of-apps entrypoint

## Child apps

- `apps/platform/00-project.yaml`: `AppProject` for platform components
- `apps/platform/10-cluster-issuer-app.yaml`
- `apps/platform/20-cinder-csi-app.yaml`
- `apps/platform/30-rancher-app.yaml`

## Managed manifests

- `platform/cluster-issuer/`: `ClusterIssuer letsencrypt-prod`
- `platform/cinder-csi/examples/`: manual secret templates (placeholders only)

Bootstrap and recovery flow is documented in `docs/GITOPS_BOOTSTRAP.md`.

Notes:

- Git repo URL is SSH-based: `git@github.com:CMCC-Foundation/protocoast-infra.git`
- Add SSH credentials in Argo CD before syncing root app.
