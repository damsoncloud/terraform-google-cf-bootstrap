output "project_id" {
  description = "ID of the bootstrap project."
  value       = module.bootstrap.project_id
}

output "state_bucket" {
  description = "Name of the foundations state bucket."
  value       = module.bootstrap.state_bucket
}

output "tf_bootstrap_email" {
  description = "Email of the tf-bootstrap service account."
  value       = module.bootstrap.tf_bootstrap_email
}
