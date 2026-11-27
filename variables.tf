variable "organization_id" {
  description = "ID of the organisation, where the deployer service accounts are granted their roles."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "The organization_id must be the numeric organisation ID."
  }
}

variable "folders" {
  description = <<-EOT
  The folders by folder name, e.g. the `folders` output of cf-hierarchy:
    `id`, the resource name (`folders/<id>`);
    `short_name`, the environment's short name, null for folders other than environments;
    `common`, whether it is the common environment.
  The bootstrap project is created in the common environment's folder and its generated names start with its short name;
  each environment gets a `tf-<short name>` deployer service account with its own state bucket.
  EOT
  type = map(object({
    id         = string
    short_name = optional(string)
    common     = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for folder in values(var.folders) : can(regex("^folders/[0-9]+$", folder.id))])
    error_message = "Each folder's id must be `folders/<id>`."
  }

  validation {
    condition     = length([for folder in values(var.folders) : folder if folder.common && folder.short_name != null]) == 1 && length([for folder in values(var.folders) : folder if folder.common]) == 1
    error_message = "Exactly one folder must be the common environment, with a short name."
  }

  validation {
    condition     = alltrue([for folder in values(var.folders) : folder.short_name == null || can(regex("^[a-z][a-z0-9-]{1,25}[a-z0-9]$", folder.short_name))])
    error_message = "Each short name must be 3-27 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }

  validation {
    condition     = length(distinct(compact([for folder in values(var.folders) : folder.short_name]))) == length(compact([for folder in values(var.folders) : folder.short_name]))
    error_message = "The short names must be unique."
  }

  validation {
    condition     = try(var.folders["foundations"].short_name, null) == null
    error_message = "No environment may be named foundations, the key of the foundations state bucket."
  }
}

variable "billing_account" {
  description = "ID of the billing account of the bootstrap project, e.g. `012345-6789AB-CDEF01`."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$", var.billing_account))
    error_message = "The billing_account must be a billing account ID, e.g. `012345-6789AB-CDEF01`."
  }
}

variable "billing_admins_group" {
  description = "Email of the group administering the billing account, e.g. `gcp-billing-admins@example.com`. No group is granted when null."
  type        = string
  default     = null

  validation {
    condition     = var.billing_admins_group == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.billing_admins_group))
    error_message = "The billing_admins_group must be an email address."
  }
}

variable "project_id" {
  description = <<-EOT
  ID of the bootstrap project.
  Generated as `<common short name>-cf-bootstrap-<suffix>`, e.g. `cmn-cf-bootstrap-<suffix>`, with a random 4 hexadecimal characters suffix, when null;
  set it to keep the ID of an existing project.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id must be 6-30 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "state_bucket_name" {
  description = <<-EOT
  Name of the foundations state bucket.
  Generated as `<common short name>-cf-bootstrap-terraform-state-<suffix>`, with the suffix of a generated project ID, when null; set it to keep an existing bucket.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.state_bucket_name == null || can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "The state_bucket_name must be a valid bucket name: 3-63 lowercase letters, digits, dots, hyphens or underscores, starting and ending with a letter or digit."
  }
}

variable "additional_organizations" {
  description = <<-EOT
  Further organisations sharing the bootstrap project, by a key of 1-10 lowercase letters, digits or hyphens, suffixing the names of their deployers, e.g. `net`:
    `organization_id`, the ID of the organisation, where `tf-bootstrap` and `tf-plan` are granted their organisation roles too;
    `folders`, as the `folders` input, e.g. the `folders` output of the organisation's cf-hierarchy;
    each environment gets a `tf-<short name>-<key>` deployer service account with its own state bucket;
    `billing_account`, the ID of the billing account of the organisation's projects, administered by `tf-bootstrap` and viewed by `tf-plan`; the bootstrap project's when null;
    `billing_admins_group`, the email of the group administering that billing account; no group is granted when null.
  EOT
  type = map(object({
    organization_id = string
    folders = map(object({
      id         = string
      short_name = optional(string)
      common     = optional(bool, false)
    }))
    billing_account      = optional(string)
    billing_admins_group = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_organizations) : can(regex("^[a-z]([a-z0-9-]{0,8}[a-z0-9])?$", key))])
    error_message = "Each organisation key must be 1-10 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }

  validation {
    condition = alltrue([for organization in values(var.additional_organizations) : can(regex("^[0-9]+$", organization.organization_id))]) && length(distinct(concat(
      [var.organization_id], [for organization in values(var.additional_organizations) : organization.organization_id]
    ))) == length(var.additional_organizations) + 1
    error_message = "Each organization_id must be the numeric ID of an organisation other than organization_id and the other further organisations."
  }

  validation {
    condition = alltrue(flatten([
      for organization in values(var.additional_organizations) : [
        for folder in values(organization.folders) : can(regex("^folders/[0-9]+$", folder.id)) && (folder.short_name == null || can(regex("^[a-z][a-z0-9-]{1,25}[a-z0-9]$", folder.short_name)))
      ]
    ]))
    error_message = "Each folder's id must be `folders/<id>`, and each short name 3-27 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }

  # The deployers' service account IDs are limited to 30 characters and must not collide with each other
  validation {
    condition = alltrue(flatten([
      for key, organization in var.additional_organizations : [for folder in values(organization.folders) : length("tf-${folder.short_name}-${key}") <= 30 if folder.short_name != null]
    ]))
    error_message = "Each deployer's service account ID, `tf-<short name>-<key>`, must not exceed 30 characters: shorten the organisation's key or the short name."
  }

  validation {
    condition = length(distinct(concat(
      compact([for folder in values(var.folders) : folder.short_name]),
      flatten([for key, organization in var.additional_organizations : [for folder in values(organization.folders) : "${folder.short_name}-${key}" if folder.short_name != null]]),
      ))) == length(compact([for folder in values(var.folders) : folder.short_name])) + length(flatten([
      for organization in values(var.additional_organizations) : compact([for folder in values(organization.folders) : folder.short_name])
    ]))
    error_message = "The deployers' names, `<short name>` in the organisation and `<short name>-<key>` in the further organisations, must be unique."
  }

  validation {
    condition = alltrue(flatten([
      for organization in values(var.additional_organizations) : [
        organization.billing_account == null || can(regex("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$", organization.billing_account)),
        organization.billing_admins_group == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", organization.billing_admins_group)),
      ]
    ]))
    error_message = "Each billing_account must be a billing account ID, e.g. `012345-6789AB-CDEF01`, and each billing_admins_group an email address."
  }
}

variable "region" {
  description = "Region of the regional resources, e.g. the state buckets."
  type        = string
  default     = "europe-west4"
}

variable "github" {
  description = <<-EOT
  GitHub Actions integration through Workload Identity Federation; not set up when null:
    `repository_owner_id`, the ID of the GitHub organisation, the only one trusted;
    `foundation_repository_ids`, the IDs of the Cloud Foundations repositories, impersonating `tf-plan` from any ref and `tf-bootstrap` from the default branch;
    `workload_repository_ids`, the IDs of the workload repositories by environment folder name, or `<key>/<folder name>` in the further organisations,
      impersonating the environment's deployer from any ref;
    `default_branch_name`, the default branch of the Cloud Foundations repositories.
  EOT
  type = object({
    repository_owner_id       = string
    foundation_repository_ids = optional(list(string), [])
    workload_repository_ids   = optional(map(list(string)), {})
    default_branch_name       = optional(string, "main")
  })
  default = null
}
