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

variable "storage_account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Storage account replication type. Valid options are LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Storage account replication type must be one of: LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  }
}

variable "storage_account_public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Allow public network access to the storage account. Default disables external access to rely on private endpoints."
}

variable "storage_account_trusted_services_enabled" {
  type        = bool
  default     = false
  description = "Enable trusted Microsoft services to bypass storage account network rules."
}

variable "storage_account_allow_nested_items_to_be_public" {
  type        = bool
  default     = false
  description = "Allow nested items (containers/directories) to inherit public access."
}

variable "storage_account_min_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "Minimum TLS version for the storage account endpoint."

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2", "TLS1_3"], var.storage_account_min_tls_version)
    error_message = "Storage account minimum TLS version must be one of: TLS1_0, TLS1_1, TLS1_2, TLS1_3."
  }
}

variable "storage_account_shared_access_key_enabled" {
  type        = bool
  default     = false
  description = "Enable shared access key authentication for the storage account. Default is false to enforce more secure authentication methods."
}

variable "storage_account_sas_expiration_period" {
  type        = string
  default     = "1.00:00:00"
  description = "Default expiration period applied to user delegation and service SAS tokens in d.hh:mm:ss format."
}

variable "storage_account_blob_soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "Retention in days for blob soft delete. Set to 0 to keep soft delete disabled."

  validation {
    condition     = var.storage_account_blob_soft_delete_retention_days >= 0 && var.storage_account_blob_soft_delete_retention_days <= 365
    error_message = "Blob soft delete retention must be between 0 and 365 days."
  }
}

variable "storage_account_container_soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "Retention in days for container soft delete. Set to 0 to keep soft delete disabled."

  validation {
    condition     = var.storage_account_container_soft_delete_retention_days >= 0 && var.storage_account_container_soft_delete_retention_days <= 365
    error_message = "Container soft delete retention must be between 0 and 365 days."
  }
}

variable "storage_account_managed_identity_enabled" {
  type        = bool
  default     = false
  description = "Assign a system managed identity to the storage account to support Customer Managed Keys."
}

variable "law_name" {
  type        = string
  default     = null
  description = "Name for the Log Analytics Workspace"
}

variable "law_resource_group_name" {
  type        = string
  default     = null
  description = "Resource Group of existing Log Analytics Workspace"
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
    condition     = var.law_cross_subscription_details == null || length(trimspace(try(var.law_cross_subscription_details.shared_key, ""))) > 0
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

variable "service_plan_sku" {
  type        = string
  default     = "S1"
  description = "SKU for App Service Plan"
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

variable "app_service_name_certificate_master" {
  type        = string
  description = "Name of the certificate master app service"
}

variable "key_vault_name" {
  type        = string
  description = "Name of the key vault"
}

variable "key_vault_use_rbac" {
  type        = bool
  default     = true
  description = "Use RBAC for the key vault or the older access policies"
}

variable "create_networking" {
  type        = bool
  default     = true
  description = "Whether the module creates networking resources (VNet, subnets, NSGs, DNS zones, Private Endpoints). Set to false for BYOS mode — provide existing_subnet_appservices_id and manage networking externally."
}

variable "existing_subnet_appservices_id" {
  type        = string
  default     = null
  nullable    = true
  description = "Resource ID of an existing subnet delegated to Microsoft.Web/serverFarms for App Service VNet integration. Required when create_networking is false; presence and format are validated at apply time via a check block to support computed values from other modules in the same plan."

  validation {
    condition     = var.existing_subnet_appservices_id == null || can(regex("(?i)^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.existing_subnet_appservices_id))
    error_message = "Must be a valid Azure subnet resource ID."
  }

}

variable "vnet_name" {
  type        = string
  default     = "vnet-scepman"
  description = "Name of the VNET created for internal communication. Ignored when create_networking is false."
}

variable "vnet_address_space" {
  type        = list(any)
  default     = ["10.158.200.0/24"]
  description = "Address-Space of the VNET. Ignored when create_networking is false."

    validation {
      condition = length(var.vnet_address_space) > 0 && can(cidrhost(var.vnet_address_space[0], 0))
      error_message = "vnet_address_space must be a list with at least one valid CIDR notation (e.g., [\"10.0.0.0/16\"])."
    }
}

variable "subnet_appservices_name" {
  type        = string
  default     = "snet-scepman-appservices"
  description = "Name of the subnet created for integrating the App Services. Ignored when create_networking is false."
}

variable "subnet_appservices_address_prefix" {
  type        = string
  default     = null
  nullable    = true
  description = "CIDR address prefix for the App Services subnet (e.g., from IPAM). When null, the prefix is auto-calculated from vnet_address_space using cidrsubnet(). Ignored when create_networking is false. Note: Azure validates at apply time that the prefix is within the VNet address space and does not overlap other subnets."

  validation {
    condition = var.subnet_appservices_address_prefix == null || (
      # Valid CIDR notation
      can(cidrhost(var.subnet_appservices_address_prefix, 0))
    )
    error_message = "Must be a valid CIDR notation (e.g., 10.0.1.0/26). When create_networking is true, the prefix must be contained within vnet_address_space[0]."
  }
}

variable "subnet_endpoints_name" {
  type        = string
  default     = "snet-scepman-endpoints"
  description = "Name of the subnet created for the other endpoints. Ignored when create_networking is false."
}

variable "subnet_endpoints_address_prefix" {
  type        = string
  default     = null
  nullable    = true
  description = "CIDR address prefix for the Private Endpoints subnet (e.g., from IPAM). When null, the prefix is auto-calculated from vnet_address_space using cidrsubnet(). Ignored when create_networking is false. Note: Azure validates at apply time that the prefix is within the VNet address space and does not overlap other subnets."

  validation {
    condition     = var.subnet_endpoints_address_prefix == null || can(cidrhost(var.subnet_endpoints_address_prefix, 0))
    error_message = "Must be a valid CIDR notation (e.g., 10.0.2.0/26)."
  }
}

variable "nsg_endpoints_name" {
  type        = string
  default     = "nsg-scepman-endpoints"
  description = "Name of the Network Security Group for the endpoints subnet. Ignored when create_networking is false."
}

variable "nsg_appservices_name" {
  type        = string
  default     = "nsg-scepman-appservices"
  description = "Name of the Network Security Group for the app services subnet. Ignored when create_networking is false."
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

variable "manage_entra_apps" {
  type        = bool
  description = "Whether to manage the Entra app registrations for SCEPman and Certificate Master within this module. If set to true, the user executing this must have Global Administrator privileges in the tenant/the service principal must have Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All permissions. For legacy installations, which were created before this setting existed, only set to true if you wish to migrate to the new model. For new installations, it is recommended to set this to true."
  default     = false
}

variable "primary_uami_ids" {
  type        = set(string)
  description = "Set of user assigned managed identity resource IDs to assign to the SCEPman primary app service. The primary app service will always have a system assigned managed identity. This setting therefore is optional and for advanced use cases where additional user assigned managed identities need to be assigned to the app service. For most use cases, this can be left empty."
  default     = []
}

variable "certificate_master_uami_ids" {
  type        = set(string)
  description = "Set of user assigned managed identity resource IDs to assign to the SCEPman Certificate Master app service. The certificate master app service will always have a system assigned managed identity. This setting therefore is optional and for advanced use cases where additional user assigned managed identities need to be assigned to the app service. For most use cases, this can be left empty."
  default     = []
}
