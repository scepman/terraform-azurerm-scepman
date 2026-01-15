
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
  name                  = azurerm_virtual_network.vnet-scepman.name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsprivatezone-kv.name
  virtual_network_id    = azurerm_virtual_network.vnet-scepman.id
}

resource "azurerm_private_dns_zone" "dnsprivatezone-sts" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink-sts" {
  name                  = azurerm_virtual_network.vnet-scepman.name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsprivatezone-sts.name
  virtual_network_id    = azurerm_virtual_network.vnet-scepman.id
}


# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage_pe" {
  name                = "pe-${azurerm_storage_account.storage.name}"
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


# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault_pe" {
  name                = "pe-${azurerm_key_vault.vault.name}"
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