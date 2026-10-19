# Cuentas de servicio con lo mínimo que necesita cada una.

# Servicio web: solo sirve archivos estáticos, no necesita permisos.
resource "google_service_account" "web" {
  project      = var.project_id
  account_id   = "financehub-web"
  display_name = "FinanceHub web (Cloud Run)"
}

# api-catalogo: lee el catálogo de su propia imagen y verifica el JWT de IAP con claves públicas,
# así que tampoco necesita permisos.
resource "google_service_account" "api" {
  project      = var.project_id
  account_id   = "api-catalogo"
  display_name = "FinanceHub api-catalogo (Cloud Run)"
}

# Cloud Build: construye, publica y despliega. En hml y prd es la única vía de despliegue.
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
