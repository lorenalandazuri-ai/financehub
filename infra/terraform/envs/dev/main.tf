terraform {
  required_version = ">= 1.6"
  required_providers {
    google      = { source = "hashicorp/google", version = ">= 6.30, < 8.0" }
    google-beta = { source = "hashicorp/google-beta", version = ">= 6.30, < 8.0" }
  }

  # Cuando exista el proyecto: crear el bucket y descomentar.
  # gcloud storage buckets create gs://co-xertica-financehub-dev-tfstate --location=us-central1 --uniform-bucket-level-access
  # backend "gcs" {
  #   bucket = "co-xertica-financehub-dev-tfstate"
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
  source         = "../../modules/portal"
  project_id     = var.project_id
  environment    = "dev"
  region         = var.region
  access_members = var.access_members
}

output "service_url" {
  value = module.portal.service_url
}

output "image_repository" {
  value = module.portal.image_repository
}
