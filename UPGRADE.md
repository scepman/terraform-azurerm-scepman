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

## Upgrading from v1.1.x

### App settings merge order correction

**Who is affected:** Anyone using `app_settings_primary` or `app_settings_certificate_master` with keys
that overlap module-managed settings.

Previously, user-supplied values in `app_settings_primary` and `app_settings_certificate_master` were
placed at an early position in the internal `merge()` chain, causing module-computed values to silently
overwrite any user-supplied key that happened to collide. This was a bug.

**The merge order has been corrected so that user-supplied values now take precedence (last-writer-wins).**

**Action required:** Review your `app_settings_primary` and `app_settings_certificate_master` inputs. If
any of the following module-managed keys appear in your configuration, confirm that overriding them is
intentional — under the old (broken) order they were silently discarded and had no effect:

**`app_settings_primary`:**

- `AppConfig:KeyVaultConfig:KeyVaultURL` — module sets this to the managed Key Vault URI
- `AppConfig:CertificateStorage:TableStorageEndpoint` — module sets this to the managed Storage Table endpoint
- `AppConfig:BaseUrl` — module sets this to the primary App Service default hostname
- `AppConfig:AuthConfig:TenantId`
- `AppConfig:LoggingConfig:WorkspaceId` / `AppConfig:LoggingConfig:SharedKey`
- When `manage_entra_apps = true`: `AppConfig:AuthConfig:ApplicationId`, `AppConfig:CertMaster:URL`,
  `AppConfig:AuthConfig:UseManagedIdentity`, `AppConfig:AuthConfig:ManagedIdentityEnabledForWebsiteHostname`

**`app_settings_certificate_master`:**

- `AppConfig:AzureStorage:TableStorageEndpoint` — module sets this to the managed Storage Table endpoint
- `AppConfig:AuthConfig:TenantId`
- `AppConfig:LoggingConfig:WorkspaceId` / `AppConfig:LoggingConfig:SharedKey`
- When `manage_entra_apps = true`: `AppConfig:AuthConfig:ApplicationId`, `AppConfig:AuthConfig:SCEPmanAPIScope`
- `AppConfig:SCEPman:URL` — module sets this to the primary App Service URL; safe to override for custom domains

If you do not pass any of these keys, no action is required — the fix only affects app settings that were
previously being silently discarded.
