terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.102.0"
    }
  }
  required_version = ">= 1.3"
}

data "azurerm_client_config" "current" {}

# vnet and subnet for internal communication
resource "azurerm_virtual_network" "vnet-scepman" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "subnet-endpoints" {
  name                 = var.subnet_endpoints_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-scepman.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 3, 1)]
}

resource "azurerm_subnet" "subnet-appservices" {
  name                 = var.subnet_appservices_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-scepman.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 3, 0)]
  delegation {
    name = "delegation"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/action", ]
      name    = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_private_dns_zone" "dnsprivatezone-kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink-kv" {
  name                  = "dnszonelink-kv"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsprivatezone-kv.name
  virtual_network_id    = azurerm_virtual_network.vnet-scepman.id
}

resource "azurerm_private_dns_zone" "dnsprivatezone-sts" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink-sts" {
  name                  = "dnszonelink-sts"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsprivatezone-sts.name
  virtual_network_id    = azurerm_virtual_network.vnet-scepman.id
}

# Storage Account

resource "azurerm_storage_account" "storage" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  public_network_access_enabled = true

  network_rules {
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
    bypass                     = ["None"]
  }

  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage_pe" {
  name                = "pep-sts-scepman"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.subnet-endpoints.id

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsprivatezone-sts.id]
  }

  private_service_connection {
    name                           = "storageconnection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
}

# Key Vault

resource "azurerm_key_vault" "vault" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "premium"
  enable_rbac_authorization = false

  enabled_for_disk_encryption     = false
  enabled_for_deployment          = false
  enabled_for_template_deployment = false

  public_network_access_enabled = false

  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  tags = var.tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault_pe" {
  name                = "pep-kv-scepman"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.subnet-endpoints.id

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsprivatezone-kv.id]
  }

  private_service_connection {
    name                           = "keyvaultconnection"
    private_connection_resource_id = azurerm_key_vault.vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}


# Log Analytics Workspace

# Get exisiting Log Analytics Workspace if law_resource_group_name is defined
data "azurerm_log_analytics_workspace" "existing-law" {
  count               = var.law_resource_group_name != null ? 1 : 0
  name                = var.law_name
  resource_group_name = var.law_resource_group_name
}

resource "azurerm_log_analytics_workspace" "law" {
  count = length(data.azurerm_log_analytics_workspace.existing-law) > 0 ? 0 : 1

  name                = var.law_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = var.tags
}

locals {
  law_id           = length(data.azurerm_log_analytics_workspace.existing-law) > 0 ? data.azurerm_log_analytics_workspace.existing-law[0].id : azurerm_log_analytics_workspace.law[0].id
  law_workspace_id = length(data.azurerm_log_analytics_workspace.existing-law) > 0 ? data.azurerm_log_analytics_workspace.existing-law[0].workspace_id : azurerm_log_analytics_workspace.law[0].workspace_id
  law_shared_key   = length(data.azurerm_log_analytics_workspace.existing-law) > 0 ? data.azurerm_log_analytics_workspace.existing-law[0].primary_shared_key : azurerm_log_analytics_workspace.law[0].primary_shared_key
}

# Application Insights
# Creating Application Insights will not allow terraform to destroy the ressource group, as app insights create hidden rules that can (currently) not be managed by terraform

resource "azurerm_application_insights" "scepman-primary" {
  count               = var.enable_application_insights == true ? 1 : 0
  name                = format("%s_app-insights", var.app_service_name_primary)
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = local.law_id
  application_type    = "web"

  tags = var.tags
}
resource "azurerm_application_insights" "scepman-cm" {
  count               = var.enable_application_insights == true ? 1 : 0
  name                = format("%s_app-insights", var.app_service_name_certificate_master)
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = local.law_id
  application_type    = "web"

  tags = var.tags
}

# App Service Plan

resource "azurerm_service_plan" "plan" {
  count = var.service_plan_resource_id == null ? 1 : 0

  name                = var.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location

  os_type  = "Windows"
  sku_name = var.service_plan_sku

  tags = var.tags
}

# Scepman App Service

