# SCEPman - Certificates Simplified

[SCEPman Docs](https://docs.scepman.com)

SCEPman is a slim and resource-friendly solution to issue and validate certificates using SCEP.
It is an Azure Web App providing the SCEP protocol and works directly with the Microsoft Graph and Intune API. SCEPman uses an Azure Key Vault based Root CA and certificate creation. No other component is involved, neither a database nor any other stateful storage except the Azure Key Vault itself. That said, SCEPman will not need any backup procedures or other operation level tasks. Only an Azure subscription is necessary to deploy it.

## Prerequisites

- Access to an **Azure subscription** (or Resource Group) with `Owner` RBAC Role assigned to Pricipal used for deployment
- Terraform environemnt - local, GitHub Codespaces or Dev Containers

#### Local Environment:

- Setup your **environment** using the following guide [Getting Started](https://learn.microsoft.com/en-us/azure/developer/terraform/quickstart-configure)

#### GitHub Codespaces

- Repository contains GitHub [Codespaces](https://github.com/features/codespaces) dev container definitions

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&repo=glueckkanja-gab%2Fterraform-azurerm-scepman)

#### Dev Containers

Visit [containers.dev](https://containers.dev) for more information

## Terraform State

- You can use local Terraform state for demo purposes
- We recommend to [Store Terraform state in Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli) for your Production environment
<!-- BEGIN_TF_DOCS -->


## Examples

### Community

For more informations how to deploy folowing example, see [README](examples/community/README.md)

```hcl
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
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_service_name_certificate_master"></a> [app\_service\_name\_certificate\_master](#input\_app\_service\_name\_certificate\_master) | Name of the certificate master app service | `string` | n/a | yes |
| <a name="input_app_service_name_primary"></a> [app\_service\_name\_primary](#input\_app\_service\_name\_primary) | Name of the primary app service | `string` | n/a | yes |
| <a name="input_app_settings_certificate_master"></a> [app\_settings\_certificate\_master](#input\_app\_settings\_certificate\_master) | A mapping of app settings to assign to the certificate master app service | `map(string)` | `{}` | no |
| <a name="input_app_settings_primary"></a> [app\_settings\_primary](#input\_app\_settings\_primary) | A mapping of app settings to assign to the primary app service | `map(string)` | `{}` | no |
| <a name="input_artifacts_repository_url"></a> [artifacts\_repository\_url](#input\_artifacts\_repository\_url) | URL of the repository containing the artifacts | `string` | `"https://raw.githubusercontent.com/scepman/install/master"` | no |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Name of the key vault | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure Region where the resources should be created | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_service_plan_name"></a> [service\_plan\_name](#input\_service\_plan\_name) | Name of the service plan | `string` | n/a | yes |
| <a name="input_service_plan_resource_id"></a> [service\_plan\_resource\_id](#input\_service\_plan\_resource\_id) | Resource ID of the service plan | `string` | `null` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Name of the storage account | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_scepman_certificate_master_url"></a> [scepman\_certificate\_master\_url](#output\_scepman\_certificate\_master\_url) | SCEPman Certificate Master Url |
| <a name="output_scepman_url"></a> [scepman\_url](#output\_scepman\_url) | SCEPman Url |
<!-- END_TF_DOCS -->