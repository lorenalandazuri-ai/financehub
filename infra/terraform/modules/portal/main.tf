data "google_project" "this" {
  project_id = var.project_id
}

locals {
  apis = [
    "run.googleapis.com",
    "iap.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "bigquery.googleapis.com",
    "iam.googleapis.com",
  ]

  iap_service_agent = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-iap.iam.gserviceaccount.com"
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

# ---------- Identidad del servicio ----------
resource "google_service_account" "run" {
  project      = var.project_id
  account_id   = "${var.service_name}-run"
  display_name = "FinanceHub (Cloud Run)"
}

# Solo lectura del catálogo y permiso para correr consultas.
resource "google_project_iam_member" "run_bq_jobs" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = google_service_account.run.member
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
  deletion_protection = var.environment == "prd"
}

resource "google_bigquery_dataset_iam_member" "run_reads_catalog" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.catalog.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = google_service_account.run.member
}

# ---------- Servicio ----------
# iap_enabled aparece en la documentación con google-beta y launch_stage BETA.
resource "google_cloud_run_v2_service" "portal" {
  provider     = google-beta
  launch_stage = "BETA"
  project      = var.project_id
  name         = var.service_name
  location     = var.region
  ingress      = "INGRESS_TRAFFIC_ALL"

  # IAP directo en Cloud Run, sin balanceador (ahorra ~US$19 al mes por ambiente).
  iap_enabled         = true
  deletion_protection = var.environment == "prd"

  template {
    service_account = google_service_account.run.email
    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }
    containers {
      image = var.image
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
      env {
        name  = "IAP_AUDIENCE"
        value = "/projects/${data.google_project.this.number}/locations/${var.region}/services/${var.service_name}"
      }
    }
  }

  # Cloud Build despliega las imágenes nuevas; Terraform no las revierte.
  lifecycle {
    ignore_changes = [template[0].containers[0].image, client, client_version]
  }

  depends_on = [google_project_service.apis]
}

# IAP llama al servicio en nombre del usuario: su agente necesita run.invoker.
resource "google_cloud_run_v2_service_iam_member" "iap_invoker" {
  project    = var.project_id
  location   = var.region
  name       = google_cloud_run_v2_service.portal.name
  role       = "roles/run.invoker"
  member     = local.iap_service_agent
  depends_on = [google_project_service_identity.iap]
}

# Quién puede entrar al portal.
resource "google_iap_web_cloud_run_service_iam_member" "access" {
  provider               = google-beta
  for_each               = toset(var.access_members)
  project                = var.project_id
  location               = var.region
  cloud_run_service_name = google_cloud_run_v2_service.portal.name
  role                   = "roles/iap.httpsResourceAccessor"
  member                 = each.value
}
