output "scepman_url" {
  value       = format("https://%s", local.default_hostname_primary)
  description = "SCEPman Url"
}

output "scepman_certificate_master_url" {
  value       = format("https://%s", local.default_hostname_cm)
  description = "SCEPman Certificate Master Url"
}

output "storage_account_id" {
  value       = azurerm_storage_account.storage.id
  description = "ID of the storage account used by the deployment."
}

output "storage_account_identity_principal_id" {
  value       = try(azurerm_storage_account.storage.identity[0].principal_id, null)
  description = "Principal ID of the storage account system-assigned managed identity when enabled."
}

output "storage_account_identity_tenant_id" {
  value       = try(azurerm_storage_account.storage.identity[0].tenant_id, null)
  description = "Tenant ID of the storage account system-assigned managed identity when enabled."
}

output "app_services" {
  value = {
    primary = {
      id = try(
        azurerm_linux_web_app.app[0].id,
        azurerm_windows_web_app.app[0].id,
        azurerm_linux_web_app.app_full[0].id,
        azurerm_windows_web_app.app_full[0].id
      )
      name = try(
        azurerm_linux_web_app.app[0].name,
        azurerm_windows_web_app.app[0].name,
        azurerm_linux_web_app.app_full[0].name,
        azurerm_windows_web_app.app_full[0].name
      )
    }
    certificate_master = {
      id = try(
        azurerm_linux_web_app.app_cm[0].id,
        azurerm_windows_web_app.app_cm[0].id,
        azurerm_linux_web_app.app_cm_full[0].id,
        azurerm_windows_web_app.app_cm_full[0].id
      )
      name = try(
        azurerm_linux_web_app.app_cm[0].name,
        azurerm_windows_web_app.app_cm[0].name,
        azurerm_linux_web_app.app_cm_full[0].name,
        azurerm_windows_web_app.app_cm_full[0].name
      )
    }
  }
  description = "Information about the deployed App Services for SCEPman"
}

output "scepman_application" {
  value = {
    azuread_application = {
      id        = one(module.appreg_scepman[*].id)
      object_id = one(module.appreg_scepman[*].object_id)
      client_id = one(module.appreg_scepman[*].client_id)
      api_scope = local.scepman_api_scope
    }
    service_principal = {
      id           = one(azuread_service_principal.scepman[*].id)
      display_name = one(azuread_service_principal.scepman[*].display_name)
      object_id    = one(azuread_service_principal.scepman[*].object_id)
    }
  }
  description = "Information about the Application and Service Principal for the SCEPman API"
}

output "certmaster_application" {
  value = {
    azuread_application = {
      id        = try(one(module.appreg_certmaster[*].id), null)
      object_id = try(one(module.appreg_certmaster[*].object_id), null)
      client_id = try(one(module.appreg_certmaster[*].client_id), null)
    }
    service_principal = {
      id           = try(one(azuread_service_principal.certmaster[*].id), null)
      display_name = try(one(azuread_service_principal.certmaster[*].display_name), null)
      object_id    = try(one(azuread_service_principal.certmaster[*].object_id), null)
    }
  }
  description = "Information about the Application and Service Principal for the SCEPman Certificate Master"
}

output "primary_mi_principal_id" {
  value       = local.scepman_mi_principal_id
  description = "principal_id of the system assigned managed identity of the SCEPman primary app"
}

output "certmaster_mi_principal_id" {
  value       = local.cm_mi_principal_id
  description = "principal_id of the system assigned managed identity of the SCEPman certificate master"
}

output "dcr_id" {
  value       = try(azurerm_monitor_data_collection_rule.scepman[0].id, null)
  description = "Resource ID of the Data Collection Rule for SCEPman logs. Null when enable_dcr_log_ingestion is false."
}

output "dce_id" {
  value       = try(azurerm_monitor_data_collection_endpoint.scepman[0].id, null)
  description = "Resource ID of the Data Collection Endpoint for SCEPman log ingestion. Null when enable_dcr_log_ingestion is false."
}

output "dcr_immutable_id" {
  value       = try(azurerm_monitor_data_collection_rule.scepman[0].immutable_id, null)
  description = "Immutable ID of the Data Collection Rule. Null when enable_dcr_log_ingestion is false."
}
