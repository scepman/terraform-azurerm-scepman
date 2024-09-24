# Version requirements

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.102.0"
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

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

module "scepman" {
  # Option 1: Local module, use from local development
  # source = "../.." # This is the local path to the module

  # Option 2: Use the terraform registry version
  source = "scepman/scepman/azurerm"
  # version = "0.1.0"

  organization_name   = var.organization_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  storage_account_name = var.storage_account_name
  key_vault_name       = var.key_vault_name
  law_name             = var.law_name

  service_plan_name                   = var.service_plan_name
  app_service_name_primary            = var.app_service_name_primary
  app_service_name_certificate_master = var.app_service_name_certificate_master

  app_settings_primary            = var.app_settings_primary
  app_settings_certificate_master = var.app_settings_certificate_master

  enable_application_insights = var.enable_application_insights

  tags = var.tags
}
