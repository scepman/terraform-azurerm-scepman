variable "organization_name" {
  type        = string
  default     = "my-org"
  description = "Organization name (O=<my-org>)"
}

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

variable "law_resource_group_name" {
  type        = string
  default     = null
  description = "Ressource Group of existing Log Analytics Workspace"
}

variable "service_plan_name" {
  type        = string
  description = "Name of the service plan"
}

variable "service_plan_sku" {
  type        = string
  default     = "S1"
  description = "SKU for App Service Plan"
}

variable "service_plan_resource_id" {
  type        = string
  default     = null
  description = "Resource ID of the service plan"
}

variable "enable_application_insights" {
  type        = bool
  default     = false
  description = "Should Terraform create and connect Application Insights for the App services? NOTE: This will prevent Terraform from beeing able to destroy the ressource group!"
}

variable "app_service_retention_in_days" {
  type        = number
  default     = 90
  description = "How many days http_logs should be kept"
}

variable "app_service_retention_in_mb" {
  type        = number
  default     = 35
  description = "Max file size of http_logs"
}

variable "app_service_logs_detailed_error_messages" {
  type        = bool
  default     = true
  description = "Detailed Error messages of the app service"
}

variable "app_service_logs_failed_request_tracing" {
  type        = bool
  default     = false
  description = "Trace failed requests"
}

variable "app_service_application_logs_file_system_level" {
  type        = string
  default     = "Error"
  description = "Application Log level for file_system"
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

variable "vnet_name" {
  type        = string
  default     = "vnet-scepman"
  description = "Name of the VNET created for internal communication"
}

variable "vnet_address_space" {
  type        = list(any)
  default     = ["10.158.200.0/24"]
  description = "Address-Space of the VNET"
}

variable "subnet_appservices_name" {
  type        = string
  default     = "snet-scepman-appservices"
  description = "Name of the subnet created for integrating the App Services"
}

variable "subnet_endpoints_name" {
  type        = string
  default     = "snet-scepman-endpoints"
  description = "Name of the subnet created for the other endpoints"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource"
}

variable "artifacts_url_primary" {
  type        = string
  default     = "https://raw.githubusercontent.com/scepman/install/master/dist/Artifacts.zip"
  description = "URL of the artifacts for SCEPman"
}

variable "artifacts_url_certificate_master" {
  type        = string
  default     = "https://raw.githubusercontent.com/scepman/install/master/dist-certmaster/CertMaster-Artifacts.zip"
  description = "URL of the artifacts for SCEPman Certificate Master"
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
