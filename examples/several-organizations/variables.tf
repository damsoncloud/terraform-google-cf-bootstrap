variable "organization_id" {
  description = "ID of the organisation holding the bootstrap project."
  type        = string
}

variable "billing_account" {
  description = "ID of the billing account of the bootstrap project."
  type        = string
}

variable "additional_organizations" {
  description = "Further organisations sharing the bootstrap project, by the key suffixing their deployers' names: their IDs and billing accounts."
  type = map(object({
    organization_id = string
    billing_account = optional(string)
  }))
}
