variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "access_members" {
  type = list(string)
}

variable "domain" {
  type = string
}

variable "cloudbuild_repository" {
  type    = string
  default = ""
}

variable "build_approvers" {
  type    = list(string)
  default = []
}
