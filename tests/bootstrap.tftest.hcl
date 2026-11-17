mock_provider "google" {
  mock_resource "google_service_account" {
    defaults = {
      member = "serviceAccount:tf@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
    }
  }
}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "a1b2"
    }
  }
}

variables {
  organization_id = "123456789012"
  folder_id       = "folders/111111111111"
  billing_account = "012345-6789AB-CDEF01"
}

run "generated_names" {
  assert {
    condition     = google_project.bootstrap.project_id == "cmn-cf-bootstrap-a1b2" && output.project_id == "cmn-cf-bootstrap-a1b2"
    error_message = "The project ID must be generated as cmn-cf-bootstrap-<suffix>."
  }

  assert {
    condition     = google_storage_bucket.state["foundations"].name == "cmn-cf-bootstrap-terraform-state-a1b2" && output.state_bucket == "cmn-cf-bootstrap-terraform-state-a1b2"
    error_message = "The state bucket name must be generated as cmn-cf-bootstrap-terraform-state-<suffix>."
  }

  assert {
    condition = output.tf_environment_state_buckets == {
      certification = "cert-cf-terraform-state-a1b2"
      common        = "cmn-cf-terraform-state-a1b2"
      development   = "dev-cf-terraform-state-a1b2"
      production    = "prod-cf-terraform-state-a1b2"
    }
    error_message = "Each environment must have a state bucket named <short name>-cf-terraform-state-<suffix>."
  }

  assert {
    condition = alltrue([for environment, binding in google_storage_bucket_iam_member.state_tf_environment :
      binding.bucket == google_storage_bucket.state[environment].name && binding.member == google_service_account.tf_environment[environment].member
    ])
    error_message = "Each deployer must have access to its own state bucket only."
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
    condition     = google_storage_bucket.state["foundations"].name == "cmn-cf-bootstrap-terraform-state-6703"
    error_message = "A given state bucket name must be used."
  }

  assert {
    condition = (
      google_storage_bucket.state["foundations"].location == "europe-west4" &&
      google_storage_bucket.state["foundations"].uniform_bucket_level_access &&
      google_storage_bucket.state["foundations"].public_access_prevention == "enforced" &&
      !google_storage_bucket.state["foundations"].force_destroy &&
      google_storage_bucket.state["foundations"].versioning[0].enabled &&
      google_storage_bucket.state["foundations"].soft_delete_policy[0].retention_duration_seconds == 0
    )
    error_message = "The state bucket must be regional, versioned, without soft delete, with uniform access, enforced public access prevention and no force_destroy."
  }
}

run "service_accounts" {
  command = plan

  assert {
    condition     = google_service_account.tf_bootstrap.account_id == "tf-bootstrap" && google_service_account.tf_plan.account_id == "tf-plan"
    error_message = "The tf-bootstrap and tf-plan service accounts must be created."
  }

  assert {
    condition     = alltrue([for binding in merge(google_organization_iam_member.tf_bootstrap, google_organization_iam_member.tf_plan) : binding.org_id == "123456789012"])
    error_message = "The organisation roles must be granted in the organisation."
  }

  assert {
    condition     = length(setintersection(keys(google_organization_iam_member.tf_plan), ["roles/owner", "roles/editor"])) == 0 && !anytrue([for role in keys(google_organization_iam_member.tf_plan) : endswith(role, "Admin")])
    error_message = "tf-plan must only have read-only organisation roles."
  }

  assert {
    condition     = google_storage_bucket_iam_member.foundations_state_tf_bootstrap.role == "roles/storage.objectAdmin" && google_storage_bucket_iam_member.foundations_state_tf_plan.role == "roles/storage.objectViewer"
    error_message = "tf-bootstrap must manage and tf-plan only read the foundations state."
  }
}

run "service_account_members_and_outputs" {
  assert {
    condition = alltrue(concat(
      [for binding in google_organization_iam_member.tf_bootstrap : binding.member == google_service_account.tf_bootstrap.member],
      [for binding in google_project_iam_member.tf_bootstrap : binding.member == google_service_account.tf_bootstrap.member && binding.project == "cmn-cf-bootstrap-a1b2"],
      [for binding in google_organization_iam_member.tf_plan : binding.member == google_service_account.tf_plan.member],
    ))
    error_message = "Each role must be granted to its service account."
  }

  assert {
    condition     = output.tf_bootstrap_organization_roles == sort(keys(google_organization_iam_member.tf_bootstrap)) && output.tf_plan_organization_roles == sort(keys(google_organization_iam_member.tf_plan))
    error_message = "The role outputs must list the granted organisation roles."
  }
}

run "environment_deployers" {
  command = plan

  assert {
    condition     = { for environment, service_account in google_service_account.tf_environment : environment => service_account.account_id } == { certification = "tf-cert", common = "tf-cmn", development = "tf-dev", production = "tf-prod" }
    error_message = "Each environment must have a tf-<short name> deployer."
  }

  assert {
    condition     = alltrue([for binding in google_storage_bucket_iam_member.state_tf_environment : binding.role == "roles/storage.objectUser"])
    error_message = "The deployers must only use the objects of their state bucket."
  }

  assert {
    condition = alltrue([for bucket in google_storage_bucket.state :
      bucket.versioning[0].enabled && bucket.soft_delete_policy[0].retention_duration_seconds == 0 && bucket.public_access_prevention == "enforced"
    ])
    error_message = "The deployers' state buckets must have the settings of the foundations state bucket."
  }
}

run "billing" {
  command = plan

  variables {
    billing_admins_group = "gcp-billing-admins@example.com"
  }

  assert {
    condition = (
      google_billing_account_iam_member.tf_bootstrap.role == "roles/billing.admin" &&
      google_billing_account_iam_member.tf_plan.role == "roles/billing.viewer" &&
      google_billing_account_iam_member.billing_admins[0].member == "group:gcp-billing-admins@example.com" &&
      google_billing_account_iam_member.billing_admins[0].role == "roles/billing.admin"
    )
    error_message = "tf-bootstrap and the billing admins group must administer, and tf-plan only view, the billing account."
  }

  assert {
    condition = alltrue([for binding in [google_billing_account_iam_member.tf_bootstrap, google_billing_account_iam_member.tf_plan, google_billing_account_iam_member.billing_admins[0]] :
      binding.billing_account_id == "012345-6789AB-CDEF01"
    ])
    error_message = "The billing roles must be granted on the billing account."
  }
}

run "billing_without_admins_group" {
  command = plan

  assert {
    condition     = length(google_billing_account_iam_member.billing_admins) == 0
    error_message = "No group must be granted without billing_admins_group."
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

run "invalid_organization_id" {
  command = plan

  variables {
    organization_id = "organizations/123456789012"
  }

  expect_failures = [var.organization_id]
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

run "invalid_environment_short_name" {
  command = plan

  variables {
    environments = { development = "Dev" }
  }

  expect_failures = [var.environments]
}

run "duplicate_environment_short_names" {
  command = plan

  variables {
    environments = { development = "dev", dev = "dev" }
  }

  expect_failures = [var.environments]
}

run "foundations_as_environment" {
  command = plan

  variables {
    environments = { foundations = "fnd" }
  }

  expect_failures = [var.environments]
}

run "invalid_billing_admins_group" {
  command = plan

  variables {
    billing_admins_group = "gcp-billing-admins"
  }

  expect_failures = [var.billing_admins_group]
}

run "invalid_project_id" {
  command = plan

  variables {
    project_id = "Bootstrap"
  }

  expect_failures = [var.project_id]
}
