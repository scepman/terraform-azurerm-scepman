# Upgrade Guide

## Upgrading to AzureRM provider v5

This module now requires the `hashicorp/azurerm` provider `>= 5.9, < 6.0.0`. Support for AzureRM v4 has been dropped, because `azurerm_private_dns_zone_virtual_network_link` in v5 only accepts `private_dns_zone_id`, an argument that is not available in any v4 release.

1. Update the `azurerm` provider constraint in your root module, e.g. `version = ">= 5.9"`, and run `terraform init -upgrade`.
2. AzureRM v5 no longer registers Azure Resource Providers automatically (`resource_provider_registrations` now defaults to `none`). If the target subscription has not registered them yet, register the providers required by this module, for example:

    ```hcl
    provider "azurerm" {
      features {}
      resource_providers_to_register = [
        "Microsoft.Insights",
        "Microsoft.KeyVault",
        "Microsoft.Network",
        "Microsoft.OperationalInsights",
        "Microsoft.Storage",
        "Microsoft.Web",
      ]
    }
    ```

3. Run `terraform plan` and review the changes. The private DNS zone virtual network links (`dnszonelink-kv`, `dnszonelink-sts`) now reference their zone via `private_dns_zone_id`. AzureRM v5 derives this value from the existing resource ID, so these links should not be replaced.
4. The storage account now uses `public_network_access` (`Enabled`/`Disabled`) instead of the deprecated `public_network_access_enabled`. The module input `storage_account_public_network_access_enabled` is unchanged and is mapped to the new argument, so no change to the storage account is expected.
