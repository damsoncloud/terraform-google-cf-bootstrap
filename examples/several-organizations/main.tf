module "hierarchy" {
  source  = "damsoncloud/cf-hierarchy/google"
  version = "0.2.0"

  organization_id = var.organization_id
}

module "additional_hierarchies" {
  source   = "damsoncloud/cf-hierarchy/google"
  version  = "0.2.0"
  for_each = var.additional_organizations

  organization_id = each.value.organization_id
}

module "bootstrap" {
  source = "../.."

  organization_id = var.organization_id
  folders         = module.hierarchy.folders
  billing_account = var.billing_account

  additional_organizations = {
    for key, organization in var.additional_organizations : key => {
      organization_id = organization.organization_id
      folders         = module.additional_hierarchies[key].folders
      billing_account = organization.billing_account
    }
  }
}
