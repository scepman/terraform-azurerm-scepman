variable "location" {
  type        = string
  description = "Azure Region where the resources should be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default = "rg-scepman-quickstart-001"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource"
}

variable "subscription_id" {
  description = "The Subscription ID for the Azure account."
  type        = string
}