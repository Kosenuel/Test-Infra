
# Protocoast Infra – Usage Guide

This guide explains how to use the **protocoast-infra** repository to deploy:

- OpenStack networking, bastion, and management nodes
- RKE2 management cluster (via Ansible)
- Day-0 bootstrap components (ingress-nginx, cert-manager, Argo CD via Helmfile)
- Platform components (ClusterIssuer, Cinder CSI, Rancher via Argo CD)
- Downstream RKE2 clusters (via OpenTofu + Rancher2 provider)
- Environment separation through Terragrunt (`dev`, `test`, `prod`)

---

## 1. Requirements

### Local machine / CI
- OpenTofu (`tofu`)
- Terragrunt
- Ansible 2.14+
- Helm + Helmfile
- Access to Rancher API (via VPN/Bastion)
- Access to OpenStack API (OS_* environment vars configured)

### Remote infrastructure
- MinIO endpoint reachable for OpenTofu state
- OpenStack tenant/project with permissions to manage:
  - networks
  - compute instances
  - floating IPs

---

## 2. Bootstrap the MinIO backend

Go to the bootstrap directory:

```bash
cd protocoast-infra/bootstrap
cp terraform.tfvars.example terraform.tfvars   # edit values
tofu init
tofu apply
```

This creates an S3-compatible bucket:
```
protocoast-opentofu-state
```

---

## 3. Terragrunt layout overview

Each environment (`dev`, `test`, `prod`) has:

```
live/<env>/
  ├── network/
  ├── compute/
  ├── bastion/
  └── rancher-mgmt/
```

Terragrunt will orchestrate dependencies automatically (e.g., compute waits for network outputs).

---

## 4. Provision an environment

### 4.1 Deploy the network

```bash
cd live/dev/network
terragrunt init
terragrunt apply
```

### 4.2 Deploy management nodes

```bash
cd ../compute
terragrunt apply
```

### 4.3 Deploy bastion host

```bash
cd ../bastion
terragrunt apply
```

### 4.4 Rancher downstream cluster creation

This step talks directly to Rancher via its API and:

- creates a **cloud credential**
- creates a **machine config**
- provisions an RKE2 cluster via Rancher machine pools

```bash
cd ../rancher-mgmt
terragrunt apply
```

---

## 5. Bootstrap the management cluster (RKE2)

Using Ansible:

```bash
cd protocoast-infra/ansible
ansible-playbook -i inventory/hosts.ini playbooks/setup_mgmt_cluster.yml
```

This installs:

- rke2-server on each mgmt node
- systemd services
- default config in `/etc/rancher/rke2/config.yaml`

---

## 6. Install bootstrap components via Helmfile

```bash
ansible-playbook -i inventory/hosts.ini playbooks/install_rancher.yml
```

This will:

1. Copy or sync the `helmfile/` directory to the management node
2. Run `helmfile apply` for day-0 components

Then apply the GitOps root app to let Argo CD manage platform components:

```bash
kubectl apply -f argocd/apps/platform-root.yaml
```

See:

```bash
docs/GITOPS_BOOTSTRAP.md
```

---

## 7. Access Rancher

Rancher is exposed through the management cluster, typically via a private ingress:

`https://rancher.protocoast.vm.fedcloud.eu`

Access requires either:

- VPN to the private network
- or SSH tunnel via Bastion

Example SSH tunnel:

```bash
ssh -L 8443:rancher.protocoast.vm.fedcloud.eu:443 ubuntu@<BASTION_IP>
```

Then open:

```
https://localhost:8443
```

---

## 8. Creating downstream clusters (automatic)

The module:

```
modules/rancher-mgmt
```

uses the Rancher2 provider, so clusters are automatically created when Terragrunt applies.

Cluster names follow the pattern:

```
k8s-dev
k8s-test
k8s-prod
```

All nodes are created by Rancher via OpenStack machine pools.

---

## 9. Destroying an environment

⚠️ Order matters — delete Rancher clusters before infrastructure:

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

---

## 10. Variables to configure

### 10.1 Rancher variables

Inside each env:

```
rancher_api_url   = "https://rancher.protocoast.vm.fedcloud.eu"
rancher_api_token = "token-xxxx:yyyyyyyy"
rancher_insecure  = true
```

### 10.2 OpenStack variables

```
os_username
os_password
os_auth_url
os_domain_name
os_project_name
openstack_image_name
openstack_flavor_name
openstack_network_name
openstack_security_groups
```

### 10.3 Environment-specific values

Examples in:

```
live/dev/rancher-mgmt/terragrunt.hcl
```

---

## 11. Notes and Best Practices

- Use **Vault or SOPS** for sensitive variables (OpenStack, Rancher tokens)
- Create one keypair per environment (`protocoast-dev-key`, etc.)
- Use a private DNS zone for cluster hostnames
- Keep Rancher behind Bastion/VPN at all times
- Always apply environment components in order:
  1. network
  2. compute
  3. bastion
  4. rancher-mgmt

---
