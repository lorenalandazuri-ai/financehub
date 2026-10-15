output "service_url" {
  description = "URL del portal."
  value       = google_cloud_run_v2_service.portal.uri
}

output "image_repository" {
  description = "Repositorio de imágenes para Cloud Build."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "run_service_account" {
  value = google_service_account.run.email
}

output "catalog_table" {
  value = "${var.project_id}.${google_bigquery_dataset.catalog.dataset_id}.${google_bigquery_table.reports.table_id}"
}
