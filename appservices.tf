# Artifacts URL
locals {
  # Base URL for the artifacts hosted by GK
  gk_github_artifact_base  = "https://raw.githubusercontent.com/scepman/install/master/dist"
  gk_vanity_artifacts_base = "https://install.scepman.com/dist"

  # If the artifacts URL is hosted by GK, we need to adjust the URL based on the OS. Self-hosted Artifacts are not adjusted, User is responsible for correct URL then.
  # Process primary artifact URL with nested replaces
  artifacts_url_primary = (
    startswith(var.artifacts_url_primary, local.gk_github_artifact_base) ||
    startswith(var.artifacts_url_primary, local.gk_vanity_artifacts_base)
    ) ? (
    lower(var.service_plan_os_type) == "linux"
    ? replace(
      replace(
        replace(var.artifacts_url_primary, "Artifacts-Intern.zip", "Artifacts-Linux-Internal.zip"),
        "Artifacts-Beta.zip",
        "Artifacts-Linux-Beta.zip"
      ),
      "Artifacts.zip",
      "Artifacts-Linux.zip"
    )
    : replace(var.artifacts_url_primary, "-Linux", "")
  ) : var.artifacts_url_primary

  # Process certificate master artifact URL with nested replaces
  artifacts_url_certificate_master = (
    startswith(var.artifacts_url_certificate_master, local.gk_github_artifact_base) ||
    startswith(var.artifacts_url_certificate_master, local.gk_vanity_artifacts_base)
    ) ? (
    lower(var.service_plan_os_type) == "linux"
    ? replace(
      replace(
        replace(var.artifacts_url_certificate_master, "CertMaster-Artifacts-Intern.zip", "CertMaster-Artifacts-Linux-Internal.zip"),
        "CertMaster-Artifacts-Beta.zip",
        "CertMaster-Artifacts-Linux-Beta.zip"
      ),
      "CertMaster-Artifacts.zip",
      "CertMaster-Artifacts-Linux.zip"
    )
    : replace(var.artifacts_url_certificate_master, "-Linux", "")
  ) : var.artifacts_url_certificate_master
}

# App Service Plan
resource "azurerm_service_plan" "plan" {
  count = var.service_plan_resource_id == null ? 1 : 0

  name                = var.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location

  os_type  = var.service_plan_os_type
  sku_name = var.service_plan_sku

  tags = var.tags
}

# Scepman Windows App Service
# Primary Locals
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
    "AppConfig:OCSP:UseAuthorizedResponder"                          = "true",
    "AppConfig:EnableCertificateStorage"                             = "true",
    "AppConfig:CRL:Source"                                           = "Storage",
    "AppConfig:DbCSRValidation:ReenrollmentAllowedCertificateTypes"  = "Static",
    "AppConfig:KeyVaultConfig:RootCertificateConfig:KeySize"         = "4096",
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
    "WEBSITE_RUN_FROM_PACKAGE"                          = local.artifacts_url_primary
    "AppConfig:BaseUrl"                                 = format("https://%s.azurewebsites.net", var.app_service_name_primary)
    "AppConfig:AuthConfig:TenantId"                     = data.azurerm_client_config.current.tenant_id
    "AppConfig:KeyVaultConfig:KeyVaultURL"              = azurerm_key_vault.vault.vault_uri
    "AppConfig:CertificateStorage:TableStorageEndpoint" = azurerm_storage_account.storage.primary_table_endpoint
    "AppConfig:LoggingConfig:WorkspaceId"               = local.law_workspace_id
    "AppConfig:LoggingConfig:SharedKey"                 = local.law_shared_key
  }

  // Normalize input app settings to use ":" as separator for easier merging
  normalized_app_settings_primary = { for k, v in var.app_settings_primary : replace(k, "__", ":") => v }
  // Merge maps will overwrite first by last > default variables, custom variables, resource variables
  merged_app_settings_primary = merge(local.app_settings_primary_defaults, local.normalized_app_settings_primary, local.app_settings_primary_app_insights, local.app_settings_primary_base)
  // If OS is linux, replace ":" with"__" in app settings, if OS is windows (NOT linux), replace "__" with ":" in app settings
  app_settings_primary = lower(var.service_plan_os_type) == "linux" ? { for k, v in local.merged_app_settings_primary : replace(k, ":", "__") => v } : { for k, v in local.merged_app_settings_primary : replace(k, "__", ":") => v }

}
# Certificate Master Locals
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

  app_settings_primary_url = format("https://%s", lower(var.service_plan_os_type) == "linux" ? azurerm_linux_web_app.app[0].default_hostname : azurerm_windows_web_app.app[0].default_hostname)


  app_settings_certificate_master_base = {
    "WEBSITE_RUN_FROM_PACKAGE"                    = local.artifacts_url_certificate_master
    "AppConfig:AzureStorage:TableStorageEndpoint" = azurerm_storage_account.storage.primary_table_endpoint
    "AppConfig:SCEPman:URL"                       = local.app_settings_primary_url
    "AppConfig:AuthConfig:TenantId"               = data.azurerm_client_config.current.tenant_id
    "AppConfig:LoggingConfig:WorkspaceId"         = local.law_workspace_id
    "AppConfig:LoggingConfig:SharedKey"           = local.law_shared_key
  }

  // Normalize input app settings to use ":" as separator for easier merging
  normalized_app_settings_certificate_master = { for k, v in var.app_settings_certificate_master : replace(k, "__", ":") => v }
  // Merge maps will overwrite first by last > default variables, custom variables, resource variables
  merged_app_settings_certificate_master = merge(local.app_settings_certificate_master_defaults, local.normalized_app_settings_certificate_master, local.app_settings_certificate_master_app_insights, local.app_settings_certificate_master_base)
  // If OS is linux, replace ":" with"__" in app settings, if OS is windows (NOT linux), replace "__" with ":" in app settings
  app_settings_certificate_master = lower(var.service_plan_os_type) == "linux" ? { for k, v in local.merged_app_settings_certificate_master : replace(k, ":", "__") => v } : { for k, v in local.merged_app_settings_certificate_master : replace(k, "__", ":") => v }
}



