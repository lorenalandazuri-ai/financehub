# Cuentas de servicio con lo mínimo que necesita cada una.

# Servicio web: solo sirve archivos estáticos, no necesita permisos.
resource "google_service_account" "web" {
  project      = var.project_id
  account_id   = "financehub-web"
  display_name = "FinanceHub web (Cloud Run)"
}

# api-catalogo: lee la tabla del catálogo.
resource "google_service_account" "api" {
  project      = var.project_id
  account_id   = "api-catalogo"
  display_name = "FinanceHub api-catalogo (Cloud Run)"
}

resource "google_project_iam_member" "api_bq_jobs" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = google_service_account.api.member
}

resource "google_bigquery_dataset_iam_member" "api_reads_catalog" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.catalog.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = google_service_account.api.member
}

# Cloud Build: construye, publica y despliega. En prd es la única vía de despliegue.
resource "google_service_account" "deployer" {
  project      = var.project_id
  account_id   = "financehub-deployer"
  display_name = "FinanceHub despliegue (Cloud Build)"
}

resource "google_project_iam_member" "deployer" {
  for_each = toset([
    "roles/run.developer",
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
  ])
  project = var.project_id
  role    = each.value
  member  = google_service_account.deployer.member
}

# Para desplegar un servicio que corre con otra cuenta, hay que poder "actuar como" esa cuenta.
resource "google_service_account_iam_member" "deployer_acts_as" {
  for_each = {
    web = google_service_account.web.name
    api = google_service_account.api.name
  }
  service_account_id = each.value
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.deployer.member
}
