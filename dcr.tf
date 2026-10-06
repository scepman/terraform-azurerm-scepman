# Data Collection Rule (DCR) based log ingestion
# Replaces the deprecated Data Collector API (shared key based)

resource "azurerm_monitor_data_collection_endpoint" "scepman" {
  count = var.enable_dcr_log_ingestion ? 1 : 0

  name                = var.dce_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

resource "azurerm_log_analytics_workspace_table_custom_log" "scepman" {
  count = var.enable_dcr_log_ingestion ? 1 : 0

  workspace_id = local.law_id
  name         = "SCEPman_CL"

  column {
    name = "TimeGenerated"
    type = "datetime"
  }
  column {
    name = "Timestamp"
    type = "string"
  }
  column {
    name = "Level"
    type = "string"
  }
  column {
    name = "Message"
    type = "string"
  }
  column {
    name = "Exception"
    type = "string"
  }
  column {
    name = "TenantIdentifier"
    type = "string"
  }
  column {
    name = "RequestUrl"
    type = "string"
  }
  column {
    name = "UserAgent"
    type = "string"
  }
  column {
    name = "LogCategory"
    type = "string"
  }
  column {
    name = "EventId"
    type = "string"
  }
  column {
    name = "Hostname"
    type = "string"
  }
  column {
    name = "WebsiteHostname"
    type = "string"
  }
  column {
    name = "WebsiteSiteName"
    type = "string"
  }
  column {
    name = "WebsiteSlotName"
    type = "string"
  }
  column {
    name = "BaseUrl"
    type = "string"
  }
  column {
    name = "TraceIdentifier"
    type = "string"
  }
}

resource "azurerm_monitor_data_collection_rule" "scepman" {
  count = var.enable_dcr_log_ingestion ? 1 : 0

  name                        = var.dcr_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.scepman[0].id
  kind                        = "Direct"
  description                 = "Data Collection Rule for SCEPman logs"

  destinations {
    log_analytics {
      workspace_resource_id = local.law_id
      name                  = "SCEPmanLogAnalyticsDestination"
    }
  }

  stream_declaration {
    stream_name = "Custom-SCEPmanLogs"

    column {
      name = "TimeGenerated"
      type = "datetime"
    }
    column {
      name = "Timestamp"
      type = "string"
    }
    column {
      name = "Level"
      type = "string"
    }
    column {
      name = "Message"
      type = "string"
    }
    column {
      name = "Exception"
      type = "string"
    }
    column {
      name = "TenantIdentifier"
      type = "string"
    }
    column {
      name = "RequestUrl"
      type = "string"
    }
    column {
      name = "UserAgent"
      type = "string"
    }
    column {
      name = "LogCategory"
      type = "string"
    }
    column {
      name = "EventId"
      type = "string"
    }
    column {
      name = "Hostname"
      type = "string"
    }
    column {
      name = "WebsiteHostname"
      type = "string"
    }
    column {
      name = "WebsiteSiteName"
      type = "string"
    }
    column {
      name = "WebsiteSlotName"
      type = "string"
    }
    column {
      name = "BaseUrl"
      type = "string"
    }
    column {
      name = "TraceIdentifier"
      type = "string"
    }
  }

  data_flow {
    streams       = ["Custom-SCEPmanLogs"]
    destinations  = ["SCEPmanLogAnalyticsDestination"]
    output_stream = "Custom-SCEPman_CL"
  }

  depends_on = [azurerm_log_analytics_workspace_table_custom_log.scepman]

  tags = var.tags
}

# Role assignments: Monitoring Metrics Publisher on the DCR for both app service managed identities
resource "azurerm_role_assignment" "scepman_primary_dcr_metrics_publisher" {
  count = var.enable_dcr_log_ingestion ? 1 : 0

  scope                = azurerm_monitor_data_collection_rule.scepman[0].id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = local.scepman_mi_principal_id
}

resource "azurerm_role_assignment" "scepman_certmaster_dcr_metrics_publisher" {
  count = var.enable_dcr_log_ingestion ? 1 : 0

  scope                = azurerm_monitor_data_collection_rule.scepman[0].id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = local.cm_mi_principal_id
}
