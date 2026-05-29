# vnet and subnet for internal communication

moved {
  from = azurerm_network_security_group.nsg-endpoints
  to   = azurerm_network_security_group.nsg-endpoints[0]
}

moved {
  from = azurerm_network_security_group.nsg-appservices
  to   = azurerm_network_security_group.nsg-appservices[0]
}

moved {
  from = azurerm_virtual_network.vnet-scepman
  to   = azurerm_virtual_network.vnet-scepman[0]
}

moved {
  from = azurerm_private_dns_zone.dnsprivatezone-kv
  to   = azurerm_private_dns_zone.dnsprivatezone-kv[0]
}

moved {
  from = azurerm_private_dns_zone_virtual_network_link.dnszonelink-kv
  to   = azurerm_private_dns_zone_virtual_network_link.dnszonelink-kv[0]
}

moved {
  from = azurerm_private_dns_zone.dnsprivatezone-sts
  to   = azurerm_private_dns_zone.dnsprivatezone-sts[0]
}

moved {
  from = azurerm_private_dns_zone_virtual_network_link.dnszonelink-sts
  to   = azurerm_private_dns_zone_virtual_network_link.dnszonelink-sts[0]
}

moved {
  from = azurerm_private_endpoint.storage_pe
  to   = azurerm_private_endpoint.storage_pe[0]
}

moved {
  from = azurerm_private_endpoint.key_vault_pe
  to   = azurerm_private_endpoint.key_vault_pe[0]
}

removed {
  from = azurerm_subnet.subnet-endpoints
  lifecycle {
    destroy = false
  }
}

removed {
  from = azurerm_subnet.subnet-appservices
  lifecycle {
    destroy = false
  }
}

# Network Security Group for endpoints subnet
resource "azurerm_network_security_group" "nsg-endpoints" {
  count = local.create_networking ? 1 : 0

  name                = var.nsg_endpoints_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Network Security Group for app services subnet
resource "azurerm_network_security_group" "nsg-appservices" {
  count = local.create_networking ? 1 : 0

  name                = var.nsg_appservices_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_virtual_network" "vnet-scepman" {
  count = local.create_networking ? 1 : 0

  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space

  tags = var.tags

  subnet {
    name                            = var.subnet_appservices_name
    address_prefixes                = [local.subnet_appservices_address_prefix]
    default_outbound_access_enabled = false
    security_group                  = azurerm_network_security_group.nsg-appservices[0].id
    delegation {
      name = "delegation"
      service_delegation {
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        name    = "Microsoft.Web/serverFarms"
      }
    }
  }

  subnet {
    name                            = var.subnet_endpoints_name
    address_prefixes                = [local.subnet_endpoints_address_prefix]
    default_outbound_access_enabled = false
    security_group                  = azurerm_network_security_group.nsg-endpoints[0].id
  }
}

resource "azurerm_private_dns_zone" "dnsprivatezone-kv" {
  count = local.create_networking ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink-kv" {
  count = local.create_networking ? 1 : 0

  name                  = "dnszonelink-kv"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsprivatezone-kv[0].name
  virtual_network_id    = azurerm_virtual_network.vnet-scepman[0].id

  tags = var.tags
}

resource "azurerm_private_dns_zone" "dnsprivatezone-sts" {
  count = local.create_networking ? 1 : 0

  name                = "privatelink.table.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink-sts" {
  count = local.create_networking ? 1 : 0

  name                  = "dnszonelink-sts"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsprivatezone-sts[0].name
  virtual_network_id    = azurerm_virtual_network.vnet-scepman[0].id

  tags = var.tags
}


# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage_pe" {
  count = local.create_networking ? 1 : 0

  name                = "pep-sts-scepman"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = local.subnet_endpoints_id

  tags = var.tags

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsprivatezone-sts[0].id]
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
  count = local.create_networking ? 1 : 0

  name                = "pep-kv-scepman"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = local.subnet_endpoints_id

  tags = var.tags

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsprivatezone-kv[0].id]
  }

  private_service_connection {
    name                           = "keyvaultconnection"
    private_connection_resource_id = azurerm_key_vault.vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}