locals {
  service_plan_resource_id = var.service_plan_resource_id != null ? var.service_plan_resource_id : azurerm_service_plan.plan[0].id

  app_settings_primary_defaults = {
    "AppConfig:LicenseKey"                                           = "trial"
    "AppConfig:UseRequestedKeyUsages"                                = "true",
    "AppConfig:ValidityPeriodDays"                                   = "730",
    "AppConfig:IntuneValidation:ValidityPeriodDays"                  = "365",
    "AppConfig:DirectCSRValidation:Enabled"                          = "true",
    "AppConfig:IntuneValidation:DeviceDirectory"                     = "AADAndIntune",
    "AppConfig:KeyVaultConfig:RootCertificateConfig:CertificateName" = "SCEPman-Root-CA-V1",
    "AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType"         = "RSA-HSM"
    "AppConfig:ValidityClockSkewMinutes"                             = "1440",
    "AppConfig:KeyVaultConfig:RootCertificateConfig:Subject"         = format("CN=SCEPman-Root-CA-V1,OU=%s,O=\"%s\"", data.azurerm_client_config.current.tenant_id, var.organization_name)
  }

  # if app insight exists, add to app settings
  app_settings_primary_app_insights = length(azurerm_application_insights.scepman-primary) > 0 ? {
    "APPINSIGHTS_INSTRUMENTATIONKEY"                  = azurerm_application_insights.scepman-primary[0].instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"           = azurerm_application_insights.scepman-primary[0].connection_string
    "APPINSIGHTS_PROFILERFEATURE_VERSION"             = "1.0.0"
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION"             = "1.0.0"
    "DiagnosticServices_EXTENSION_VERSION"            = "~3"
    "InstrumentationEngine_EXTENSION_VERSION"         = "~1"
    "SnapshotDebugger_EXTENSION_VERSION"              = "~1"
    "XDT_MicrosoftApplicationInsights_BaseExtensions" = "disabled"
    "XDT_MicrosoftApplicationInsights_Java"           = "1"
    "XDT_MicrosoftApplicationInsights_NodeJS"         = "1"
    "XDT_MicrosoftApplicationInsights_PreemptSdk"     = "disabled"
    "ApplicationInsightsAgent_EXTENSION_VERSION"      = "~2"
    "XDT_MicrosoftApplicationInsights_Mode"           = "recommended"
  } : {}

  app_settings_primary_base = {
    "WEBSITE_RUN_FROM_PACKAGE"                          = var.artifacts_url_primary
    "AppConfig:BaseUrl"                                 = format("https://%s.azurewebsites.net", var.app_service_name_primary)
    "AppConfig:AuthConfig:TenantId"                     = data.azurerm_client_config.current.tenant_id
    "AppConfig:KeyVaultConfig:KeyVaultURL"              = azurerm_key_vault.vault.vault_uri
    "AppConfig:CertificateStorage:TableStorageEndpoint" = azurerm_storage_account.storage.primary_table_endpoint
    "AppConfig:LoggingConfig:WorkspaceId"               = local.law_workspace_id
    "AppConfig:LoggingConfig:SharedKey"                 = local.law_shared_key
  }

  // Merge maps will overwrite first by last > default variables, custom variables, resource variables
  app_settings_primary = merge(local.app_settings_primary_defaults, var.app_settings_primary, local.app_settings_primary_app_insights, local.app_settings_primary_base)

}

