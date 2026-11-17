variable "organization_id" {
  description = "ID of the organisation."
  type        = string
}

variable "billing_account" {
  description = "ID of the billing account."
  type        = string
}

variable "github_owner_id" {
  description = "ID of the GitHub organisation."
  type        = string
}

variable "foundation_repository_ids" {
  description = "IDs of the Cloud Foundations repositories."
  type        = list(string)
}

variable "workload_repository_ids" {
  description = "IDs of the workload repositories, by environment folder name."
  type        = map(list(string))
  default     = {}
}
