variable "subscription_id" {
  description = "The Subscription ID for the Azure account."
  type        = string
}

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

variable "storage_account_public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Allow public network access to the storage account."
}

variable "storage_account_trusted_services_enabled" {
  type        = bool
  default     = false
  description = "Enable trusted Microsoft services to bypass storage account network rules."
}

variable "storage_account_min_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "Minimum TLS version for the storage account endpoint."
}

variable "storage_account_shared_access_key_enabled" {
  type        = bool
  default     = false
  description = "Enable shared access key authentication for the storage account. Default is false to enforce more secure authentication methods."
}

variable "storage_account_allow_nested_items_to_be_public" {
  type        = bool
  default     = false
  description = "Allow nested items (containers) to inherit public access."
}

variable "storage_account_sas_expiration_period" {
  type        = string
  default     = "1.00:00:00"
  description = "Expiration period applied to SAS tokens in d.hh:mm:ss format."
}

variable "storage_account_blob_soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "Retention in days for blob soft delete. Set to 0 to keep soft delete disabled."
}

variable "storage_account_container_soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "Retention in days for container soft delete. Set to 0 to keep soft delete disabled."
}

variable "storage_account_managed_identity_enabled" {
  type        = bool
  default     = false
  description = "Assign a system managed identity to the storage account for Customer Managed Keys."
}

variable "law_name" {
  type        = string
  default     = null
  description = "Name for the Log Analytics Workspace"
}

variable "law_resource_group_name" {
  type        = string
  default     = null
  description = "Ressource Group of existing Log Analytics Workspace"
}

variable "law_cross_subscription_details" {
  type = object({
    id           = string
    workspace_id = string
    shared_key   = string
  })
  default     = null
  nullable    = true
  description = "Used to reference an existing Log Analytics Workspace located in another subscription. Use this instead of law_name and law_resource_group_name."
  validation {
    condition     = var.law_cross_subscription_details == null || can(regex("^/subscriptions/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.law_cross_subscription_details.id))
    error_message = "When provided, law_cross_subscription_details.id must be a valid Log Analytics workspace resource ID."
  }
  validation {
    condition     = var.law_cross_subscription_details == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.law_cross_subscription_details.workspace_id))
    error_message = "When provided, law_cross_subscription_details.workspace_id must be a UUID."
  }
  validation {
    condition     = var.law_cross_subscription_details == null || length(trimspace(var.law_cross_subscription_details.shared_key)) > 0
    error_message = "When provided, law_cross_subscription_details.shared_key must be non-empty."
  }
  validation {
    condition     = var.law_cross_subscription_details == null || (var.law_name == null && var.law_resource_group_name == null)
    error_message = "When law_cross_subscription_details is provided, leave law_name and law_resource_group_name unset."
  }
  validation {
    condition     = var.law_cross_subscription_details != null || var.law_name != null
    error_message = "Set law_name when using workspaces from the current subscription."
  }
}

variable "service_plan_name" {
  type        = string
  description = "Name of the service plan"
}

variable "service_plan_os_type" {
  type    = string
  default = "Windows"
  validation {
    condition     = can(regex("Windows|Linux", var.service_plan_os_type))
    error_message = "service_plan_os_type must be either 'Windows' or 'Linux'"
  }
  description = "The type of operating system to use for the app service plan. Possible values are 'Windows' or 'Linux'."
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

variable "app_service_minimum_tls_version_scepman" {
  type        = string
  default     = "1.2"
  description = "Minimum Inbound TLS Version for SCEPman core App Service"

  validation {
    condition     = contains(["1.0", "1.1", "1.2", "1.3"], var.app_service_minimum_tls_version_scepman)
    error_message = "The TLS version must be one of: 1.0, 1.1, 1.2, or 1.3."
  }
}

variable "app_service_minimum_tls_version_certificate_master" {
  type        = string
  default     = "1.3"
  description = "Minimum Inbound TLS Version for Certificate Master App Service"

  validation {
    condition     = contains(["1.0", "1.1", "1.2", "1.3"], var.app_service_minimum_tls_version_certificate_master)
    error_message = "The TLS version must be one of: 1.0, 1.1, 1.2, or 1.3."
  }
}
