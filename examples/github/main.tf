module "hierarchy" {
  source  = "damsoncloud/cf-hierarchy/google"
  version = "0.1.0"

  organization_id = var.organization_id
}

module "bootstrap" {
  source = "../.."

  organization_id = var.organization_id
  folder_id       = module.hierarchy.folders["common"]
  billing_account = var.billing_account

  github = {
    repository_owner_id       = var.github_owner_id
    foundation_repository_ids = var.foundation_repository_ids
    workload_repository_ids   = var.workload_repository_ids
  }
}
