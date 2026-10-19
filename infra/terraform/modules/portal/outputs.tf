output "portal_url" {
  description = "URL del portal."
  value       = "https://${var.domain}"
}

output "lb_ip" {
  description = "IP del balanceador. TI crea un registro A del dominio hacia esta IP."
  value       = google_compute_global_address.lb.address
}

output "image_repository" {
  description = "Repositorio de imágenes para Cloud Build."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "deployer_service_account" {
  value = google_service_account.deployer.email
}
