terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
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

# App Service Plan

resource "azurerm_service_plan" "plan" {
  count = var.service_plan_resource_id == null ? 1 : 0

  name                = var.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location

  os_type  = "Windows"
  sku_name = "S1"

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
    "AppConfig:KeyVaultConfig:RootCertificateConfig:Subject"         = format("CN=SCEPman-Root-CA-V1,OU=%s,O=\"my-org\"", data.azurerm_client_config.current.tenant_id)
  }

  app_settings_primary_base = {
    "WEBSITE_RUN_FROM_PACKAGE"                    = format("%s/dist/Artifacts.zip", var.artifacts_repository_url)
    "AppConfig:BaseUrl"                           = format("https://%s.azurewebsites.net", var.app_service_name_primary)
    "AppConfig:AuthConfig:TenantId"               = data.azurerm_client_config.current.tenant_id
    "AppConfig:KeyVaultConfig:KeyVaultURL"        = azurerm_key_vault.vault.vault_uri
    "AppConfig:AzureStorage:TableStorageEndpoint" = azurerm_storage_account.storage.primary_table_endpoint
  }

  // Merge maps will overwrite first by last > default variables, custom variables, resource variables
  app_settings_primary = merge(local.app_settings_primary_defaults, var.app_settings_primary, local.app_settings_primary_base)

}

resource "azurerm_windows_web_app" "app" {
  name                = var.app_service_name_primary
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id = local.service_plan_resource_id

  identity {
    type = "SystemAssigned"
  }

  site_config {}

  app_settings = local.app_settings_primary

  tags = var.tags

  lifecycle {
    # CA Key type must be specific
    precondition {
      condition     = local.app_settings_primary["AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType"] == "RSA" || local.app_settings_primary["AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType"] == "RSA-HSM"
      error_message = "Possible values are 'RSA' or 'RSA-HSM'"
    }
  }
}

# Certificate Master App Service

locals {

  app_settings_certificate_master_defaults = {}

  app_settings_certificate_master_base = {
    "WEBSITE_RUN_FROM_PACKAGE"                    = format("%s/dist-certmaster/CertMaster-Artifacts.zip", var.artifacts_repository_url)
    "AppConfig:AzureStorage:TableStorageEndpoint" = azurerm_storage_account.storage.primary_table_endpoint
    "AppConfig:SCEPman:URL"                       = azurerm_windows_web_app.app.default_hostname
    "AppConfig:AuthConfig:TenantId"               = data.azurerm_client_config.current.tenant_id
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

  site_config {}

  app_settings = local.app_settings_certificate_master

  tags = var.tags
}

# Key Vault Access Policy

resource "azurerm_key_vault_access_policy" "scepman" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_web_app.app.identity[0].principal_id

  certificate_permissions = [
    "Backup",
    "Create",
    "Delete",
    "DeleteIssuers",
    "Get",
    "GetIssuers",
    "Import",
    "List",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "Purge",
    "Recover",
    "Restore",
    "SetIssuers",
    "Update",
  ]

  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
    "Release",
    "Rotate",
    "GetRotationPolicy",
    "SetRotationPolicy",
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
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
