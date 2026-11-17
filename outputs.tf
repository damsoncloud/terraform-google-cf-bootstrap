output "project_id" {
  description = "ID of the bootstrap project."
  value       = google_project.bootstrap.project_id
}

output "state_bucket" {
  description = "Name of the foundations state bucket."
  value       = google_storage_bucket.state["foundations"].name
}

output "tf_bootstrap_email" {
  description = "Email of the `tf-bootstrap` service account, applying the Cloud Foundations configurations."
  value       = google_service_account.tf_bootstrap.email
}

output "tf_plan_email" {
  description = "Email of the `tf-plan` service account, planning the Cloud Foundations configurations."
  value       = google_service_account.tf_plan.email
}

output "tf_bootstrap_organization_roles" {
  description = "Organisation roles of `tf-bootstrap`, which the authoritative organisation IAM policy of cf-organization must keep."
  value       = sort(local.tf_bootstrap_organization_roles)
}

output "tf_plan_organization_roles" {
  description = "Organisation roles of `tf-plan`, which the authoritative organisation IAM policy of cf-organization must keep."
  value       = sort(local.tf_plan_organization_roles)
}

output "tf_environment_emails" {
  description = "Emails of the `tf-<short name>` deployer service accounts, by environment folder name."
  value       = { for environment, service_account in google_service_account.tf_environment : environment => service_account.email }
}

output "tf_environment_state_buckets" {
  description = "Names of the deployers' state buckets, by environment folder name."
  value       = { for environment in keys(var.environments) : environment => google_storage_bucket.state[environment].name }
}
