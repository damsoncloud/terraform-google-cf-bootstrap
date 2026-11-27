locals {
  additional_billing_accounts = toset([
    for organization in values(var.additional_organizations) : organization.billing_account
    if organization.billing_account != null && organization.billing_account != var.billing_account
  ])

  # Keyed by billing account and group, as organisations may share both
  additional_billing_admins = {
    for pair in distinct([
      for organization in values(var.additional_organizations) : { billing_account = coalesce(organization.billing_account, var.billing_account), group = organization.billing_admins_group }
      if organization.billing_admins_group != null
    ]) : "${pair.billing_account}/${pair.group}" => pair
    if !(pair.billing_account == var.billing_account && pair.group == var.billing_admins_group)
  }
}

# Granting billing.viewer to the billing disabler requires administering the billing account; this also covers linking projects and managing budgets
resource "google_billing_account_iam_member" "tf_bootstrap" {
  billing_account_id = var.billing_account
  role               = "roles/billing.admin"
  member             = google_service_account.tf_bootstrap.member
}

resource "google_billing_account_iam_member" "tf_plan" {
  billing_account_id = var.billing_account
  role               = "roles/billing.viewer"
  member             = google_service_account.tf_plan.member
}

resource "google_billing_account_iam_member" "billing_admins" {
  count = var.billing_admins_group != null ? 1 : 0

  billing_account_id = var.billing_account
  role               = "roles/billing.admin"
  member             = "group:${var.billing_admins_group}"
}

# The billing accounts of the further organisations, other than the bootstrap project's
resource "google_billing_account_iam_member" "tf_bootstrap_additional_organizations" {
  for_each = local.additional_billing_accounts

  billing_account_id = each.key
  role               = "roles/billing.admin"
  member             = google_service_account.tf_bootstrap.member
}

resource "google_billing_account_iam_member" "tf_plan_additional_organizations" {
  for_each = local.additional_billing_accounts

  billing_account_id = each.key
  role               = "roles/billing.viewer"
  member             = google_service_account.tf_plan.member
}

resource "google_billing_account_iam_member" "billing_admins_additional_organizations" {
  for_each = local.additional_billing_admins

  billing_account_id = each.value.billing_account
  role               = "roles/billing.admin"
  member             = "group:${each.value.group}"
}
