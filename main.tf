terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  required_version = "~> 1.3.3"
}

data "azurerm_client_config" "current" {}

# Storage Account

resource "azurerm_storage_account" "storage" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
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

  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  tags = var.tags
}

# Log Analytics Workspace

resource "azurerm_log_analytics_workspace" "law" {
  count = (var.law_workspace_id == null || var.law_shared_key == null) ? 1 : 0

  name                = var.law_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = var.tags

  lifecycle {
    precondition {
      condition     = (var.law_workspace_id != null && var.law_shared_key != null) || (var.law_workspace_id == null && var.law_shared_key == null)
      error_message = "If you want to use your existing Log Analytics Wokrpsce, both 'law_workspace_id' AND 'law_shared_key' need to be set!"
    }
  }

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
  law_workspace_id         = var.law_workspace_id != null ? var.law_workspace_id : azurerm_log_analytics_workspace.law[0].workspace_id
  law_shared_key           = var.law_shared_key != null ? var.law_shared_key : azurerm_log_analytics_workspace.law[0].primary_shared_key

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
  app_settings_primary = merge(local.app_settings_primary_defaults, var.app_settings_primary, local.app_settings_primary_base)

}

resource "azurerm_windows_web_app" "app" {
  name                = var.app_service_name_primary
  resource_group_name = var.resource_group_name
  location            = var.location
  https_only          = false

  service_plan_id = local.service_plan_resource_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    health_check_path = "/probe"
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
        retention_in_days = var.app_service_retention_in_days
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
      app_settings["APPINSIGHTS_INSTRUMENTATIONKEY"],
      app_settings["APPINSIGHTS_PROFILERFEATURE_VERSION"],
      app_settings["APPINSIGHTS_SNAPSHOTFEATURE_VERSION"],
      app_settings["APPLICATIONINSIGHTS_CONNECTION_STRING"],
      app_settings["ApplicationInsightsAgent_EXTENSION_VERSION"],
      app_settings["DiagnosticServices_EXTENSION_VERSION"],
      app_settings["InstrumentationEngine_EXTENSION_VERSION"],
      app_settings["SnapshotDebugger_EXTENSION_VERSION"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      app_settings["XDT_MicrosoftApplicationInsights_BaseExtensions"],
      app_settings["XDT_MicrosoftApplicationInsights_Java"],
      app_settings["XDT_MicrosoftApplicationInsights_Mode"],
      app_settings["XDT_MicrosoftApplicationInsights_NodeJS"],
      app_settings["XDT_MicrosoftApplicationInsights_PreemptSdk"],
      sticky_settings
    ]
  }
}

# Certificate Master App Service

locals {

  app_settings_certificate_master_defaults = {}

  app_settings_certificate_master_base = {
    "WEBSITE_RUN_FROM_PACKAGE"                    = var.artifacts_url_certificate_master
    "AppConfig:AzureStorage:TableStorageEndpoint" = azurerm_storage_account.storage.primary_table_endpoint
    "AppConfig:SCEPman:URL"                       = format("https://%s", azurerm_windows_web_app.app.default_hostname)
    "AppConfig:AuthConfig:TenantId"               = data.azurerm_client_config.current.tenant_id
    "AppConfig:LoggingConfig:WorkspaceId"         = local.law_workspace_id
    "AppConfig:LoggingConfig:SharedKey"           = local.law_shared_key
  }

  // Merge maps will overwrite first by last > default variables, custom variables, resource variables
  app_settings_certificate_master = merge(local.app_settings_certificate_master_defaults, var.app_settings_certificate_master, local.app_settings_certificate_master_base)
}

resource "azurerm_windows_web_app" "app_cm" {
  name                = var.app_service_name_certificate_master
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id = local.service_plan_resource_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    health_check_path = "/probe"
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
        retention_in_days = var.app_service_retention_in_days
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
      app_settings["APPINSIGHTS_INSTRUMENTATIONKEY"],
      app_settings["APPINSIGHTS_PROFILERFEATURE_VERSION"],
      app_settings["APPINSIGHTS_SNAPSHOTFEATURE_VERSION"],
      app_settings["APPLICATIONINSIGHTS_CONNECTION_STRING"],
      app_settings["ApplicationInsightsAgent_EXTENSION_VERSION"],
      app_settings["DiagnosticServices_EXTENSION_VERSION"],
      app_settings["InstrumentationEngine_EXTENSION_VERSION"],
      app_settings["SnapshotDebugger_EXTENSION_VERSION"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      app_settings["XDT_MicrosoftApplicationInsights_BaseExtensions"],
      app_settings["XDT_MicrosoftApplicationInsights_Java"],
      app_settings["XDT_MicrosoftApplicationInsights_Mode"],
      app_settings["XDT_MicrosoftApplicationInsights_NodeJS"],
      app_settings["XDT_MicrosoftApplicationInsights_PreemptSdk"],
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
