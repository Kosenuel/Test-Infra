# Contributing

This repository is operated by platform engineering and DevOps teams for internal infrastructure.

## Workflow

1. Create a branch from `main`.
2. Make focused changes (infra, automation, or docs).
3. Validate locally where applicable.
4. Open a pull request with change summary and rollout impact.

## Pull Request Expectations

- Clear problem statement and scope
- Affected environments (`dev`, `test`, `prod`)
- Rollback plan for operational changes
- Updated documentation for behavior changes

## Validation Checklist

- Terragrunt/OpenTofu plans reviewed
- Helmfile changes reviewed for release impact
- Argo CD manifests linted/validated
- Secrets not committed to Git

## Commit and Branch Naming

Use descriptive names, for example:

- `feat/argocd-data-appset-tuning`
- `fix/helmfile-rancher-release-values`
- `docs/bootstrap-runbook-refresh`

## Security

Never commit production credentials, tokens, or private keys.
Use approved secret-management paths.
