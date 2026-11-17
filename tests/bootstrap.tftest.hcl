mock_provider "google" {}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "a1b2"
    }
  }
}

variables {
  folder_id       = "folders/111111111111"
  billing_account = "012345-6789AB-CDEF01"
}

run "generated_names" {
  assert {
    condition     = google_project.bootstrap.project_id == "cmn-cf-bootstrap-a1b2" && output.project_id == "cmn-cf-bootstrap-a1b2"
    error_message = "The project ID must be generated as cmn-cf-bootstrap-<suffix>."
  }

  assert {
    condition     = google_storage_bucket.foundations_state.name == "cmn-cf-bootstrap-terraform-state-a1b2" && output.state_bucket == "cmn-cf-bootstrap-terraform-state-a1b2"
    error_message = "The state bucket name must be generated as cmn-cf-bootstrap-terraform-state-<suffix>."
  }
}

run "project" {
  command = plan

  variables {
    project_id = "cmn-cf-bootstrap-6703"
  }

  assert {
    condition     = google_project.bootstrap.project_id == "cmn-cf-bootstrap-6703" && google_project.bootstrap.name == "cmn-cf-bootstrap-6703"
    error_message = "A given project ID must be used as the project's ID and name."
  }

  assert {
    condition = (
      google_project.bootstrap.folder_id == "folders/111111111111" &&
      google_project.bootstrap.billing_account == "012345-6789AB-CDEF01" &&
      !google_project.bootstrap.auto_create_network
    )
    error_message = "The project must be created in the folder, with the billing account and without the default network."
  }
}

run "state_bucket" {
  command = plan

  variables {
    state_bucket_name = "cmn-cf-bootstrap-terraform-state-6703"
  }

  assert {
    condition     = google_storage_bucket.foundations_state.name == "cmn-cf-bootstrap-terraform-state-6703"
    error_message = "A given state bucket name must be used."
  }

  assert {
    condition = (
      google_storage_bucket.foundations_state.location == "europe-west4" &&
      google_storage_bucket.foundations_state.uniform_bucket_level_access &&
      google_storage_bucket.foundations_state.public_access_prevention == "enforced" &&
      !google_storage_bucket.foundations_state.force_destroy &&
      google_storage_bucket.foundations_state.versioning[0].enabled &&
      google_storage_bucket.foundations_state.soft_delete_policy[0].retention_duration_seconds == 0
    )
    error_message = "The state bucket must be regional, versioned, without soft delete, with uniform access, enforced public access prevention and no force_destroy."
  }
}

run "apis" {
  command = plan

  assert {
    condition     = contains(keys(google_project_service.bootstrap), "sts.googleapis.com") && contains(keys(google_project_service.bootstrap), "iamcredentials.googleapis.com")
    error_message = "The APIs of Workload Identity Federation must be enabled."
  }

  assert {
    condition     = alltrue([for service in google_project_service.bootstrap : !service.disable_on_destroy])
    error_message = "The APIs must not be disabled when removed from the configuration."
  }
}

run "invalid_folder_id" {
  command = plan

  variables {
    folder_id = "111111111111"
  }

  expect_failures = [var.folder_id]
}

run "invalid_billing_account" {
  command = plan

  variables {
    billing_account = "billingAccounts/012345-6789AB-CDEF01"
  }

  expect_failures = [var.billing_account]
}

run "invalid_state_bucket_name" {
  command = plan

  variables {
    state_bucket_name = "Terraform_State-"
  }

  expect_failures = [var.state_bucket_name]
}

run "invalid_project_id" {
  command = plan

  variables {
    project_id = "Bootstrap"
  }

  expect_failures = [var.project_id]
}
