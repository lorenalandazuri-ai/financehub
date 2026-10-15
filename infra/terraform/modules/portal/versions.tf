terraform {
  required_version = ">= 1.6"
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.30, < 8.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 6.30, < 8.0"
    }
  }
}
