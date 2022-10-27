# Version requirements

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.28.0"
    }
  }
  backend "local" {}

  required_version = "~> 1.3.3"
}

# Provider configuration

provider "azurerm" {
  features {}
}

# Resources

module "scepman" {
  source = "../.." # This is the local path to the module
  # to use the terraform registry version comment the previous line and uncomment the 2 lines below
  # source  = "glueckkanja-gab/scepman/azurerm"
  # version = "specify_version_number"


  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name = var.storage_account_name
  key_vault_name       = var.key_vault_name

  service_plan_name                   = var.service_plan_name
  app_service_name_primary            = var.app_service_name_primary
  app_service_name_certificate_master = var.app_service_name_certificate_master

  app_settings_primary            = var.app_settings_primary
  app_settings_certificate_master = var.app_settings_certificate_master

  tags = var.tags
}
