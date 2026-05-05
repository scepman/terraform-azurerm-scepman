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

  app_settings_primary_app = var.manage_entra_apps ? {
    "AppConfig:CertMaster:URL"                                      = format("https://%s.azurewebsites.net", var.app_service_name_certificate_master)
    "AppConfig:AuthConfig:ApplicationId"                            = module.appreg_scepman[0].client_id
    "AppConfig:AuthConfig:UseManagedIdentity"                       = "true"
    "AppConfig:AuthConfig:ManagedIdentityEnabledForWebsiteHostname" = format("%s.azurewebsites.net", var.app_service_name_primary)
    "AppConfig:AuthConfig:ManagedIdentityEnabledOnUnixTime"         = time_offset.managed_identity.unix
    "AppConfig:AuthConfig:ManagedIdentityPermissionLevel"           = "2"
  } : {}

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
  }

  app_settings_primary_dcr = var.enable_dcr_log_ingestion ? {
    "AppConfig:LoggingConfig:DataCollectionEndpointUri" = azurerm_monitor_data_collection_endpoint.scepman[0].logs_ingestion_endpoint
    "AppConfig:LoggingConfig:RuleId"                    = azurerm_monitor_data_collection_rule.scepman[0].immutable_id
  } : {}

  app_settings_primary_legacy_log = var.enable_dcr_log_ingestion ? {} : {
    "AppConfig:LoggingConfig:SharedKey" = local.law_shared_key
  }

  // Normalize input app settings to use ":" as separator for easier merging
  normalized_app_settings_primary = { for k, v in var.app_settings_primary : replace(k, "__", ":") => v }
  // Merge maps will overwrite first by last > default variables, custom variables, resource variables
  merged_app_settings_primary = merge(local.app_settings_primary_defaults, local.normalized_app_settings_primary, local.app_settings_primary_app_insights, local.app_settings_primary_base, local.app_settings_primary_dcr, local.app_settings_primary_legacy_log, local.app_settings_primary_app)
  // If OS is linux, replace ":" with"__" in app settings, if OS is windows (NOT linux), replace "__" with ":" in app settings
  app_settings_primary = lower(var.service_plan_os_type) == "linux" ? { for k, v in local.merged_app_settings_primary : replace(k, ":", "__") => v } : { for k, v in local.merged_app_settings_primary : replace(k, "__", ":") => v }

  app_service_primary_identity = {
    type         = length(var.primary_uami_ids) == 0 ? "SystemAssigned" : "SystemAssigned, UserAssigned"
    identity_ids = length(var.primary_uami_ids) == 0 ? null : var.primary_uami_ids
  }
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

  default_hostname_primary = try(
    azurerm_linux_web_app.app[0].default_hostname,
    azurerm_windows_web_app.app[0].default_hostname,
    azurerm_linux_web_app.app_full[0].default_hostname,
    azurerm_windows_web_app.app_full[0].default_hostname
  )

  app_settings_primary_url = format("https://%s", local.default_hostname_primary)


  app_settings_certificate_master_base = {
    "WEBSITE_RUN_FROM_PACKAGE"                    = local.artifacts_url_certificate_master
    "AppConfig:AzureStorage:TableStorageEndpoint" = azurerm_storage_account.storage.primary_table_endpoint
    "AppConfig:SCEPman:URL"                       = local.app_settings_primary_url
    "AppConfig:AuthConfig:TenantId"               = data.azurerm_client_config.current.tenant_id
    "AppConfig:LoggingConfig:WorkspaceId"         = local.law_workspace_id
  }

  app_settings_certificate_master_dcr = var.enable_dcr_log_ingestion ? {
    "AppConfig:LoggingConfig:DataCollectionEndpointUri" = azurerm_monitor_data_collection_endpoint.scepman[0].logs_ingestion_endpoint
    "AppConfig:LoggingConfig:RuleId"                    = azurerm_monitor_data_collection_rule.scepman[0].immutable_id
  } : {}

  app_settings_certificate_master_legacy_log = var.enable_dcr_log_ingestion ? {} : {
    "AppConfig:LoggingConfig:SharedKey" = local.law_shared_key
  }

  app_settings_certificate_master_app = var.manage_entra_apps ? {
    "AppConfig:AuthConfig:ApplicationId"                    = module.appreg_certmaster[0].client_id
    "AppConfig:AuthConfig:SCEPmanAPIScope"                  = local.scepman_api_scope
    "AppConfig:AuthConfig:UseManagedIdentity"               = "true"
    "AppConfig:AuthConfig:ManagedIdentityEnabledOnUnixTime" = time_offset.managed_identity.unix
    "AppConfig:AuthConfig:ManagedIdentityPermissionLevel"   = "2"
  } : {}

  default_hostname_cm = try(
    azurerm_linux_web_app.app_cm[0].default_hostname,
    azurerm_windows_web_app.app_cm[0].default_hostname,
    azurerm_linux_web_app.app_cm_full[0].default_hostname,
    azurerm_windows_web_app.app_cm_full[0].default_hostname
  )

  // Normalize input app settings to use ":" as separator for easier merging
  normalized_app_settings_certificate_master = { for k, v in var.app_settings_certificate_master : replace(k, "__", ":") => v }
  // Merge maps will overwrite first by last > default variables, custom variables, resource variables
  merged_app_settings_certificate_master = merge(local.app_settings_certificate_master_defaults, local.normalized_app_settings_certificate_master, local.app_settings_certificate_master_app_insights, local.app_settings_certificate_master_base, local.app_settings_certificate_master_dcr, local.app_settings_certificate_master_legacy_log, local.app_settings_certificate_master_app)
  // If OS is linux, replace ":" with"__" in app settings, if OS is windows (NOT linux), replace "__" with ":" in app settings
  app_settings_certificate_master = lower(var.service_plan_os_type) == "linux" ? { for k, v in local.merged_app_settings_certificate_master : replace(k, ":", "__") => v } : { for k, v in local.merged_app_settings_certificate_master : replace(k, "__", ":") => v }

  app_service_certificate_master_identity = {
    type         = length(var.certificate_master_uami_ids) == 0 ? "SystemAssigned" : "SystemAssigned, UserAssigned"
    identity_ids = length(var.certificate_master_uami_ids) == 0 ? null : var.certificate_master_uami_ids
  }
}
