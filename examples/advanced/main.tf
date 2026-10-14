# Version requirements

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.42"
    }
  }
  backend "local" {}

  required_version = ">= 1.9"
}

# Provider configuration

provider "azurerm" {
  features {}
  storage_use_azuread = true
  partner_id          = "a262352f-52a9-4ed9-a9ba-6a2b2478d19b"
  subscription_id     = var.subscription_id
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

  storage_account_name                     = var.storage_account_name
  key_vault_name                           = var.key_vault_name
  law_name                                 = var.law_name
  storage_account_managed_identity_enabled = var.storage_account_managed_identity_enabled

  service_plan_os_type                = var.service_plan_os_type
  service_plan_name                   = var.service_plan_name
  app_service_name_primary            = var.app_service_name_primary
  app_service_name_certificate_master = var.app_service_name_certificate_master

  app_settings_primary            = var.app_settings_primary
  app_settings_certificate_master = var.app_settings_certificate_master

  enable_application_insights = var.enable_application_insights
  manage_entra_apps           = true

  # Optional: Configure network access restrictions for the primary SCEPman app
  # network_access_restrictions_primary = {
  #   public_network_access_enabled = true
  #   ip_restriction_default_action = "Deny"
  #   ip_restrictions = [
  #     {
  #       name       = "allow-corp-vpn"
  #       priority   = 100
  #       action     = "Allow"
  #       ip_address = "203.0.113.0/24"
  #     }
  #   ]
  #   scm_ip_restriction_default_action = "Deny"
  #   scm_ip_restrictions = [
  #     {
  #       name        = "allow-build-agents"
  #       priority    = 100
  #       action      = "Allow"
  #       service_tag = "AzureDevOps"
  #     }
  #   ]
  # }

  # Optional: Configure network access restrictions for Certificate Master
  # network_access_restrictions_certificate_master = {
  #   public_network_access_enabled     = false
  #   ip_restriction_default_action     = "Deny"
  #   scm_ip_restriction_default_action = "Deny"
  # }

  tags = var.tags
}