resource "azurerm_windows_web_app" "app" {
  name                      = var.app_service_name_primary
  resource_group_name       = var.resource_group_name
  location                  = var.location
  https_only                = false
  virtual_network_subnet_id = azurerm_subnet.subnet-appservices.id

  service_plan_id = local.service_plan_resource_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    health_check_path = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker = false
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }
  }

  app_settings = local.app_settings_primary

  tags = var.tags

  logs {
    detailed_error_messages = var.app_service_logs_detailed_error_messages
    failed_request_tracing  = var.app_service_logs_failed_request_tracing

    application_logs {
      file_system_level = var.app_service_application_logs_file_system_level
    }

    http_logs {
      file_system {
        retention_in_days = length(azurerm_application_insights.scepman-primary) > 0 ? 0 : var.app_service_retention_in_days
        retention_in_mb   = var.app_service_retention_in_mb
      }
    }
  }

  lifecycle {
    # CA Key type must be specific
    precondition {
      condition     = local.app_settings_primary["AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType"] == "RSA" || local.app_settings_primary["AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType"] == "RSA-HSM"
      error_message = "Possible values are 'RSA' or 'RSA-HSM'"
    }

    ignore_changes = [
      app_settings["AppConfig:AuthConfig:ApplicationId"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityEnabledForWebsiteHostname"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityEnabledOnUnixTime"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityPermissionLevel"],
      app_settings["AppConfig:CertMaster:URL"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      sticky_settings
    ]
  }
}

# Certificate Master App Service

locals {

  app_settings_certificate_master_defaults = {}

  # if app insight exists, add to app settings
  app_settings_certificate_master_app_insights = length(azurerm_application_insights.scepman-cm) > 0 ? {
    "APPINSIGHTS_INSTRUMENTATIONKEY"                  = azurerm_application_insights.scepman-cm[0].instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"           = azurerm_application_insights.scepman-cm[0].connection_string
    "APPINSIGHTS_PROFILERFEATURE_VERSION"             = "1.0.0"
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION"             = "1.0.0"
    "DiagnosticServices_EXTENSION_VERSION"            = "~3"
    "InstrumentationEngine_EXTENSION_VERSION"         = "~1"
    "SnapshotDebugger_EXTENSION_VERSION"              = "~1"
    "XDT_MicrosoftApplicationInsights_BaseExtensions" = "disabled"
    "XDT_MicrosoftApplicationInsights_Java"           = "1"
    "XDT_MicrosoftApplicationInsights_NodeJS"         = "1"
    "XDT_MicrosoftApplicationInsights_PreemptSdk"     = "disabled"
    "ApplicationInsightsAgent_EXTENSION_VERSION"      = "~2"
    "XDT_MicrosoftApplicationInsights_Mode"           = "recommended"
  } : {}

  app_settings_certificate_master_base = {
    "WEBSITE_RUN_FROM_PACKAGE"                    = var.artifacts_url_certificate_master
    "AppConfig:AzureStorage:TableStorageEndpoint" = azurerm_storage_account.storage.primary_table_endpoint
    "AppConfig:SCEPman:URL"                       = format("https://%s", azurerm_windows_web_app.app.default_hostname)
    "AppConfig:AuthConfig:TenantId"               = data.azurerm_client_config.current.tenant_id
    "AppConfig:LoggingConfig:WorkspaceId"         = local.law_workspace_id
    "AppConfig:LoggingConfig:SharedKey"           = local.law_shared_key
  }

  // Merge maps will overwrite first by last > default variables, custom variables, resource variables
  app_settings_certificate_master = merge(local.app_settings_certificate_master_defaults, var.app_settings_certificate_master, local.app_settings_certificate_master_app_insights, local.app_settings_certificate_master_base)
}

resource "azurerm_windows_web_app" "app_cm" {
  name                      = var.app_service_name_certificate_master
  resource_group_name       = var.resource_group_name
  location                  = var.location
  virtual_network_subnet_id = azurerm_subnet.subnet-appservices.id

  service_plan_id = local.service_plan_resource_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    health_check_path = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker = false
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }
  }

  app_settings = local.app_settings_certificate_master

  tags = var.tags

  logs {
    detailed_error_messages = var.app_service_logs_detailed_error_messages
    failed_request_tracing  = var.app_service_logs_failed_request_tracing

    application_logs {
      file_system_level = var.app_service_application_logs_file_system_level
    }

    http_logs {
      file_system {
        retention_in_days = length(azurerm_application_insights.scepman-cm) > 0 ? 0 : var.app_service_retention_in_days
        retention_in_mb   = var.app_service_retention_in_mb
      }
    }
  }

  lifecycle {

    ignore_changes = [
      app_settings["AppConfig:AuthConfig:ApplicationId"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityEnabledOnUnixTime"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityPermissionLevel"],
      app_settings["AppConfig:AuthConfig:SCEPmanAPIScope"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      sticky_settings
    ]
  }

}

# Key Vault Access Policy

resource "azurerm_key_vault_access_policy" "scepman" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_web_app.app.identity[0].principal_id

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "ManageContacts"
  ]

  key_permissions = [
    "Get",
    "Create",
    "UnwrapKey",
    "Sign"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}

# Role Assignment - Storage Table Data Contributor

locals {
  object_ids = { for key, item in [azurerm_windows_web_app.app, azurerm_windows_web_app.app_cm] : key => item.identity[0].principal_id }
}

resource "azurerm_role_assignment" "table_contributor" {
  for_each = local.object_ids

  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = each.value
}
