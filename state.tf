resource "google_storage_bucket" "foundations_state" {
  project                     = google_project.bootstrap.project_id
  name                        = local.state_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  # Object versioning already keeps the previous states
  soft_delete_policy {
    retention_duration_seconds = 0
  }

  depends_on = [google_project_service.bootstrap]
}
