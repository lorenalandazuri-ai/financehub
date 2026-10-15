variable "project_id" {
  description = "Proyecto de GCP del ambiente (co-xertica-financehub-dev o -prd)."
  type        = string
}

variable "environment" {
  description = "dev o prd."
  type        = string
  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "environment debe ser dev o prd."
  }
}

variable "region" {
  description = "Región de Cloud Run, Artifact Registry y BigQuery."
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Nombre del servicio de Cloud Run."
  type        = string
  default     = "financehub"
}

variable "image" {
  description = "Imagen inicial. Después Cloud Build despliega las versiones nuevas y Terraform no la toca."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "access_members" {
  description = "Quién puede entrar al portal por IAP, p. ej. [\"group:financehub-usuarios@xertica.com\"]."
  type        = list(string)
}

variable "max_instances" {
  description = "Máximo de instancias de Cloud Run."
  type        = number
  default     = 2
}

variable "catalog_dataset" {
  description = "Dataset de BigQuery con la tabla del catálogo."
  type        = string
  default     = "financehub"
}
