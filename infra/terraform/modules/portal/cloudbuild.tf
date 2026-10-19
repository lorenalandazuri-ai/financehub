# Triggers de Cloud Build. Se crean cuando Davy conecte el repositorio (var.cloudbuild_repository).
# dev: despliega con cada push a main. hml y prd: despliegan con cada tag v*, solo con aprobación.

locals {
  create_trigger = var.cloudbuild_repository != ""
}

resource "google_cloudbuild_trigger" "deploy" {
  count           = local.create_trigger ? 1 : 0
  project         = var.project_id
  location        = var.region
  name            = "financehub-deploy-${var.environment}"
  description     = local.protected ? "Despliegue a ${var.environment} (requiere aprobación)" : "Despliegue a dev con cada push a main"
  filename        = "cloudbuild.yaml"
  service_account = google_service_account.deployer.id

  repository_event_config {
    repository = var.cloudbuild_repository
    push {
      branch = local.protected ? null : "^main$"
      tag    = local.protected ? "^v.*$" : null
    }
  }

  substitutions = {
    _REGION = var.region
  }

  approval_config {
    approval_required = local.protected
  }
}

resource "google_project_iam_member" "build_approvers" {
  for_each = local.protected ? toset(var.build_approvers) : toset([])
  project  = var.project_id
  role     = "roles/cloudbuild.builds.approver"
  member   = each.value
}
