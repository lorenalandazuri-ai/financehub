variable "project_id" {
  description = "Proyecto de GCP del ambiente (xertica-financehub-dev, -hml o -prd)."
  type        = string
}

variable "environment" {
  description = "dev, hml o prd."
  type        = string
  validation {
    condition     = contains(["dev", "hml", "prd"], var.environment)
    error_message = "environment debe ser dev, hml o prd."
  }
}

variable "region" {
  description = "Región de Cloud Run, Artifact Registry y BigQuery."
  type        = string
  default     = "us-central1"
}

variable "domain" {
  description = "Dominio del portal (p. ej. financehub-dev.xertica.com). TI apunta su DNS a la IP del balanceador."
  type        = string
}

variable "access_members" {
  description = "Quién puede entrar por IAP, p. ej. [\"group:financehub-usuarios@xertica.com\"]."
  type        = list(string)
}

variable "web_image" {
  description = "Imagen inicial del servicio web. Después Cloud Build despliega y Terraform no la toca."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "api_image" {
  description = "Imagen inicial de api-catalogo. Después Cloud Build despliega y Terraform no la toca."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "max_instances" {
  description = "Máximo de instancias por servicio de Cloud Run."
  type        = number
  default     = 2
}

variable "catalog_dataset" {
  description = "Dataset de BigQuery con la tabla del catálogo."
  type        = string
  default     = "financehub"
}

variable "cloudbuild_repository" {
  description = "Repositorio de Cloud Build (2.ª gen.) que conecta Davy: projects/P/locations/R/connections/C/repositories/N. Vacío = no se crean triggers."
  type        = string
  default     = ""
}

variable "build_approvers" {
  description = "Quién aprueba los despliegues (solo aplica en hml y prd), p. ej. [\"user:lorena.landazuri@xertica.com\"]."
  type        = list(string)
  default     = []
}
