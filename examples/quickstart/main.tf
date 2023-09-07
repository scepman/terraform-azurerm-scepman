# Version requirements

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.28.0"
    }
  }
  backend "local" {}

  required_version = ">= 1.3"
}

# Provider configuration

provider "azurerm" {
  features {}
  partner_id = "a262352f-52a9-4ed9-a9ba-6a2b2478d19b"
}

# Resources

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

locals {
  unique_key = substr(sha256(format("%s%s", data.azurerm_client_config.current.subscription_id, var.resource_group_name)), 0, 6)

  storage_account_name = format("stscepman%s", local.unique_key)
  key_vault_name       = format("kv-scepman-%s", local.unique_key)

  service_plan_name                   = format("asp-scepman-%s", local.unique_key)
  app_service_name_primary            = format("app-scepman-%s", local.unique_key)
  app_service_name_certificate_master = format("app-scepman-cm-%s", local.unique_key)
}

module "scepman" {
  # Option 1: Local module, use from local development
  # source = "../.." # This is the local path to the module

  # Option 2: Use the terraform registry version
  source = "glueckkanja-gab/scepman/azurerm"
  # version = "0.1.0"


  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  storage_account_name = local.storage_account_name
  key_vault_name       = local.key_vault_name

  service_plan_name                   = local.service_plan_name
  app_service_name_primary            = local.app_service_name_primary
  app_service_name_certificate_master = local.app_service_name_certificate_master

  tags = var.tags
}