### Windows App Service
#Scepman Primary
resource "azurerm_windows_web_app" "app" {
  count                     = lower(var.service_plan_os_type) == "windows" ? 1 : 0
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
    health_check_path                 = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker                 = false
    minimum_tls_version               = var.app_service_minimum_tls_version_scepman
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }
  }

  app_settings = lower(var.service_plan_os_type) == "windows" ? { for k, v in local.app_settings_primary : replace(k, "__", ":") => v } : local.app_settings_primary

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
resource "azurerm_windows_web_app" "app_cm" {
  count                     = lower(var.service_plan_os_type) == "windows" ? 1 : 0
  name                      = var.app_service_name_certificate_master
  resource_group_name       = var.resource_group_name
  location                  = var.location
  virtual_network_subnet_id = azurerm_subnet.subnet-appservices.id

  service_plan_id = local.service_plan_resource_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    health_check_path                 = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker                 = false
    minimum_tls_version               = var.app_service_minimum_tls_version_certificate_master
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

### Linux App Service
#Scepman Primary
resource "azurerm_linux_web_app" "app" {
  count                     = lower(var.service_plan_os_type) == "linux" ? 1 : 0
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
    health_check_path                 = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker                 = false
    minimum_tls_version               = var.app_service_minimum_tls_version_scepman
    application_stack {
      #current_stack  = "dotnet"
      dotnet_version = "8.0"
    }
  }

  app_settings = lower(var.service_plan_os_type) == "linux" ? { for k, v in local.app_settings_primary : replace(k, ":", "__") => v } : local.app_settings_primary


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
      condition     = local.app_settings_primary["AppConfig__KeyVaultConfig__RootCertificateConfig__KeyType"] == "RSA" || local.app_settings_primary["AppConfig__KeyVaultConfig__RootCertificateConfig__KeyType"] == "RSA-HSM"
      error_message = "Possible values are 'RSA' or 'RSA-HSM'"
    }

    ignore_changes = [
      app_settings["AppConfig__AuthConfig__ApplicationId"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityEnabledForWebsiteHostname"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityEnabledOnUnixTime"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityPermissionLevel"],
      app_settings["AppConfig__CertMaster__URL"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      sticky_settings
    ]
  }
}
# Certificate Master App Service
resource "azurerm_linux_web_app" "app_cm" {
  count                     = lower(var.service_plan_os_type) == "linux" ? 1 : 0
  name                      = var.app_service_name_certificate_master
  resource_group_name       = var.resource_group_name
  location                  = var.location
  virtual_network_subnet_id = azurerm_subnet.subnet-appservices.id

  service_plan_id = local.service_plan_resource_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    health_check_path                 = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker                 = false
    minimum_tls_version               = var.app_service_minimum_tls_version_certificate_master
    application_stack {
      #  current_stack  = "dotnet"
      dotnet_version = "8.0"
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
      app_settings["AppConfig__AuthConfig__ApplicationId"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityEnabledOnUnixTime"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityPermissionLevel"],
      app_settings["AppConfig__AuthConfig__SCEPmanAPIScope"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      sticky_settings
    ]
  }

}
