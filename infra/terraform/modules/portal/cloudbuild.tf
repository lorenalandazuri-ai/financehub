# Triggers de Cloud Build. Se crean cuando Davy conecte el repositorio (var.cloudbuild_repository).
# dev: despliega con cada push a main. hml: tag v1.2.0-rc1. prd: tag v1.2.0. Ambos solo con aprobación.
# Tags distintos para que una versión pase primero por hml y no se despliegue en los dos a la vez.

locals {
  create_trigger = var.cloudbuild_repository != ""
  release_tag = {
    hml = "^v[0-9]+\\.[0-9]+\\.[0-9]+-rc[0-9]+$"
    prd = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
  }
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
      tag    = lookup(local.release_tag, var.environment, null)
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
