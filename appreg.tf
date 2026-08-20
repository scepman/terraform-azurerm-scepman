
locals {
  scepman_approles = [
    {
      allowed_member_types = ["Application"]
      description          = "Request certificates via the raw CSR API. Only used internally for SCEPman."
      display_name         = "CSR Requesters"
      value                = "CSR.Request"
    },
    {
      allowed_member_types = ["Application"]
      description          = "Request certificates via the raw CSR API that automatically stores issued certificates"
      display_name         = "CSR DB Requesters"
      value                = "CSR.Request.Db"
    },
    {
      allowed_member_types = ["Application"]
      description          = "Request certificates via the raw CSR API with the caller being responsible for storing the certificates. Only used internally for SCEPman."
      display_name         = "Direct CSR Requesters"
      value                = "CSR.Request.Direct"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request certificates via EST or the raw CSR API for your own devices or your own user account."
      display_name         = "CSR Self Service"
      value                = "CSR.SelfService"
    },
    {
      allowed_member_types = ["Application", "User"]
      description          = "Use the Management API to see and revoke all issued certificates"
      display_name         = "Manage All"
      value                = "Manage.All"
    },
  ]

  certmaster_approles = [
    {
      allowed_member_types = ["User"]
      description          = "Full access to all SCEPman CertMaster functions like requesting and managing certificates"
      display_name         = "Full Admin"
      value                = "Admin.Full"
    },
    {
      allowed_member_types = ["User"]
      description          = "See and revoke all issued certificates"
      display_name         = "Manage All"
      value                = "Manage.All"
    },
    {
      allowed_member_types = ["User"]
      description          = "See all issued certificates"
      display_name         = "Manage All Readonly"
      value                = "Manage.All.Read"
    },
    {
      allowed_member_types = ["User"]
      description          = "See and revoke certificates listed in the Azure Storage Account"
      display_name         = "Manage Storage Certificates"
      value                = "Manage.Storage"
    },
    {
      allowed_member_types = ["User"]
      description          = "See certificates listed in the Azure Storage Account"
      display_name         = "Manage Storage Certificates Readonly"
      value                = "Manage.Storage.Read"
    },
    {
      allowed_member_types = ["User"]
      description          = "See and revoke certificates enrolled via Intune"
      display_name         = "Manage Intune Certificates"
      value                = "Manage.Intune"
    },
    {
      allowed_member_types = ["User"]
      description          = "See certificates enrolled via Intune"
      display_name         = "Manage Intune Certificates Readonly"
      value                = "Manage.Intune.Read"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request certificates of all types"
      display_name         = "Request All"
      value                = "Request.All"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request client certificates"
      display_name         = "Request Client"
      value                = "Request.Client"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request user certificates"
      display_name         = "Request User"
      value                = "Request.User"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request code signing certificates"
      display_name         = "Request Code Signing"
      value                = "Request.CodeSigning"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request Subordinate CA certificates for Firewalls"
      display_name         = "Request Subordinate CA"
      value                = "Request.SubCa"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request TLS server certificates"
      display_name         = "Request Server"
      value                = "Request.Server"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request certificates of all types using CSR"
      display_name         = "Request All (CSR)"
      value                = "Request.All.Csr"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request certificates of all types using form"
      display_name         = "Request All (Form)"
      value                = "Request.All.Form"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request client certificates using CSR"
      display_name         = "Request Client (CSR)"
      value                = "Request.Client.Csr"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request client certificates using form"
      display_name         = "Request Client (Form)"
      value                = "Request.Client.Form"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request user certificates using CSR"
      display_name         = "Request User (CSR)"
      value                = "Request.User.Csr"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request user certificates using form"
      display_name         = "Request User (Form)"
      value                = "Request.User.Form"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request code signing certificates using CSR"
      display_name         = "Request Code Signing (CSR)"
      value                = "Request.CodeSigning.Csr"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request code signing certificates using form"
      display_name         = "Request Code Signing (Form)"
      value                = "Request.CodeSigning.Form"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request Subordinate CA certificates for Firewalls using CSR"
      display_name         = "Request Subordinate CA (CSR)"
      value                = "Request.SubCa.Csr"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request Subordinate CA certificates for Firewalls using form"
      display_name         = "Request Subordinate CA (Form)"
      value                = "Request.SubCa.Form"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request server certificates using CSR"
      display_name         = "Request Server (CSR)"
      value                = "Request.Server.Csr"
    },
    {
      allowed_member_types = ["User"]
      description          = "Request server certificates using form"
      display_name         = "Request Server (Form)"
      value                = "Request.Server.Form"
    }
  ]

  scepman_mi_principal_id = try(
    azurerm_linux_web_app.app[0].identity[0].principal_id,
    azurerm_windows_web_app.app[0].identity[0].principal_id,
    azurerm_linux_web_app.app_full[0].identity[0].principal_id,
    azurerm_windows_web_app.app_full[0].identity[0].principal_id
  )

  cm_mi_principal_id = try(
    azurerm_linux_web_app.app_cm[0].identity[0].principal_id,
    azurerm_windows_web_app.app_cm[0].identity[0].principal_id,
    azurerm_linux_web_app.app_cm_full[0].identity[0].principal_id,
    azurerm_windows_web_app.app_cm_full[0].identity[0].principal_id
  )

  certmaster_base_url = format("https://%s", local.default_hostname_cm)
}

