variable "organization_id" {
  description = "ID of the organisation."
  type        = string
}

variable "billing_account" {
  description = "ID of the billing account."
  type        = string
}

variable "billing_admins_group" {
  description = "Email of the group administering the billing account."
  type        = string
  default     = null
}
