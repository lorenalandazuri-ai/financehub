data "google_project" "this" {
  project_id = var.project_id
}

locals {
  apis = [
    "run.googleapis.com",
    "compute.googleapis.com",
    "iap.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "bigquery.googleapis.com",
    "iam.googleapis.com",
  ]

  web_service       = "financehub-web"
  api_service       = "api-catalogo"
  iap_service_agent = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-iap.iam.gserviceaccount.com"

  # hml es la antesala de prd: misma protección contra borrado y despliegue con aprobación.
  protected = contains(["hml", "prd"], var.environment)
}

resource "google_project_service" "apis" {
  for_each           = toset(local.apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# El agente de servicio de IAP no existe hasta que se pide explícitamente.
resource "google_project_service_identity" "iap" {
  provider   = google-beta
  project    = var.project_id
  service    = "iap.googleapis.com"
  depends_on = [google_project_service.apis]
}

# ---------- Imágenes ----------
resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.region
  repository_id = "financehub"
  format        = "DOCKER"
  description   = "Imágenes del portal FinanceHub"

  cleanup_policies {
    id     = "keep-last-10"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  depends_on = [google_project_service.apis]
}

# ---------- Catálogo ----------
resource "google_bigquery_dataset" "catalog" {
  project     = var.project_id
  dataset_id  = var.catalog_dataset
  location    = var.region
  description = "Catálogo de tableros del portal FinanceHub (solo enlaces, sin datos)."
  depends_on  = [google_project_service.apis]
}

resource "google_bigquery_table" "reports" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.catalog.dataset_id
  table_id            = "reports"
  description         = "Un registro por tablero: país, módulo, enlace y estado."
  schema              = file("${path.module}/../../../../catalog/reports_schema.json")
  deletion_protection = local.protected
}

# ---------- Servicios de Cloud Run ----------
# Solo aceptan tráfico del balanceador; IAP los llama con su agente de servicio.
resource "google_cloud_run_v2_service" "web" {
  project             = var.project_id
  name                = local.web_service
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  deletion_protection = local.protected

  template {
    service_account = google_service_account.web.email
    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }
    containers {
      image = var.web_image
      resources {
        limits = { cpu = "1", memory = "256Mi" }
      }
    }
  }

  # Cloud Build despliega las imágenes nuevas; Terraform no las revierte.
  lifecycle {
    ignore_changes = [template[0].containers[0].image, client, client_version]
  }

  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_v2_service" "api" {
  project             = var.project_id
  name                = local.api_service
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  deletion_protection = local.protected

  template {
    service_account = google_service_account.api.email
    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }
    containers {
      image = var.api_image
      resources {
        limits = { cpu = "1", memory = "512Mi" }
      }
      env {
        name  = "CATALOG_SOURCE"
        value = "bigquery"
      }
      env {
        name  = "BQ_REPORTS_TABLE"
        value = "${var.project_id}.${google_bigquery_dataset.catalog.dataset_id}.${google_bigquery_table.reports.table_id}"
      }
      # La API verifica que el JWT de IAP venga de su propio backend del balanceador.
      env {
        name  = "IAP_AUDIENCE"
        value = "/projects/${data.google_project.this.number}/global/backendServices/${google_compute_backend_service.api.generated_id}"
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0].image, client, client_version]
  }

  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_v2_service_iam_member" "iap_invokes_web" {
  project    = var.project_id
  location   = var.region
  name       = google_cloud_run_v2_service.web.name
  role       = "roles/run.invoker"
  member     = local.iap_service_agent
  depends_on = [google_project_service_identity.iap]
}

resource "google_cloud_run_v2_service_iam_member" "iap_invokes_api" {
  project    = var.project_id
  location   = var.region
  name       = google_cloud_run_v2_service.api.name
  role       = "roles/run.invoker"
  member     = local.iap_service_agent
  depends_on = [google_project_service_identity.iap]
}
