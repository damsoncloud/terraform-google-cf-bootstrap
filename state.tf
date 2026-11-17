# The foundations state bucket and one state bucket per environment deployer
resource "google_storage_bucket" "state" {
  for_each = local.state_buckets

  project                     = google_project.bootstrap.project_id
  name                        = each.value
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
