module "github" {
  source = "./modules/github"
  count  = var.github != null ? 1 : 0

  project_id                      = google_project.bootstrap.project_id
  name_prefix                     = local.name_prefix
  repository_owner_id             = var.github.repository_owner_id
  foundation_repository_ids       = var.github.foundation_repository_ids
  workload_repository_ids         = var.github.workload_repository_ids
  default_branch_name             = var.github.default_branch_name
  tf_plan_service_account         = google_service_account.tf_plan.name
  tf_bootstrap_service_account    = google_service_account.tf_bootstrap.name
  tf_environment_service_accounts = { for environment, service_account in google_service_account.tf_environment : environment => service_account.name }

  depends_on = [google_project_service.bootstrap]
}
