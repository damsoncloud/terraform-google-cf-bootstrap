output "project_id" {
  description = "ID of the bootstrap project."
  value       = google_project.bootstrap.project_id
}

output "state_bucket" {
  description = "Name of the foundations state bucket."
  value       = google_storage_bucket.foundations_state.name
}
