module "hierarchy" {
  source  = "damsoncloud/cf-hierarchy/google"
  version = "0.1.0"

  organization_id = var.organization_id
}

module "bootstrap" {
  source = "../.."

  organization_id      = var.organization_id
  folder_id            = module.hierarchy.folders["common"]
  billing_account      = var.billing_account
  billing_admins_group = var.billing_admins_group
}