data "azuread_application_published_app_ids" "well_known" {
  count = var.manage_entra_apps ? 1 : 0
}

data "azuread_service_principal" "msgraph" {
  count     = var.manage_entra_apps ? 1 : 0
  client_id = data.azuread_application_published_app_ids.well_known[0].result["MicrosoftGraph"]
}

data "azuread_service_principal" "intune" {
  count     = var.manage_entra_apps ? 1 : 0
  client_id = data.azuread_application_published_app_ids.well_known[0].result["InTune"]
}

module "appreg_scepman" {
  count  = var.manage_entra_apps ? 1 : 0
  source = "./modules/application_registration"

  display_name                       = "SCEPman-api"
  sign_in_audience                   = "AzureADMyOrg"
  implicit_id_token_issuance_enabled = true

  app_roles = local.scepman_approles
}

resource "azuread_service_principal" "scepman" {
  count     = var.manage_entra_apps ? 1 : 0
  client_id = module.appreg_scepman[0].client_id

  depends_on = [module.appreg_scepman[0]]

  feature_tags {
    hide = true
  }
}

locals {
  scepman_api_scope = var.manage_entra_apps ? "api://${module.appreg_scepman[0].client_id}" : null
}

module "appreg_certmaster" {
  count  = var.manage_entra_apps ? 1 : 0
  source = "./modules/application_registration"

  display_name                       = "SCEPman-CertMaster"
  sign_in_audience                   = "AzureADMyOrg"
  implicit_id_token_issuance_enabled = true

  app_roles = local.certmaster_approles
}
resource "azuread_service_principal" "certmaster" {
  count     = var.manage_entra_apps ? 1 : 0
  client_id = module.appreg_certmaster[0].client_id

  feature_tags {
    hide = false
  }
}
resource "azuread_application_redirect_uris" "appreg_certmaster" {
  count          = var.manage_entra_apps ? 1 : 0
  application_id = module.appreg_certmaster[0].id
  type           = "SPA"

  redirect_uris = [
    format("%s/signin-oidc", local.certmaster_base_url)
  ]
}

resource "azuread_application_api_access" "certmaster_graph" {
  count          = var.manage_entra_apps ? 1 : 0
  application_id = module.appreg_certmaster[0].id
  api_client_id  = data.azuread_application_published_app_ids.well_known[0].result["MicrosoftGraph"]

  scope_ids = [
    data.azuread_service_principal.msgraph[0].oauth2_permission_scope_ids["User.Read"],
    data.azuread_service_principal.msgraph[0].oauth2_permission_scope_ids["offline_access"],
  ]
}

