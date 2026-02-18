# protocoast-infra

Infrastructure-as-Code stack for **OpenStack + RKE2 + Rancher** using:

- **OpenTofu** for infrastructure and Rancher integration
- **Terragrunt** for environment orchestration (`dev`, `test`, `prod`)
- **Ansible** to bootstrap the RKE2 *management cluster* on OpenStack VMs
- **Helmfile** for Day-0 bootstrap:
  - `ingress-nginx`
  - `cert-manager`
  - `ArgoCD`
- **ArgoCD** for Day-1+ platform GitOps:
  - `ClusterIssuer`
  - `OpenStack Cinder CSI`
  - `Rancher`
- **Rancher2 provider** to create **downstream RKE2 clusters on OpenStack** for each env

## High-level flow

1. **Bootstrap**: create MinIO bucket for OpenTofu state (`bootstrap/`).
2. **Provision infra per-env** (`live/dev|test|prod/...` via Terragrunt):
   - OpenStack network + subnet
   - Bastion host
   - Management nodes VMs for RKE2 + Rancher
3. **Configure management cluster** with Ansible:
   - install **RKE2** on management nodes
   - install **Helmfile** and apply Day-0 bootstrap
   - deploy platform components through ArgoCD app-of-apps
4. **Provision downstream clusters** via Rancher2 provider:
   - one RKE2 cluster per environment (e.g. `k8s-dev`, `k8s-test`, `k8s-prod`)
   - VMs automatically created on OpenStack by Rancher

Detailed bootstrap/runbook:

- `docs/GITOPS_BOOTSTRAP.md`

## Directory structure

```text
protocoast-infra/
├── README.md
├── bootstrap/
│   └── main.tofu
├── terragrunt.hcl
├── live/
│   ├── dev/
│   ├── test/
│   └── prod/
├── ansible/
│   ├── inventory/
│   ├── playbooks/
│   ├── roles/
│   └── ...
├── helmfile/
│   ├── helmfile.yaml
│   └── values/
│       ├── cert-manager.yaml
│       ├── rancher.yaml
│       └── argocd.yaml
└── docs/
    └── diagram.txt
```

## Usage overview

1. **Bootstrap state backend** (MinIO):

   ```bash
   cd bootstrap
   tofu init
   tofu apply
   ```

2. **Provision infra for one env (e.g. dev)**:

   ```bash
   cd live/dev/network
   terragrunt init
   terragrunt apply

   cd ../compute
   terragrunt apply

   cd ../bastion
   terragrunt apply

   cd ../rancher-mgmt
   terragrunt apply   # creates Rancher cloud credential + dev downstream cluster
   ```

3. **Bootstrap RKE2 management cluster** (from your laptop / CI):

   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts.ini playbooks/setup_mgmt_cluster.yml
   ansible-playbook -i inventory/hosts.ini playbooks/install_rancher.yml
   ```

4. **Access Rancher** through bastion/VPN, verify clusters, then hook
   up ArgoCD to your app repos.
