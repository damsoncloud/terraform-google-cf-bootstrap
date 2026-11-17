variable "folder_id" {
  description = "The `common` folder holding the bootstrap project, as `folders/<id>`, e.g. the `folders[\"common\"]` output of cf-hierarchy."
  type        = string

  validation {
    condition     = can(regex("^folders/[0-9]+$", var.folder_id))
    error_message = "The folder_id must be `folders/<id>`."
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

variable "project_id" {
  description = "ID of the bootstrap project. Generated as `cmn-cf-bootstrap-<suffix>`, with a random 4 hexadecimal characters suffix, when null; set it to keep the ID of an existing project."
  type        = string
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id must be 6-30 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "state_bucket_name" {
  description = "Name of the foundations state bucket. Generated as `cmn-cf-bootstrap-terraform-state-<suffix>`, with the suffix of a generated project ID, when null; set it to keep an existing bucket."
  type        = string
  default     = null

  validation {
    condition     = var.state_bucket_name == null || can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "The state_bucket_name must be a valid bucket name: 3-63 lowercase letters, digits, dots, hyphens or underscores, starting and ending with a letter or digit."
  }
}

variable "region" {
  description = "Region of the regional resources, e.g. the state buckets."
  type        = string
  default     = "europe-west4"
}