resource "azuread_service_principal_delegated_permission_grant" "certmaster_graph" {
  count                                = var.manage_entra_apps ? 1 : 0
  service_principal_object_id          = azuread_service_principal.certmaster[0].object_id
  resource_service_principal_object_id = data.azuread_service_principal.msgraph[0].object_id
  claim_values = [
    "User.Read",
    "offline_access",
  ]
}



resource "azuread_app_role_assignment" "mi_scepman_directory_read_all" {
  count               = var.manage_entra_apps ? 1 : 0
  app_role_id         = data.azuread_service_principal.msgraph[0].app_role_ids["Directory.Read.All"]
  principal_object_id = local.scepman_mi_principal_id
  resource_object_id  = data.azuread_service_principal.msgraph[0].object_id
}
resource "azuread_app_role_assignment" "mi_scepman_device_management_config_read_all" {
  count               = var.manage_entra_apps ? 1 : 0
  app_role_id         = data.azuread_service_principal.msgraph[0].app_role_ids["DeviceManagementConfiguration.Read.All"]
  principal_object_id = local.scepman_mi_principal_id
  resource_object_id  = data.azuread_service_principal.msgraph[0].object_id
}
resource "azuread_app_role_assignment" "mi_scepman_device_management_managed_devices_read_all" {
  count               = var.manage_entra_apps ? 1 : 0
  app_role_id         = data.azuread_service_principal.msgraph[0].app_role_ids["DeviceManagementManagedDevices.Read.All"]
  principal_object_id = local.scepman_mi_principal_id
  resource_object_id  = data.azuread_service_principal.msgraph[0].object_id
}
resource "azuread_app_role_assignment" "mi_scepman_identity_risky_user_read_all" {
  count               = var.manage_entra_apps ? 1 : 0
  app_role_id         = data.azuread_service_principal.msgraph[0].app_role_ids["IdentityRiskyUser.Read.All"]
  principal_object_id = local.scepman_mi_principal_id
  resource_object_id  = data.azuread_service_principal.msgraph[0].object_id
}
resource "azuread_app_role_assignment" "mi_scepman_intune_scep_challenge_provider" {
  count               = var.manage_entra_apps ? 1 : 0
  app_role_id         = data.azuread_service_principal.intune[0].app_role_ids["scep_challenge_provider"]
  principal_object_id = local.scepman_mi_principal_id
  resource_object_id  = data.azuread_service_principal.intune[0].object_id
}


resource "azuread_app_role_assignment" "mi_cm_csr_request" {
  count               = var.manage_entra_apps ? 1 : 0
  app_role_id         = module.appreg_scepman[0].app_role_ids["CSR.Request"]
  principal_object_id = local.cm_mi_principal_id
  resource_object_id  = azuread_service_principal.scepman[0].object_id
}
resource "azuread_app_role_assignment" "mi_cm_graph_device_management_config_read_all" {
  count               = var.manage_entra_apps ? 1 : 0
  app_role_id         = data.azuread_service_principal.msgraph[0].app_role_ids["DeviceManagementConfiguration.Read.All"]
  principal_object_id = local.cm_mi_principal_id
  resource_object_id  = data.azuread_service_principal.msgraph[0].object_id
}
resource "azuread_app_role_assignment" "mi_cm_graph_device_management_managed_devices_read_all" {
  count               = var.manage_entra_apps ? 1 : 0
  app_role_id         = data.azuread_service_principal.msgraph[0].app_role_ids["DeviceManagementManagedDevices.Read.All"]
  principal_object_id = local.cm_mi_principal_id
  resource_object_id  = data.azuread_service_principal.msgraph[0].object_id
}
