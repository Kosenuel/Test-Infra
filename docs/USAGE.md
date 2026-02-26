# Usage Guide (Internal Operators)

This guide covers the operational flow for provisioning infrastructure and operating the management cluster.

## Stack Summary

- OpenTofu + Terragrunt: OpenStack infrastructure and environment orchestration
- Ansible: RKE2 management cluster bootstrap
- Helmfile (Day-0): ingress-nginx, cert-manager, argo-cd, rancher
- Argo CD (Day-1+): ClusterIssuer, Cinder CSI, JupyterHub, Dask Gateway
- Rancher2 provider: downstream cluster lifecycle in `live/<env>/rancher-mgmt`

## Prerequisites

- OpenTofu (`tofu`)
- Terragrunt
- Ansible 2.14+
- Helm and Helmfile
- kubectl access to management cluster
- OpenStack credentials (`OS_*`)
- Access to Rancher endpoint through bastion/VPN

## Provision an Environment

```bash
cd live/dev/network
terragrunt init
terragrunt apply

cd ../compute
terragrunt apply

cd ../bastion
terragrunt apply

cd ../rancher-mgmt
terragrunt apply
```

## Bootstrap Management Cluster (RKE2)

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/setup_mgmt_cluster.yml
```

## Install Day-0 Components

```bash
cd helmfile
helmfile --selector name=ingress-nginx apply
helmfile --selector name=cert-manager apply
helmfile --selector name=argo-cd apply
helmfile --selector name=rancher apply
```

Or apply all releases:

```bash
helmfile sync
```

## Bootstrap Argo CD Root

```bash
kubectl apply -f argocd/bootstrap/main-root.yaml
```

## Verify Platform State

```bash
kubectl get applications -n argocd
kubectl get clusterissuer letsencrypt-prod
kubectl get pods -n kube-system | grep -i cinder
kubectl get pods -n daskhub
kubectl get pods -n cattle-system
```

## Access Rancher

Rancher URL:

`https://rancher.protocoast.vm.fedcloud.eu`

Example bastion tunnel:

```bash
ssh -L 8443:rancher.protocoast.vm.fedcloud.eu:443 ubuntu@<BASTION_IP>
```

Then open `https://localhost:8443`.

## Destroy Order

Destroy Rancher-managed clusters first:

```bash
cd live/dev/rancher-mgmt
terragrunt destroy

cd ../bastion
terragrunt destroy

cd ../compute
terragrunt destroy

cd ../network
terragrunt destroy
```

## Configuration Notes

- Store secrets outside Git (Vault/SOPS/External Secrets).
- Keep chart versions pinned and upgrade by PR.
- Keep Rancher access private (VPN or bastion only).

## Canonical Repository URLs

- HTTPS: `https://github.com/CMCC-Foundation/protocoast-infra`
- SSH: `git@github.com:CMCC-Foundation/protocoast-infra.git`
