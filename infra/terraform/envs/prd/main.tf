terraform {
  required_version = ">= 1.6"
  required_providers {
    google      = { source = "hashicorp/google", version = ">= 6.30, < 8.0" }
    google-beta = { source = "hashicorp/google-beta", version = ">= 6.30, < 8.0" }
  }

  # Cuando exista el proyecto: crear el bucket y descomentar.
  # gcloud storage buckets create gs://xertica-financehub-prd-tfstate --location=us-central1 --uniform-bucket-level-access
  # backend "gcs" {
  #   bucket = "xertica-financehub-prd-tfstate"
  #   prefix = "portal"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "portal" {
  source                = "../../modules/portal"
  project_id            = var.project_id
  environment           = "prd"
  region                = var.region
  domain                = var.domain
  access_members        = var.access_members
  cloudbuild_repository = var.cloudbuild_repository
  build_approvers       = var.build_approvers
}

output "portal_url" {
  value = module.portal.portal_url
}

output "lb_ip" {
  value = module.portal.lb_ip
}

output "image_repository" {
  value = module.portal.image_repository
}
