locals {
  # Shared with cf-organization through the outputs, whose authoritative organisation IAM policy must keep the same roles
  tf_bootstrap_organization_roles = toset([
    # keep-sorted start
    "roles/accesscontextmanager.policyAdmin",
    "roles/billing.projectManager",
    "roles/cloudasset.viewer",
    "roles/compute.networkAdmin",
    "roles/compute.xpnAdmin",
    "roles/eventarc.admin",
    "roles/iam.denyAdmin",
    "roles/iam.organizationRoleAdmin",
    "roles/iam.securityAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/logging.configWriter",
    "roles/modelarmor.floorSettingsAdmin",
    "roles/monitoring.metricsScopesAdmin",
    "roles/orgpolicy.policyAdmin",
    "roles/pubsub.editor",
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.organizationViewer",
    "roles/resourcemanager.projectCreator",
    "roles/resourcemanager.projectMover",
    "roles/resourcemanager.tagAdmin",
    "roles/resourcemanager.tagUser",
    "roles/run.admin",
    "roles/securitycenter.notificationConfigEditor",
    "roles/workflows.editor",
    # keep-sorted end
  ])

  tf_plan_organization_roles = toset([
    # keep-sorted start
    "roles/accesscontextmanager.policyReader",
    "roles/iam.securityReviewer",
    "roles/modelarmor.floorSettingsViewer",
    "roles/reader",
    # keep-sorted end
  ])

  # tf-bootstrap manages the bootstrap project itself once the installer's grants are removed
  tf_bootstrap_project_roles = toset([
    # keep-sorted start
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
    # keep-sorted end
  ])
}

resource "google_service_account" "tf_bootstrap" {
  project      = google_project.bootstrap.project_id
  account_id   = "tf-bootstrap"
  display_name = "Bootstrap Terraform deployer"
  description  = "Applies the Cloud Foundations configurations."
}

resource "google_service_account" "tf_plan" {
  project      = google_project.bootstrap.project_id
  account_id   = "tf-plan"
  display_name = "Terraform planner"
  description  = "Plans the Cloud Foundations configurations, read-only."
}

resource "google_organization_iam_member" "tf_bootstrap" {
  for_each = local.tf_bootstrap_organization_roles

  org_id = var.organization_id
  role   = each.key
  member = google_service_account.tf_bootstrap.member
}

resource "google_organization_iam_member" "tf_plan" {
  for_each = local.tf_plan_organization_roles

  org_id = var.organization_id
  role   = each.key
  member = google_service_account.tf_plan.member
}

resource "google_project_iam_member" "tf_bootstrap" {
  for_each = local.tf_bootstrap_project_roles

  project = google_project.bootstrap.project_id
  role    = each.key
  member  = google_service_account.tf_bootstrap.member
}

resource "google_storage_bucket_iam_member" "foundations_state_tf_bootstrap" {
  bucket = google_storage_bucket.state["foundations"].name
  role   = "roles/storage.objectAdmin"
  member = google_service_account.tf_bootstrap.member
}

# Plans run without a state lock, so reading the state is enough
resource "google_storage_bucket_iam_member" "foundations_state_tf_plan" {
  bucket = google_storage_bucket.state["foundations"].name
  role   = "roles/storage.objectViewer"
  member = google_service_account.tf_plan.member
}

resource "google_service_account" "tf_environment" {
  for_each = local.environments

  project      = google_project.bootstrap.project_id
  account_id   = "tf-${each.value}"
  display_name = "Terraform deployer for the ${each.value} GCP environment"
  description  = "Applies the workload configurations of the ${each.key} environment."
}

resource "google_storage_bucket_iam_member" "state_tf_environment" {
  for_each = local.environments

  bucket = google_storage_bucket.state[each.key].name
  role   = "roles/storage.objectUser"
  member = google_service_account.tf_environment[each.key].member
}
