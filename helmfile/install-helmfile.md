# Install Helmfile (Ubuntu)

This guide installs Helmfile on Ubuntu Linux for operators managing `Test-Infra/helmfile`.

## Prerequisite

Install Helm first: [install-helm.md](./install-helm.md)

## Verify if Helmfile is already installed

```bash
helmfile --version
```

If this returns a version, you can skip installation.

## Option 1: Install from release binary

Release page:

- https://github.com/helmfile/helmfile/releases

Download the latest Linux amd64 tarball and install:
<!-- 
```bash
VERSION=$(curl -s https://api.github.com/repos/helmfile/helmfile/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
wget https://github.com/helmfile/helmfile/releases/download/v${VERSION}/helmfile_${VERSION}_linux_amd64.tar.gz
tar -xzf helmfile_${VERSION}_linux_amd64.tar.gz
sudo mv helmfile /usr/local/bin/helmfile
sudo chmod +x /usr/local/bin/helmfile
``` -->

```bash
wget https://github.com/helmfile/helmfile/releases/download/v1.4.1/helmfile_1.4.1_linux_amd64.tar.gz

tar xzf helmfile_1.4.1_linux_amd64.tar.gz

sudo mv helmfile /usr/local/bin/

chmod +x /usr/local/bin/helmfile

helmfile version
# You should see a version 1.4.1 ...
#
```

Verify:

```bash
helmfile --version
```

## Repo bootstrap sanity checks

From `Protocoast-infra/helmfile`, you could run:

```bash
helmfile repos
helmfile lint
helmfile diff
```

If DNS/IPv6 issue appears, apply fix script:

```bash
source fix-helmfile-issue.sh
```

## Next step

Runbook and operations: [README.md](./README.md)
