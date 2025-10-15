terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.8"
    }
  }
  required_version = ">= 1.3"
}

data "azurerm_client_config" "current" {}

# Log Analytics Workspace

# Get exisiting Log Analytics Workspace if law_resource_group_name is defined and no cross subscription details are provided
data "azurerm_log_analytics_workspace" "existing-law" {
  count               = (var.law_resource_group_name != null && var.law_name != null && var.law_cross_subscription_details == null) ? 1 : 0
  name                = var.law_name
  resource_group_name = var.law_resource_group_name
}

resource "azurerm_log_analytics_workspace" "law" {
  count = (var.law_cross_subscription_details == null && length(data.azurerm_log_analytics_workspace.existing-law) == 0) ? 1 : 0

  name                = var.law_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = var.tags
}

locals {
  # Prioritize workspace details from cross-subscription input, then data lookup, and finally the workspace created by this module.
  law_details = var.law_cross_subscription_details != null ? var.law_cross_subscription_details : length(data.azurerm_log_analytics_workspace.existing-law) > 0 ? {
      id           = data.azurerm_log_analytics_workspace.existing-law[0].id
      workspace_id = data.azurerm_log_analytics_workspace.existing-law[0].workspace_id
      shared_key   = data.azurerm_log_analytics_workspace.existing-law[0].primary_shared_key
    } : {
      id           = azurerm_log_analytics_workspace.law[0].id
      workspace_id = azurerm_log_analytics_workspace.law[0].workspace_id
      shared_key   = azurerm_log_analytics_workspace.law[0].primary_shared_key
    }

  law_id           = local.law_details.id
  law_workspace_id = local.law_details.workspace_id
  law_shared_key   = local.law_details.shared_key
}

# Application Insights
# Creating Application Insights will not allow terraform to destroy the ressource group, as app insights create hidden rules that can (currently) not be managed by terraform

resource "azurerm_application_insights" "scepman-primary" {
  count               = var.enable_application_insights == true ? 1 : 0
  name                = format("%s_app-insights", var.app_service_name_primary)
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = local.law_id
  application_type    = "web"

  tags = var.tags
}
resource "azurerm_application_insights" "scepman-cm" {
  count               = var.enable_application_insights == true ? 1 : 0
  name                = format("%s_app-insights", var.app_service_name_certificate_master)
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = local.law_id
  application_type    = "web"

  tags = var.tags
}
