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
