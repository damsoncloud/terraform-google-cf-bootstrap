locals {
  workload_repositories = {
    for pair in flatten([
      for environment, repository_ids in var.workload_repository_ids : [
        for repository_id in repository_ids : { environment = environment, repository_id = repository_id }
      ]
    ]) : "${pair.environment}/${pair.repository_id}" => pair
  }
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "${var.name_prefix}-gh"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.name_prefix}-gha"
  display_name                       = "GitHub Actions"
  description                        = "GitHub Actions integration with Google Cloud Platform"

  # Immutable IDs, so a renamed or recreated organisation or repository is not trusted
  attribute_condition = "assertion.repository_owner_id == '${var.repository_owner_id}'"
  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.repository"          = "assertion.repository"
    "attribute.repository_id"       = "assertion.repository_id"
    "attribute.repository_id_ref"   = "assertion.repository_id + '@' + assertion.ref"
    "attribute.repository_owner_id" = "assertion.repository_owner_id"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "tf_plan" {
  for_each = toset(var.foundation_repository_ids)

  service_account_id = var.tf_plan_service_account
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository_id/${each.key}"
}

resource "google_service_account_iam_member" "tf_bootstrap" {
  for_each = toset(var.foundation_repository_ids)

  service_account_id = var.tf_bootstrap_service_account
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository_id_ref/${each.key}@refs/heads/${var.default_branch_name}"
}

resource "google_service_account_iam_member" "tf_environment" {
  for_each = local.workload_repositories

  service_account_id = var.tf_environment_service_accounts[each.value.environment]
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository_id/${each.value.repository_id}"
}
