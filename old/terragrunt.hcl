remote_state {
  backend = "s3"
  config = {
    bucket                     = "opentofu-state"
    key                        = "${path_relative_to_include()}/terraform.tfstate"
    endpoint                   = "minio.example.local:9000"
    access_key                 = "MINIO_ACCESS_KEY"
    secret_key                 = "MINIO_SECRET_KEY"
    region                     = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style           = true
  }
}

# Centralized provider generation.
# This file will be written in every Terragrunt working dir as providers.tofu.
generate "providers" {
  path      = "providers.tofu"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.54.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 3.0.0"
    }
    minio = {
      source  = "aminueza/minio"
      version = "1.9.2"
    }
  }
}

# Provider configurations rely on environment variables or shared variables.
# Adjust to your environment (OS_*, RANCHER_URL, etc.).

provider "openstack" {
  # Typically uses OS_AUTH_URL, OS_USERNAME, OS_PASSWORD, OS_REGION_NAME, etc.
}

provider "rancher2" {
  # api_url and token_key can be set via env vars:
  #   RANCHER_URL, RANCHER_BEARER_TOKEN
}

provider "minio" {
  # For normal workloads you may not need MinIO provider here;
  # remote_state uses MinIO-compatible S3 endpoint already.
}
EOF
}

inputs = {
  env = "dev"
}
