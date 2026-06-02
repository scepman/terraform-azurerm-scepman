# SCEPman - Certificates Simplified

[SCEPman Docs](https://docs.scepman.com)

SCEPman is a slim and resource-friendly solution to issue and validate certificates using SCEP.
It is an Azure Web App providing the SCEP protocol and works directly with the Microsoft Graph and Intune API. SCEPman uses an Azure Key Vault based Root CA and certificate creation. No other component is involved, neither a database nor any other stateful storage except the Azure Key Vault itself. That said, SCEPman will not need any backup procedures or other operation level tasks. Only an Azure subscription is necessary to deploy it.

## Prerequisites

- Access to an **Azure subscription** (or Resource Group) with `Owner` RBAC Role assigned to Principal used for deployment
- Terraform environment - local, GitHub Codespaces or Dev Containers

#### Local Environment:

- Setup your **environment** using the following guide [Getting Started](https://learn.microsoft.com/en-us/azure/developer/terraform/quickstart-configure)

#### GitHub Codespaces

- Repository contains GitHub [Codespaces](https://github.com/features/codespaces) dev container definitions

[Open in GitHub Codespaces](https://github.com/codespaces/new?hide_repo_select=true&repo=scepman%2Fterraform-azurerm-scepman)

#### Dev Containers

Visit [containers.dev](https://containers.dev) for more information

## Terraform State

- You can use local Terraform state for demo purposes
- We recommend to [Store Terraform state in Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli) for your Production environment

## Security defaults

- Storage account public network access and shared key authorization are disabled out of the box.
- A storage account SAS expiration policy defaults to 24 hours and can be adjusted through `storage_account_sas_expiration_period`.
- Optional inputs allow enabling trusted Microsoft services or soft-delete retention when required.
- Because shared keys are disabled, Terraform must use Azure AD for all storage data plane operations. Set `storage_use_azuread = true` in your provider configuration (or export `ARM_STORAGE_USE_AZUREAD=true`) and assign your deployment principal the roles `Storage Queue Data Contributor` and `Storage Table Data Contributor` on the storage account.

<!-- BEGIN_TF_DOCS -->


## Examples

### Quickstart Example

```hcl
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
  law_name                            = format("log-scepman-%s", local.unique_key)
}

module "scepman" {
  # Option 1: Local module, use from local development
  source = "../.." # This is the local path to the module

  # Option 2: Use the terraform registry version
  # source = "scepman/scepman/azurerm"
  # version = "0.1.0"


  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  storage_account_name = local.storage_account_name
  key_vault_name       = local.key_vault_name

  service_plan_name                   = local.service_plan_name
  app_service_name_primary            = local.app_service_name_primary
  app_service_name_certificate_master = local.app_service_name_certificate_master
  law_name                            = local.law_name
  manage_entra_apps                   = true

  tags = var.tags
}
```

### Advanced Example

```hcl
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

  tags = var.tags
}
```

To re-use an existing Log Analytics Workspace that lives in another subscription, provide its identifiers via `law_cross_subscription_details`:
```hcl
  law_cross_subscription_details = {
    id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-central"
    workspace_id = "00000000-0000-0000-0000-000000000000"
    shared_key   = "redacted-primary-shared-key"
  }
```
When you supply `law_cross_subscription_details`, omit both `law_name` and `law_resource_group_name`.

### IPAM Integration (Custom Address Prefixes)

If your organization uses IPAM (IP Address Management) to assign subnet ranges but you want the module to still manage the VNet, subnets, NSGs, DNS zones, and Private Endpoints, use the address prefix override variables:

```hcl
module "scepman" {
  source = "scepman/scepman/azurerm"

  # Use IPAM-assigned address prefixes instead of auto-calculated ranges
  vnet_address_space                = ["10.100.4.0/24"]
  subnet_appservices_address_prefix = "10.100.4.0/26"
  subnet_endpoints_address_prefix   = "10.100.4.64/26"

  # ... other required inputs
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.location
  storage_account_name            = var.storage_account_name
  key_vault_name                  = var.key_vault_name
  law_name                        = var.law_name
  service_plan_name               = var.service_plan_name
  app_service_name_primary        = var.app_service_name_primary
  app_service_name_certificate_master = var.app_service_name_certificate_master
  manage_entra_apps               = true
}
```

When `subnet_appservices_address_prefix` or `subnet_endpoints_address_prefix` are omitted (default), prefixes are auto-calculated from `vnet_address_space` using `cidrsubnet()`.

> **ℹ️ Subnet address validation**
>
> Custom address prefixes are validated for correct CIDR format at plan time. Containment within the VNet address space and non-overlap between subnets are enforced by the Azure API at apply time — if your prefixes fall outside `vnet_address_space` or overlap each other, Azure will return a clear error during resource creation.

> **⚠️ Changing VNet address space on existing deployments**
>
> Modifying `vnet_address_space` or custom subnet prefixes on an already-deployed environment will fail if Private Endpoints are attached to the existing subnets. Azure does not allow resizing a VNet/subnet with active Private Endpoint connections. To change address ranges on a live deployment, you must first delete (or move) the Private Endpoints, resize the network, then recreate the endpoints. Consider using BYOS mode for environments where networking is managed by a separate lifecycle.

### Bring Your Own Subnet (BYOS)

For enterprise environments with centrally managed networking (e.g., using [Azure Verified Module for Virtual Networks](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork)), you can pass existing subnet IDs instead of letting the module create its own networking resources.

Set `create_networking = false` and provide `existing_subnet_appservices_id`. The explicit boolean toggle ensures plan-time determinism — subnet IDs may be unknown until apply (e.g., when the networking module runs in the same plan) without causing Terraform `count` errors. A `check` block enforces at apply time that `existing_subnet_appservices_id` is provided and is a valid Azure subnet resource ID.

When `create_networking` is `false`, the module skips creation of: VNet, subnets, NSGs, Private DNS zones, Private DNS zone links, and Private Endpoints. You are responsible for managing these externally, including:
- Subnet delegation (`Microsoft.Web/serverFarms`) on the App Services subnet
- Private Endpoints for Key Vault and Storage Account in the endpoints subnet
- Private DNS zone configuration for `privatelink.vaultcore.azure.net` and `privatelink.table.core.windows.net`
- NSG rules as needed

> **⚠️ Migrating an existing deployment to BYOS**
>
> If you switch an existing deployment from module-managed networking to BYOS, Terraform will plan to **destroy** the previously module-managed networking resources (VNet, NSGs, Private DNS zones, Private Endpoints). To avoid accidental outages:
>
> 1. Create or identify the replacement VNet/subnets/NSGs/Private DNS zones/Private Endpoints that will be managed outside this module.
> 2. Verify the replacement networking is fully configured and connected to the workload.
> 3. Run `terraform state list` to identify the exact resource addresses in your deployment before removing anything from state.
> 4. Note that addresses may differ depending on your upgrade path: for example, the VNet may appear as `module.scepman.azurerm_virtual_network.vnet-scepman` or `module.scepman.azurerm_virtual_network.vnet-scepman[0]`.
> 5. Remove only the module-managed networking resources you intend to manage externally using the exact addresses returned by `terraform state list`, then set the BYOS variables and run `terraform plan` to confirm no destruction is proposed.

```hcl
module "network" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"
  # ... creates vnet/subnets using IPAM or central networking team
}

module "scepman" {
  source = "scepman/scepman/azurerm"

  create_networking              = false
  existing_subnet_appservices_id = module.network.subnets["snet-scepman-appservices"].resource_id

  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.location
  storage_account_name            = var.storage_account_name
  key_vault_name                  = var.key_vault_name
  law_name                        = var.law_name
  service_plan_name               = var.service_plan_name
  app_service_name_primary        = var.app_service_name_primary
  app_service_name_certificate_master = var.app_service_name_certificate_master
  manage_entra_apps               = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_app_service_application_logs_file_system_level"></a> [app\_service\_application\_logs\_file\_system\_level](#input\_app\_service\_application\_logs\_file\_system\_level) | Application Log level for file\_system | `string` | `"Error"` | no |
| <a name="input_app_service_logs_detailed_error_messages"></a> [app\_service\_logs\_detailed\_error\_messages](#input\_app\_service\_logs\_detailed\_error\_messages) | Detailed Error messages of the app service | `bool` | `true` | no |
| <a name="input_app_service_logs_failed_request_tracing"></a> [app\_service\_logs\_failed\_request\_tracing](#input\_app\_service\_logs\_failed\_request\_tracing) | Trace failed requests | `bool` | `false` | no |
| <a name="input_app_service_minimum_tls_version_certificate_master"></a> [app\_service\_minimum\_tls\_version\_certificate\_master](#input\_app\_service\_minimum\_tls\_version\_certificate\_master) | Minimum Inbound TLS Version for Certificate Master App Service | `string` | `"1.3"` | no |
| <a name="input_app_service_minimum_tls_version_scepman"></a> [app\_service\_minimum\_tls\_version\_scepman](#input\_app\_service\_minimum\_tls\_version\_scepman) | Minimum Inbound TLS Version for SCEPman core App Service | `string` | `"1.2"` | no |
| <a name="input_app_service_name_certificate_master"></a> [app\_service\_name\_certificate\_master](#input\_app\_service\_name\_certificate\_master) | Name of the certificate master app service | `string` | n/a | yes |
| <a name="input_app_service_name_primary"></a> [app\_service\_name\_primary](#input\_app\_service\_name\_primary) | Name of the primary app service | `string` | n/a | yes |
| <a name="input_app_service_retention_in_days"></a> [app\_service\_retention\_in\_days](#input\_app\_service\_retention\_in\_days) | How many days http\_logs should be kept | `number` | `90` | no |
| <a name="input_app_service_retention_in_mb"></a> [app\_service\_retention\_in\_mb](#input\_app\_service\_retention\_in\_mb) | Max file size of http\_logs | `number` | `35` | no |
| <a name="input_app_settings_certificate_master"></a> [app\_settings\_certificate\_master](#input\_app\_settings\_certificate\_master) | A mapping of additional app settings to assign to the certificate master app service. User-supplied values take precedence over module-computed defaults (last-writer-wins). Avoid overriding module-managed keys such as AppConfig:AzureStorage:TableStorageEndpoint unless intentional; when manage\_entra\_apps = true, also avoid AppConfig:AuthConfig:ApplicationId. Override AppConfig:SCEPman:URL when using a custom domain for the primary app service. Both ":" and "\_\_" key separators are accepted and normalised internally. | `map(string)` | `{}` | no |
| <a name="input_app_settings_primary"></a> [app\_settings\_primary](#input\_app\_settings\_primary) | A mapping of additional app settings to assign to the primary app service. User-supplied values take precedence over module-computed defaults (last-writer-wins). Avoid overriding module-managed keys such as AppConfig:KeyVaultConfig:KeyVaultURL, AppConfig:CertificateStorage:TableStorageEndpoint, and AppConfig:BaseUrl unless intentional; when manage\_entra\_apps = true, also avoid AppConfig:AuthConfig:ApplicationId. Both ":" and "\_\_" key separators are accepted and normalised internally. | `map(string)` | `{}` | no |
| <a name="input_artifacts_url_certificate_master"></a> [artifacts\_url\_certificate\_master](#input\_artifacts\_url\_certificate\_master) | URL of the artifacts for SCEPman Certificate Master | `string` | `"https://raw.githubusercontent.com/scepman/install/master/dist-certmaster/CertMaster-Artifacts.zip"` | no |
| <a name="input_artifacts_url_primary"></a> [artifacts\_url\_primary](#input\_artifacts\_url\_primary) | URL of the artifacts for SCEPman | `string` | `"https://raw.githubusercontent.com/scepman/install/master/dist/Artifacts.zip"` | no |
| <a name="input_certificate_master_uami_ids"></a> [certificate\_master\_uami\_ids](#input\_certificate\_master\_uami\_ids) | Set of user assigned managed identity resource IDs to assign to the SCEPman Certificate Master app service. The certificate master app service will always have a system assigned managed identity. This setting therefore is optional and for advanced use cases where additional user assigned managed identities need to be assigned to the app service. For most use cases, this can be left empty. | `set(string)` | `[]` | no |
| <a name="input_create_networking"></a> [create\_networking](#input\_create\_networking) | Whether the module creates networking resources (VNet, subnets, NSGs, DNS zones, Private Endpoints). Set to false for BYOS mode — provide existing\_subnet\_appservices\_id and manage networking externally. | `bool` | `true` | no |
| <a name="input_enable_application_insights"></a> [enable\_application\_insights](#input\_enable\_application\_insights) | Should Terraform create and connect Application Insights for the App services? NOTE: This will prevent Terraform from beeing able to destroy the ressource group! | `bool` | `false` | no |
| <a name="input_existing_subnet_appservices_id"></a> [existing\_subnet\_appservices\_id](#input\_existing\_subnet\_appservices\_id) | Resource ID of an existing subnet delegated to Microsoft.Web/serverFarms for App Service VNet integration. Required when create\_networking is false; presence and format are validated at apply time via a check block to support computed values from other modules in the same plan. | `string` | `null` | no |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Name of the key vault | `string` | n/a | yes |
| <a name="input_key_vault_use_rbac"></a> [key\_vault\_use\_rbac](#input\_key\_vault\_use\_rbac) | Use RBAC for the key vault or the older access policies | `bool` | `true` | no |
| <a name="input_law_cross_subscription_details"></a> [law\_cross\_subscription\_details](#input\_law\_cross\_subscription\_details) | Used to reference an existing Log Analytics Workspace located in another subscription. Use this instead of law\_name and law\_resource\_group\_name. | <pre>object({<br/>    id           = string<br/>    workspace_id = string<br/>    shared_key   = string<br/>  })</pre> | `null` | no |
| <a name="input_law_name"></a> [law\_name](#input\_law\_name) | Name for the Log Analytics Workspace | `string` | `null` | no |
| <a name="input_law_resource_group_name"></a> [law\_resource\_group\_name](#input\_law\_resource\_group\_name) | Resource Group of existing Log Analytics Workspace | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure Region where the resources should be created | `string` | n/a | yes |
| <a name="input_manage_entra_apps"></a> [manage\_entra\_apps](#input\_manage\_entra\_apps) | Whether to manage the Entra app registrations for SCEPman and Certificate Master within this module. If set to true, the user executing this must have Global Administrator privileges in the tenant/the service principal must have Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All permissions. For legacy installations, which were created before this setting existed, only set to true if you wish to migrate to the new model. For new installations, it is recommended to set this to true. | `bool` | `false` | no |
| <a name="input_nsg_appservices_name"></a> [nsg\_appservices\_name](#input\_nsg\_appservices\_name) | Name of the Network Security Group for the app services subnet. Ignored when create\_networking is false. | `string` | `"nsg-scepman-appservices"` | no |
| <a name="input_nsg_endpoints_name"></a> [nsg\_endpoints\_name](#input\_nsg\_endpoints\_name) | Name of the Network Security Group for the endpoints subnet. Ignored when create\_networking is false. | `string` | `"nsg-scepman-endpoints"` | no |
| <a name="input_organization_name"></a> [organization\_name](#input\_organization\_name) | Organization name (O=<my-org>) | `string` | `"my-org"` | no |
| <a name="input_primary_uami_ids"></a> [primary\_uami\_ids](#input\_primary\_uami\_ids) | Set of user assigned managed identity resource IDs to assign to the SCEPman primary app service. The primary app service will always have a system assigned managed identity. This setting therefore is optional and for advanced use cases where additional user assigned managed identities need to be assigned to the app service. For most use cases, this can be left empty. | `set(string)` | `[]` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_service_plan_name"></a> [service\_plan\_name](#input\_service\_plan\_name) | Name of the service plan | `string` | n/a | yes |
| <a name="input_service_plan_os_type"></a> [service\_plan\_os\_type](#input\_service\_plan\_os\_type) | The type of operating system to use for the app service plan. Possible values are 'Windows' or 'Linux'. | `string` | `"Windows"` | no |
| <a name="input_service_plan_resource_id"></a> [service\_plan\_resource\_id](#input\_service\_plan\_resource\_id) | Resource ID of the service plan | `string` | `null` | no |
| <a name="input_service_plan_sku"></a> [service\_plan\_sku](#input\_service\_plan\_sku) | SKU for App Service Plan | `string` | `"S1"` | no |
| <a name="input_storage_account_allow_nested_items_to_be_public"></a> [storage\_account\_allow\_nested\_items\_to\_be\_public](#input\_storage\_account\_allow\_nested\_items\_to\_be\_public) | Allow nested items (containers/directories) to inherit public access. | `bool` | `false` | no |
| <a name="input_storage_account_blob_soft_delete_retention_days"></a> [storage\_account\_blob\_soft\_delete\_retention\_days](#input\_storage\_account\_blob\_soft\_delete\_retention\_days) | Retention in days for blob soft delete. Set to 0 to keep soft delete disabled. | `number` | `7` | no |
| <a name="input_storage_account_container_soft_delete_retention_days"></a> [storage\_account\_container\_soft\_delete\_retention\_days](#input\_storage\_account\_container\_soft\_delete\_retention\_days) | Retention in days for container soft delete. Set to 0 to keep soft delete disabled. | `number` | `7` | no |
| <a name="input_storage_account_managed_identity_enabled"></a> [storage\_account\_managed\_identity\_enabled](#input\_storage\_account\_managed\_identity\_enabled) | Assign a system managed identity to the storage account to support Customer Managed Keys. | `bool` | `false` | no |
| <a name="input_storage_account_min_tls_version"></a> [storage\_account\_min\_tls\_version](#input\_storage\_account\_min\_tls\_version) | Minimum TLS version for the storage account endpoint. | `string` | `"TLS1_2"` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Name of the storage account | `string` | n/a | yes |
| <a name="input_storage_account_public_network_access_enabled"></a> [storage\_account\_public\_network\_access\_enabled](#input\_storage\_account\_public\_network\_access\_enabled) | Allow public network access to the storage account. Default disables external access to rely on private endpoints. | `bool` | `false` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | Storage account replication type. Valid options are LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS. | `string` | `"LRS"` | no |
| <a name="input_storage_account_sas_expiration_period"></a> [storage\_account\_sas\_expiration\_period](#input\_storage\_account\_sas\_expiration\_period) | Default expiration period applied to user delegation and service SAS tokens in d.hh:mm:ss format. | `string` | `"1.00:00:00"` | no |
| <a name="input_storage_account_shared_access_key_enabled"></a> [storage\_account\_shared\_access\_key\_enabled](#input\_storage\_account\_shared\_access\_key\_enabled) | Enable shared access key authentication for the storage account. Default is false to enforce more secure authentication methods. | `bool` | `false` | no |
| <a name="input_storage_account_trusted_services_enabled"></a> [storage\_account\_trusted\_services\_enabled](#input\_storage\_account\_trusted\_services\_enabled) | Enable trusted Microsoft services to bypass storage account network rules. | `bool` | `false` | no |
| <a name="input_subnet_appservices_address_prefix"></a> [subnet\_appservices\_address\_prefix](#input\_subnet\_appservices\_address\_prefix) | CIDR address prefix for the App Services subnet (e.g., from IPAM). When null, the prefix is auto-calculated from vnet\_address\_space using cidrsubnet(). Ignored when create\_networking is false. Note: Azure validates at apply time that the prefix is within the VNet address space and does not overlap other subnets. | `string` | `null` | no |
| <a name="input_subnet_appservices_name"></a> [subnet\_appservices\_name](#input\_subnet\_appservices\_name) | Name of the subnet created for integrating the App Services. Ignored when create\_networking is false. | `string` | `"snet-scepman-appservices"` | no |
| <a name="input_subnet_endpoints_address_prefix"></a> [subnet\_endpoints\_address\_prefix](#input\_subnet\_endpoints\_address\_prefix) | CIDR address prefix for the Private Endpoints subnet (e.g., from IPAM). When null, the prefix is auto-calculated from vnet\_address\_space using cidrsubnet(). Ignored when create\_networking is false. Note: Azure validates at apply time that the prefix is within the VNet address space and does not overlap other subnets. | `string` | `null` | no |
| <a name="input_subnet_endpoints_name"></a> [subnet\_endpoints\_name](#input\_subnet\_endpoints\_name) | Name of the subnet created for the other endpoints. Ignored when create\_networking is false. | `string` | `"snet-scepman-endpoints"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | Address-Space of the VNET. Ignored when create\_networking is false. | `list(any)` | <pre>[<br/>  "10.158.200.0/24"<br/>]</pre> | no |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name of the VNET created for internal communication. Ignored when create\_networking is false. | `string` | `"vnet-scepman"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_app_services"></a> [app\_services](#output\_app\_services) | Information about the deployed App Services for SCEPman |
| <a name="output_certmaster_application"></a> [certmaster\_application](#output\_certmaster\_application) | Information about the Application and Service Principal for the SCEPman Certificate Master |
| <a name="output_certmaster_mi_principal_id"></a> [certmaster\_mi\_principal\_id](#output\_certmaster\_mi\_principal\_id) | principal\_id of the system assigned managed identity of the SCEPman certificate master |
| <a name="output_primary_mi_principal_id"></a> [primary\_mi\_principal\_id](#output\_primary\_mi\_principal\_id) | principal\_id of the system assigned managed identity of the SCEPman primary app |
| <a name="output_scepman_application"></a> [scepman\_application](#output\_scepman\_application) | Information about the Application and Service Principal for the SCEPman API |
| <a name="output_scepman_certificate_master_url"></a> [scepman\_certificate\_master\_url](#output\_scepman\_certificate\_master\_url) | SCEPman Certificate Master Url |
| <a name="output_scepman_url"></a> [scepman\_url](#output\_scepman\_url) | SCEPman Url |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | ID of the storage account used by the deployment. |
| <a name="output_storage_account_identity_principal_id"></a> [storage\_account\_identity\_principal\_id](#output\_storage\_account\_identity\_principal\_id) | Principal ID of the storage account system-assigned managed identity when enabled. |
| <a name="output_storage_account_identity_tenant_id"></a> [storage\_account\_identity\_tenant\_id](#output\_storage\_account\_identity\_tenant\_id) | Tenant ID of the storage account system-assigned managed identity when enabled. |
<!-- END_TF_DOCS -->
