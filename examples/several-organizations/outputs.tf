output "tf_environment_emails" {
  description = "Emails of the organisation's deployers, by environment folder name."
  value       = module.bootstrap.tf_environment_emails
}

output "additional_organizations" {
  description = "Deployers and state buckets of the further organisations, by organisation key."
  value       = module.bootstrap.additional_organizations
}
