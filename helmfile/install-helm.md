# Install Helm (Ubuntu)

This guide installs Helm on Ubuntu Linux for operators managing `Test-Infra/helmfile`.

## Verify if Helm is already installed

```bash
helm version
```

If this returns a version, you can skip installation.

## Option 1: Official install script

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
helm version
```

## Option 2: APT repository install

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https curl gnupg
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm
```

Verify:

```bash
helm version
```

## Required plugin for this repo

Helmfile uses Helm diff operations. Install `helm-diff`:

```bash
helm plugin install https://github.com/databus23/helm-diff --verify=false
helm plugin list
```

## Next step

Proceed to [install-helmfile.md](./install-helmfile.md).
