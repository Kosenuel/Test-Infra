# protocoast-infra

Infrastructure-as-Code repository for ProtoCoast platform operations on OpenStack.

This repository is intended for internal operators and provides:

- OpenStack infrastructure provisioning with OpenTofu and Terragrunt
- RKE2 management-cluster bootstrap with Ansible
- Management-plane platform deployment with Helmfile
- GitOps-managed platform/data workloads with Argo CD
- Downstream cluster lifecycle through the Rancher2 provider

## Deployment Model

The stack uses a two-layer control model:

1. Day-0 (Helmfile)
- ingress-nginx
- cert-manager
- argo-cd
- rancher

2. Day-1+ (Argo CD)
- platform ClusterIssuer
- OpenStack Cinder CSI
- JupyterHub
- Dask Gateway

This split avoids Argo CD bootstrap dependency issues while keeping platform/data workloads reconciled by GitOps.

## Repository URL Convention

Canonical HTTPS URL:

`https://github.com/CMCC-Foundation/protocoast-infra`

Canonical SSH URL:

`git@github.com:CMCC-Foundation/protocoast-infra.git`

these are the URLs consistently used in our docs, manifests, and operator commands.

## High-Level Operator Flow

1. Bootstrap remote state backend (`bootstrap/`).
2. Provision infrastructure for an environment (`live/<env>/...`).
3. Bootstrap RKE2 management cluster with Ansible.
4. Install Day-0 components with Helmfile.
5. Register Git repository in Argo CD and apply root app.
6. Verify platform/data applications and Rancher health.

## Key Paths

- `bootstrap/`: state-backend bootstrap
- `live/`: Terragrunt environment stacks
- `ansible/`: management-cluster setup playbooks
- `helmfile/`: Day-0 releases and values
- `argocd/`: projects, ApplicationSets, and workload definitions
- `docs/`: operator documentations/runbook

## Quick Start 

<!-- ```bash
cd bootstrap
tofu init
tofu apply

cd ../live/dev/network
terragrunt init
terragrunt apply
cd ../compute && terragrunt apply
cd ../bastion && terragrunt apply
cd ../rancher-mgmt && terragrunt apply

cd ../../../ansible
ansible-playbook -i inventory/hosts.ini playbooks/setup_mgmt_cluster.yml
ansible-playbook -i inventory/hosts.ini playbooks/install_rancher.yml

cd ../helmfile
helmfile sync -->

After setting up your infrastructure using terraform, 
ssh into the mgmt cluster, 
pull this repo and run

```bash
cd ../helmfile
helmfile sync

kubectl apply -f ../argocd/bootstrap/main-root.yaml
```

## Documentation Index

- `docs/USAGE.md`: end-to-end operations guide
- `docs/GITOPS_BOOTSTRAP.md`: Argo CD bootstrap and recovery doc/runbook
- `argocd/README.md`: Argo CD layout and ownership boundaries

## Operational Notes

- Keep credentials out of Git. Use secure secret delivery for runtime values.
- Chart and app versions are pinned; upgrade by PR in non-prod first.
- If you remove Argo resources from `argocd/kustomization.yaml`, Argo may prune them automatically.
