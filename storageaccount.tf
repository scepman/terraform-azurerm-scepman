# Storage Account

resource "azurerm_storage_account" "storage" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  public_network_access           = var.storage_account_public_network_access_enabled ? "Enabled" : "Disabled"
  min_tls_version                 = var.storage_account_min_tls_version
  allow_nested_items_to_be_public = var.storage_account_allow_nested_items_to_be_public
  shared_access_key_enabled       = var.storage_account_shared_access_key_enabled

  network_rules {
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
    bypass                     = var.storage_account_trusted_services_enabled ? ["AzureServices"] : ["None"]
  }

  account_tier             = "Standard"
  account_replication_type = var.storage_account_replication_type

  dynamic "sas_policy" {
    for_each = var.storage_account_sas_expiration_period != null ? [var.storage_account_sas_expiration_period] : []
    content {
      expiration_period = sas_policy.value
    }
  }

  dynamic "blob_properties" {
    for_each = var.storage_account_blob_soft_delete_retention_days > 0 || var.storage_account_container_soft_delete_retention_days > 0 ? [1] : []
    content {
      dynamic "delete_retention_policy" {
        for_each = var.storage_account_blob_soft_delete_retention_days > 0 ? [var.storage_account_blob_soft_delete_retention_days] : []
        content {
          days = delete_retention_policy.value
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = var.storage_account_container_soft_delete_retention_days > 0 ? [var.storage_account_container_soft_delete_retention_days] : []
        content {
          days = container_delete_retention_policy.value
        }
      }
    }
  }

  dynamic "identity" {
    for_each = var.storage_account_managed_identity_enabled ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      network_rules[0].private_link_access
    ]
  }
}

# Role Assignment - Storage Table Data Contributor

locals {
  object_ids = {
    scepman    = local.scepman_mi_principal_id
    certmaster = local.cm_mi_principal_id
  }
}

moved {
  from = azurerm_role_assignment.table_contributor["0"]
  to   = azurerm_role_assignment.table_contributor["scepman"]
}

moved {
  from = azurerm_role_assignment.table_contributor["1"]
  to   = azurerm_role_assignment.table_contributor["certmaster"]
}

resource "azurerm_role_assignment" "table_contributor" {
  for_each = local.object_ids

  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = each.value
}
