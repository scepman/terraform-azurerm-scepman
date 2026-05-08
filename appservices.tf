
resource "time_offset" "managed_identity" {
  offset_minutes = 5
}


### Windows App Service
# Scepman Primary
resource "azurerm_windows_web_app" "app" {
  count                         = (lower(var.service_plan_os_type) == "windows" && !var.manage_entra_apps) ? 1 : 0
  name                          = var.app_service_name_primary
  resource_group_name           = var.resource_group_name
  location                      = var.location
  https_only                    = false
  virtual_network_subnet_id     = "${azurerm_virtual_network.vnet-scepman.id}/subnets/${var.subnet_appservices_name}"
  public_network_access_enabled = local.network_restrictions_primary != null ? local.network_restrictions_primary.public_network_access_enabled : null

  service_plan_id = local.service_plan_resource_id

  identity {
    type         = local.app_service_primary_identity.type
    identity_ids = local.app_service_primary_identity.identity_ids
  }

  site_config {
    health_check_path                 = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker                 = false
    minimum_tls_version               = var.app_service_minimum_tls_version_scepman
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }

    ip_restriction_default_action     = local.network_restrictions_primary != null ? local.network_restrictions_primary.ip_restriction_default_action : null
    scm_ip_restriction_default_action = local.network_restrictions_primary != null ? local.network_restrictions_primary.scm_ip_restriction_default_action : null

    dynamic "ip_restriction" {
      for_each = local.network_restrictions_primary != null ? local.network_restrictions_primary.ip_restrictions : []
      content {
        action                    = ip_restriction.value.action
        ip_address                = ip_restriction.value.ip_address
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = local.network_restrictions_primary != null ? local.network_restrictions_primary.scm_ip_restrictions : []
      content {
        action                    = scm_ip_restriction.value.action
        ip_address                = scm_ip_restriction.value.ip_address
        name                      = scm_ip_restriction.value.name
        priority                  = scm_ip_restriction.value.priority
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = scm_ip_restriction.value.headers != null ? [scm_ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }
  }

  app_settings = lower(var.service_plan_os_type) == "windows" ? { for k, v in local.app_settings_primary : replace(k, "__", ":") => v } : local.app_settings_primary

  tags = var.tags

  logs {
    detailed_error_messages = var.app_service_logs_detailed_error_messages
    failed_request_tracing  = var.app_service_logs_failed_request_tracing

    application_logs {
      file_system_level = var.app_service_application_logs_file_system_level
    }

    http_logs {
      file_system {
        retention_in_days = length(azurerm_application_insights.scepman-primary) > 0 ? 0 : var.app_service_retention_in_days
        retention_in_mb   = var.app_service_retention_in_mb
      }
    }
  }

  lifecycle {
    # CA Key type must be specific
    precondition {
      condition     = local.app_settings_primary["AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType"] == "RSA" || local.app_settings_primary["AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType"] == "RSA-HSM"
      error_message = "Possible values are 'RSA' or 'RSA-HSM'"
    }

    ignore_changes = [
      app_settings["AppConfig:AuthConfig:ApplicationId"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityEnabledForWebsiteHostname"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityEnabledOnUnixTime"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityPermissionLevel"],
      app_settings["AppConfig:CertMaster:URL"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      tags,
      sticky_settings
    ]
  }
}

# Certificate Master App Service
resource "azurerm_windows_web_app" "app_cm" {
  count                         = (lower(var.service_plan_os_type) == "windows" && !var.manage_entra_apps) ? 1 : 0
  name                          = var.app_service_name_certificate_master
  resource_group_name           = var.resource_group_name
  location                      = var.location
  https_only                    = true
  virtual_network_subnet_id     = "${azurerm_virtual_network.vnet-scepman.id}/subnets/${var.subnet_appservices_name}"
  public_network_access_enabled = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.public_network_access_enabled : null

  service_plan_id = local.service_plan_resource_id

  identity {
    type         = local.app_service_certificate_master_identity.type
    identity_ids = local.app_service_certificate_master_identity.identity_ids
  }

  site_config {
    health_check_path                 = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker                 = false
    minimum_tls_version               = var.app_service_minimum_tls_version_certificate_master
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }

    ip_restriction_default_action     = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.ip_restriction_default_action : null
    scm_ip_restriction_default_action = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.scm_ip_restriction_default_action : null

    dynamic "ip_restriction" {
      for_each = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.ip_restrictions : []
      content {
        action                    = ip_restriction.value.action
        ip_address                = ip_restriction.value.ip_address
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.scm_ip_restrictions : []
      content {
        action                    = scm_ip_restriction.value.action
        ip_address                = scm_ip_restriction.value.ip_address
        name                      = scm_ip_restriction.value.name
        priority                  = scm_ip_restriction.value.priority
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = scm_ip_restriction.value.headers != null ? [scm_ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }
  }

  app_settings = local.app_settings_certificate_master

  tags = var.tags

  logs {
    detailed_error_messages = var.app_service_logs_detailed_error_messages
    failed_request_tracing  = var.app_service_logs_failed_request_tracing

    application_logs {
      file_system_level = var.app_service_application_logs_file_system_level
    }

    http_logs {
      file_system {
        retention_in_days = length(azurerm_application_insights.scepman-cm) > 0 ? 0 : var.app_service_retention_in_days
        retention_in_mb   = var.app_service_retention_in_mb
      }
    }
  }

  lifecycle {

    ignore_changes = [
      app_settings["AppConfig:AuthConfig:ApplicationId"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityEnabledOnUnixTime"],
      app_settings["AppConfig:AuthConfig:ManagedIdentityPermissionLevel"],
      app_settings["AppConfig:AuthConfig:SCEPmanAPIScope"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      sticky_settings,
      tags
    ]
  }

}



### Linux App Service
# Scepman Primary
resource "azurerm_linux_web_app" "app" {
  count                         = lower(var.service_plan_os_type) == "linux" && !var.manage_entra_apps ? 1 : 0
  name                          = var.app_service_name_primary
  resource_group_name           = var.resource_group_name
  location                      = var.location
  https_only                    = false
  virtual_network_subnet_id     = "${azurerm_virtual_network.vnet-scepman.id}/subnets/${var.subnet_appservices_name}"
  public_network_access_enabled = local.network_restrictions_primary != null ? local.network_restrictions_primary.public_network_access_enabled : null

  service_plan_id = local.service_plan_resource_id

  identity {
    type         = local.app_service_primary_identity.type
    identity_ids = local.app_service_primary_identity.identity_ids
  }

  site_config {
    health_check_path                 = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker                 = false
    minimum_tls_version               = var.app_service_minimum_tls_version_scepman
    application_stack {
      #current_stack  = "dotnet"
      dotnet_version = "8.0"
    }

    ip_restriction_default_action     = local.network_restrictions_primary != null ? local.network_restrictions_primary.ip_restriction_default_action : null
    scm_ip_restriction_default_action = local.network_restrictions_primary != null ? local.network_restrictions_primary.scm_ip_restriction_default_action : null

    dynamic "ip_restriction" {
      for_each = local.network_restrictions_primary != null ? local.network_restrictions_primary.ip_restrictions : []
      content {
        action                    = ip_restriction.value.action
        ip_address                = ip_restriction.value.ip_address
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = local.network_restrictions_primary != null ? local.network_restrictions_primary.scm_ip_restrictions : []
      content {
        action                    = scm_ip_restriction.value.action
        ip_address                = scm_ip_restriction.value.ip_address
        name                      = scm_ip_restriction.value.name
        priority                  = scm_ip_restriction.value.priority
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = scm_ip_restriction.value.headers != null ? [scm_ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }
  }

  app_settings = lower(var.service_plan_os_type) == "linux" ? { for k, v in local.app_settings_primary : replace(k, ":", "__") => v } : local.app_settings_primary


  tags = var.tags

  logs {
    detailed_error_messages = var.app_service_logs_detailed_error_messages
    failed_request_tracing  = var.app_service_logs_failed_request_tracing

    application_logs {
      file_system_level = var.app_service_application_logs_file_system_level
    }

    http_logs {
      file_system {
        retention_in_days = length(azurerm_application_insights.scepman-primary) > 0 ? 0 : var.app_service_retention_in_days
        retention_in_mb   = var.app_service_retention_in_mb
      }
    }
  }

  lifecycle {
    # CA Key type must be specific
    precondition {
      condition     = local.app_settings_primary["AppConfig__KeyVaultConfig__RootCertificateConfig__KeyType"] == "RSA" || local.app_settings_primary["AppConfig__KeyVaultConfig__RootCertificateConfig__KeyType"] == "RSA-HSM"
      error_message = "Possible values are 'RSA' or 'RSA-HSM'"
    }

    ignore_changes = [
      app_settings["AppConfig__AuthConfig__ApplicationId"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityEnabledForWebsiteHostname"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityEnabledOnUnixTime"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityPermissionLevel"],
      app_settings["AppConfig__CertMaster__URL"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      sticky_settings,
      tags
    ]
  }
}

# Certificate Master App Service
resource "azurerm_linux_web_app" "app_cm" {
  count                         = (lower(var.service_plan_os_type) == "linux" && !var.manage_entra_apps) ? 1 : 0
  name                          = var.app_service_name_certificate_master
  resource_group_name           = var.resource_group_name
  location                      = var.location
  https_only                    = true
  virtual_network_subnet_id     = "${azurerm_virtual_network.vnet-scepman.id}/subnets/${var.subnet_appservices_name}"
  public_network_access_enabled = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.public_network_access_enabled : null

  service_plan_id = local.service_plan_resource_id

  identity {
    type         = local.app_service_certificate_master_identity.type
    identity_ids = local.app_service_certificate_master_identity.identity_ids
  }

  site_config {
    health_check_path                 = "/probe"
    health_check_eviction_time_in_min = 10
    use_32_bit_worker                 = false
    minimum_tls_version               = var.app_service_minimum_tls_version_certificate_master
    application_stack {
      #  current_stack  = "dotnet"
      dotnet_version = "8.0"
    }

    ip_restriction_default_action     = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.ip_restriction_default_action : null
    scm_ip_restriction_default_action = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.scm_ip_restriction_default_action : null

    dynamic "ip_restriction" {
      for_each = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.ip_restrictions : []
      content {
        action                    = ip_restriction.value.action
        ip_address                = ip_restriction.value.ip_address
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = local.network_restrictions_certificate_master != null ? local.network_restrictions_certificate_master.scm_ip_restrictions : []
      content {
        action                    = scm_ip_restriction.value.action
        ip_address                = scm_ip_restriction.value.ip_address
        name                      = scm_ip_restriction.value.name
        priority                  = scm_ip_restriction.value.priority
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id

        dynamic "headers" {
          for_each = scm_ip_restriction.value.headers != null ? [scm_ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
      }
    }
  }

  app_settings = local.app_settings_certificate_master

  tags = var.tags

  logs {
    detailed_error_messages = var.app_service_logs_detailed_error_messages
    failed_request_tracing  = var.app_service_logs_failed_request_tracing

    application_logs {
      file_system_level = var.app_service_application_logs_file_system_level
    }

    http_logs {
      file_system {
        retention_in_days = length(azurerm_application_insights.scepman-cm) > 0 ? 0 : var.app_service_retention_in_days
        retention_in_mb   = var.app_service_retention_in_mb
      }
    }
  }

  lifecycle {

    ignore_changes = [
      app_settings["AppConfig__AuthConfig__ApplicationId"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityEnabledOnUnixTime"],
      app_settings["AppConfig__AuthConfig__ManagedIdentityPermissionLevel"],
      app_settings["AppConfig__AuthConfig__SCEPmanAPIScope"],
      app_settings["WEBSITE_HEALTHCHECK_MAXPINGFAILURES"],
      sticky_settings,
      tags
    ]
  }

}
