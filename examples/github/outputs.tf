output "workload_identity_provider" {
  description = "Workload Identity Federation provider, for google-github-actions/auth in the repositories."
  value       = module.bootstrap.github_workload_identity_provider
}

output "tf_bootstrap_email" {
  description = "Email of the tf-bootstrap service account, impersonated from the default branch."
  value       = module.bootstrap.tf_bootstrap_email
}

output "tf_plan_email" {
  description = "Email of the tf-plan service account, impersonated from any ref."
  value       = module.bootstrap.tf_plan_email
}
