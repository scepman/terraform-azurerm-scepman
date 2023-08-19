variable "location" {
  type        = string
  description = "Azure Region where the resources should be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "law_name" {
  type        = string
  description = "Name for the Log Analytics Workspace"
}

variable "law_workspace_id" {
  type        = string
  default     = null
  description = "Workspace ID of the Log Analytics Workspace"
}

variable "law_shared_key" {
  type        = string
  default     = null
  description = "Primary or secondary shared key of Log Analytics Workspace"
}

variable "service_plan_name" {
  type        = string
  description = "Name of the service plan"
}

variable "service_plan_resource_id" {
  type        = string
  default     = null
  description = "Resource ID of the service plan"
}

variable "app_service_name_primary" {
  type        = string
  description = "Name of the primary app service"
}

variable "app_service_name_certificate_master" {
  type        = string
  description = "Name of the certificate master app service"
}

variable "key_vault_name" {
  type        = string
  description = "Name of the key vault"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource"
}

variable "artifacts_repository_url" {
  type        = string
  default     = "https://raw.githubusercontent.com/scepman/install/master"
  description = "URL of the repository containing the artifacts"
}

variable "app_settings_primary" {
  type        = map(string)
  default     = {}
  description = "A mapping of app settings to assign to the primary app service"
}

variable "app_settings_certificate_master" {
  type        = map(string)
  default     = {}
  description = "A mapping of app settings to assign to the certificate master app service"
}
