# Upgrade Guide

## Migrating to DCR-based log ingestion

SCEPman and Certificate Master now send their logs to Log Analytics through the [Logs Ingestion API](https://learn.microsoft.com/azure/azure-monitor/logs/logs-ingestion-api-overview) using a Data Collection Rule (DCR). The shared-key based HTTP Data Collector API is deprecated by Microsoft. Because `enable_dcr_log_ingestion` defaults to `true`, existing deployments switch to the new path on the next `terraform apply`.

### What changes

- New resources:
  - Data Collection Endpoint `dce_name` (default `dce-scepmanlogs`)
  - Data Collection Rule `dcr_name` (default `dcr-scepmanlogs`)
  - DCR-based custom table `SCEPman_CL` in the Log Analytics Workspace
  - `Monitoring Metrics Publisher` role assignments on the DCR for the SCEPman and Certificate Master managed identities
- App settings: `AppConfig:LoggingConfig:SharedKey` is removed, `AppConfig:LoggingConfig:DataCollectionEndpointUri` and `AppConfig:LoggingConfig:RuleId` are added.
- `law_cross_subscription_details.shared_key` is now optional and only required when `enable_dcr_log_ingestion = false`.

### Migration steps

Existing SCEPman installations that used the Data Collector API already have a **classic** `SCEPman_CL` table in the workspace. Terraform cannot create this table again, so `terraform apply` fails with `a resource with the ID ".../tables/SCEPman_CL" already exists`. Migrate and import the table before applying:

1. Check whether the table exists and which type it has:

    ```powershell
    az monitor log-analytics workspace table show --resource-group <law-resource-group> --workspace-name <law-name> --name SCEPman_CL --query schema.tableSubType -o tsv
    ```

    - Table not found: nothing to do, continue with step 4.
    - `Classic`: continue with step 2.
    - `DataCollectionRuleBased`: continue with step 3.

2. Migrate the classic table to a DCR-based table. This cannot be undone. Existing log data is kept.

    ```powershell
    az monitor log-analytics workspace table migrate --resource-group <law-resource-group> --workspace-name <law-name> --table-name SCEPman_CL
    ```

    Alternatively, `Complete-SCEPmanInstallation` from the [SCEPman PowerShell module](https://github.com/scepman/scepman-psmodule) migrates the table. Note that it also creates its own DCR (`dcr-scepmanlogs` in the workspace resource group) and changes the app settings outside of Terraform. Delete that DCR afterwards, or set `dcr_name` to a different name, so Terraform does not fail with a name conflict.

3. Import the table into the Terraform state by adding an `import` block to your root module (adjust `module.scepman` to the name of your module block):

    ```hcl
    import {
      to = module.scepman.azurerm_log_analytics_workspace_table_custom_log.scepman[0]
      id = "/subscriptions/<subscription-id>/resourceGroups/<law-resource-group>/providers/Microsoft.OperationalInsights/workspaces/<law-name>/tables/SCEPman_CL"
    }
    ```

4. Run `terraform plan` and review the changes, then run `terraform apply`. For imported tables, the plan adds the columns used by the DCR. Migrated classic tables still contain the suffixed columns of the Data Collector API (e.g. `Exception_s`, `RequestUrl_s`, `TenantIdentifier_g`); check whether the plan removes them before applying if you need to keep querying older entries.
5. Remove the `import` block once the apply succeeded.
6. New log entries are written to columns without type suffix (e.g. `Exception`, `RequestUrl`). Update saved queries, workbooks and alert rules accordingly. Queries that span old and new entries can combine both, e.g. `coalesce(Exception, Exception_s)`.

To postpone the migration, set `enable_dcr_log_ingestion = false`. This keeps the shared-key based logging and should only be used temporarily, as the Data Collector API is being retired.

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
