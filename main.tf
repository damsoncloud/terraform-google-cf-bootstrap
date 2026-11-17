locals {
  project_id = coalesce(var.project_id, "cmn-cf-bootstrap-${random_id.suffix.hex}")
  state_buckets = merge(
    { foundations = coalesce(var.state_bucket_name, "cmn-cf-bootstrap-terraform-state-${random_id.suffix.hex}") },
    { for environment, short_name in var.environments : environment => "${short_name}-cf-terraform-state-${random_id.suffix.hex}" },
  )

  # The deployer service accounts live in this project, so the APIs they call at the organisation level are enabled here too
  apis = toset([
    # keep-sorted start
    "accesscontextmanager.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "essentialcontacts.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "orgpolicy.googleapis.com",
    "pubsub.googleapis.com",
    "securitycenter.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
    # keep-sorted end
  ])
}

# Makes the globally unique names of the generated project ID and buckets unique
resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_project" "bootstrap" {
  name                = local.project_id
  project_id          = local.project_id
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}

resource "google_project_service" "bootstrap" {
  for_each = local.apis

  project            = google_project.bootstrap.project_id
  service            = each.key
  disable_on_destroy = false
}
