# Tests of the modules/github submodule, called directly
mock_provider "google" {
  mock_resource "google_iam_workload_identity_pool" {
    defaults = {
      name = "projects/123/locations/global/workloadIdentityPools/cmn-cf-bootstrap-gh"
    }
  }
}

variables {
  project_id                   = "cmn-cf-bootstrap-a1b2"
  name_prefix                  = "cmn-cf-bootstrap"
  repository_owner_id          = "1000"
  tf_plan_service_account      = "projects/cmn-cf-bootstrap-a1b2/serviceAccounts/tf-plan@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
  tf_bootstrap_service_account = "projects/cmn-cf-bootstrap-a1b2/serviceAccounts/tf-bootstrap@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
  tf_environment_service_accounts = {
    production       = "projects/cmn-cf-bootstrap-a1b2/serviceAccounts/tf-prod@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
    "net/production" = "projects/cmn-cf-bootstrap-a1b2/serviceAccounts/tf-prod-net@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
  }
  foundation_repository_ids = ["2001", "2002"]
  workload_repository_ids   = { production = ["3001"], "net/production" = ["3002"] }
}

run "trust" {
  command = plan

  module {
    source = "./modules/github"
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.github.attribute_condition == "assertion.repository_owner_id == '1000'"
    error_message = "Only tokens of the GitHub organisation, by its ID, must be accepted."
  }

  assert {
    condition     = google_iam_workload_identity_pool.github.project == "cmn-cf-bootstrap-a1b2" && google_iam_workload_identity_pool.github.workload_identity_pool_id == "cmn-cf-bootstrap-gh"
    error_message = "The pool must be created in the given project, with an ID starting with the given prefix."
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.github.workload_identity_pool_provider_id == "cmn-cf-bootstrap-gha"
    error_message = "The provider's ID must start with the given prefix."
  }
}

run "impersonation" {
  module {
    source = "./modules/github"
  }

  assert {
    condition = (
      google_service_account_iam_member.tf_plan["2001"].member == "principalSet://iam.googleapis.com/projects/123/locations/global/workloadIdentityPools/cmn-cf-bootstrap-gh/attribute.repository_id/2001" &&
      google_service_account_iam_member.tf_plan["2001"].service_account_id == var.tf_plan_service_account
    )
    error_message = "The foundations repositories must impersonate tf-plan from any ref."
  }

  assert {
    condition = (
      google_service_account_iam_member.tf_bootstrap["2002"].member == "principalSet://iam.googleapis.com/projects/123/locations/global/workloadIdentityPools/cmn-cf-bootstrap-gh/attribute.repository_id_ref/2002@refs/heads/main" &&
      google_service_account_iam_member.tf_bootstrap["2002"].service_account_id == var.tf_bootstrap_service_account
    )
    error_message = "The foundations repositories must impersonate tf-bootstrap from main only."
  }

  assert {
    condition = (
      keys(google_service_account_iam_member.tf_environment) == ["net/production/3002", "production/3001"] &&
      google_service_account_iam_member.tf_environment["net/production/3002"].service_account_id == var.tf_environment_service_accounts["net/production"] &&
      google_service_account_iam_member.tf_environment["production/3001"].service_account_id == var.tf_environment_service_accounts["production"] &&
      endswith(google_service_account_iam_member.tf_environment["production/3001"].member, "/attribute.repository_id/3001")
    )
    error_message = "A workload repository must impersonate only its environment's deployer, from any ref."
  }

  assert {
    condition     = output.workload_identity_provider == google_iam_workload_identity_pool_provider.github.name
    error_message = "The provider name must be returned."
  }
}

run "default_branch" {
  command = plan

  module {
    source = "./modules/github"
  }

  variables {
    default_branch_name = "master"
  }

  assert {
    condition     = endswith(google_service_account_iam_member.tf_bootstrap["2001"].member, "/attribute.repository_id_ref/2001@refs/heads/master")
    error_message = "tf-bootstrap must be impersonated from the given default branch only."
  }
}

run "workload_repositories_of_unknown_environment" {
  command = plan

  module {
    source = "./modules/github"
  }

  variables {
    workload_repository_ids = { sandbox = ["3001"] }
  }

  expect_failures = [var.workload_repository_ids]
}

run "invalid_repository_owner_id" {
  command = plan

  module {
    source = "./modules/github"
  }

  variables {
    repository_owner_id = "damsoncloud"
  }

  expect_failures = [var.repository_owner_id]
}

run "invalid_repository_ids" {
  command = plan

  module {
    source = "./modules/github"
  }

  variables {
    foundation_repository_ids = ["cf-bootstrap"]
    workload_repository_ids   = { production = ["cf-workload"] }
  }

  expect_failures = [var.foundation_repository_ids, var.workload_repository_ids]
}

run "invalid_default_branch_name" {
  command = plan

  module {
    source = "./modules/github"
  }

  variables {
    default_branch_name = ""
  }

  expect_failures = [var.default_branch_name]
}

run "invalid_name_prefix" {
  command = plan

  module {
    source = "./modules/github"
  }

  variables {
    name_prefix = "common-environment-cf-bootstrap"
  }

  expect_failures = [var.name_prefix]
}
