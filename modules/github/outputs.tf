output "workload_identity_provider" {
  description = "Name of the Workload Identity Federation provider, for `google-github-actions/auth`."
  value       = google_iam_workload_identity_pool_provider.this.name
}
