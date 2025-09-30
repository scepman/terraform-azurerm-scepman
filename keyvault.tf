# Key Vault

resource "azurerm_key_vault" "vault" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  rbac_authorization_enabled = var.key_vault_use_rbac

  enabled_for_disk_encryption     = false
  enabled_for_deployment          = false
  enabled_for_template_deployment = false

  public_network_access_enabled = false

  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  tags = var.tags
}

locals {
  key_vault_roles = {
    "Key Vault Crypto Officer"       = "kv_crypto_officer"
    "Key Vault Certificates Officer" = "kv_certificates_officer"
    "Key Vault Secrets User"         = "kv_secrets_user"
  }
  primary_app_principal_id = lower(var.service_plan_os_type) == "linux" ? azurerm_linux_web_app.app[0].identity[0].principal_id : azurerm_windows_web_app.app[0].identity[0].principal_id
}

# Key Vault Access Policy
resource "azurerm_key_vault_access_policy" "scepman" {
  count = azurerm_key_vault.vault.rbac_authorization_enabled ? 0 : 1

  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = local.primary_app_principal_id

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

resource "azurerm_role_assignment" "kv_roles" {
  for_each = azurerm_key_vault.vault.rbac_authorization_enabled ? local.key_vault_roles : {}

  scope                = azurerm_key_vault.vault.id
  role_definition_name = each.key
  principal_id         = local.primary_app_principal_id
}
