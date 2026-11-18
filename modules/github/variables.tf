variable "project_id" {
  description = "ID of the project holding the Workload Identity Federation pool, e.g. the bootstrap project."
  type        = string
}

variable "name_prefix" {
  description = "Prefix of the pool's and provider's IDs, `<prefix>-gh` and `<prefix>-gha`, e.g. `cmn-cf-bootstrap`."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,26}[a-z0-9]$", var.name_prefix))
    error_message = "The name_prefix must be 4-28 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "repository_owner_id" {
  description = "ID of the GitHub organisation, the only one trusted."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.repository_owner_id))
    error_message = "The repository_owner_id must be the numeric ID of the GitHub organisation."
  }
}

variable "foundation_repository_ids" {
  description = "IDs of the Cloud Foundations repositories, impersonating `tf-plan` from any ref and `tf-bootstrap` from the default branch."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for repository_id in var.foundation_repository_ids : can(regex("^[0-9]+$", repository_id))])
    error_message = "The foundation_repository_ids must be numeric GitHub repository IDs."
  }
}

variable "workload_repository_ids" {
  description = "IDs of the workload repositories, by environment folder name, impersonating the environment's deployer from any ref."
  type        = map(list(string))
  default     = {}

  validation {
    condition     = alltrue([for repository_id in flatten(values(var.workload_repository_ids)) : can(regex("^[0-9]+$", repository_id))])
    error_message = "The workload_repository_ids must be numeric GitHub repository IDs."
  }

  validation {
    condition     = alltrue([for environment in keys(var.workload_repository_ids) : contains(keys(var.tf_environment_service_accounts), environment)])
    error_message = "The workload_repository_ids must be keyed by environments of the tf_environment_service_accounts input."
  }
}

variable "default_branch_name" {
  description = "Default branch of the Cloud Foundations repositories, the only ref impersonating `tf-bootstrap`."
  type        = string
  default     = "main"

  validation {
    condition     = can(regex("^[^\\s]+$", var.default_branch_name))
    error_message = "The default_branch_name must be a branch name, without whitespace."
  }
}

variable "tf_plan_service_account" {
  description = "Resource name of the `tf-plan` service account, `projects/<project>/serviceAccounts/<email>`."
  type        = string
}

variable "tf_bootstrap_service_account" {
  description = "Resource name of the `tf-bootstrap` service account, `projects/<project>/serviceAccounts/<email>`."
  type        = string
}

variable "tf_environment_service_accounts" {
  description = "Resource names of the environment deployer service accounts, by environment folder name."
  type        = map(string)
  default     = {}
}
