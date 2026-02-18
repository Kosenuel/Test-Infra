terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "1.9.2"
    }
  }
}

variable "minio_endpoint" {
  type        = string
  description = "MinIO endpoint URL, e.g. https://minio.example.local:9000"
}

variable "minio_access_key" {
  type        = string
  description = "Access key for MinIO"
}

variable "minio_secret_key" {
  type        = string
  description = "Secret key for MinIO"
}

provider "minio" {
  minio_server   = var.minio_endpoint
  minio_user     = var.minio_access_key
  minio_password = var.minio_secret_key
  ssl            = true
}

resource "minio_s3_bucket" "tfstate" {
  bucket = "opentofu-state"
  acl    = "private"

  versioning {
    enabled = true
  }
}

output "bucket_name" {
  value = minio_s3_bucket.tfstate.bucket
}
