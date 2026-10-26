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

## Network Access Restrictions (New Feature)

### What Changed

Two new optional variables have been added to support configurable network access restrictions
for the SCEPman primary and Certificate Master App Services:

- `network_access_restrictions_primary`
- `network_access_restrictions_certificate_master`

### Impact on Existing Deployments

**None.** Both variables default to `null`, which means:

- No `ip_restriction` or `scm_ip_restriction` blocks are rendered
- `public_network_access_enabled` is not set (provider default applies)
- Existing deployments will see **zero diff** on `terraform plan`
- No resource recreation is triggered

### Migration Steps

1. **Upgrade the module version** — no code changes required for existing behavior.
2. **Optionally configure restrictions** — add the new variables to your module call when ready.

### Example: Adding Restrictions to an Existing Deployment

Before (no restrictions):
```hcl
module "scepman" {
  source = "scepman/scepman/azurerm"
  # ... existing configuration ...
}
```

After (with deny-by-default):
```hcl
module "scepman" {
  source = "scepman/scepman/azurerm"
  # ... existing configuration ...

  network_access_restrictions_primary = {
    ip_restriction_default_action     = "Deny"
    scm_ip_restriction_default_action = "Deny"
    ip_restrictions = [
      {
        name       = "allow-corp"
        priority   = 100
        action     = "Allow"
        ip_address = "10.0.0.0/8"
      }
    ]
  }
}
```

### Notes

- Adding restrictions will modify the App Service `site_config` in-place (no recreation).
- Setting `public_network_access_enabled = false` will immediately block all public traffic.
  Ensure private endpoints or VNet integration is configured before disabling public access.
- Restricting the **primary** App Service can break **Certificate Master** communication, because
  Certificate Master reaches SCEPman via the primary's public hostname (`local.default_hostname_primary`,
  used in `AppConfig:SCEPman:URL`).
- If you set `public_network_access_enabled = false` on the primary, or configure a deny-by-default
  `ip_restrictions` policy, make sure the Certificate Master's egress is still allowed to reach the
  primary. By default, Certificate Master uses the standard outbound Azure IPs, not the integrated
  subnet, unless `vnet_route_all_enabled` / `WEBSITE_VNET_ROUTE_ALL` is enabled.
- When locking down the primary, allow Certificate Master's egress either by routing all traffic
  through the integrated VNet subnet with route-all enabled, or by adding an explicit allow rule for
  the actual outbound source that reaches the primary.
- IP restriction rules are evaluated by priority (lowest number = highest priority).
- Use `service_tag` for Azure service-level access (e.g., `AzureDevOps`, `AzureFrontDoor.Backend`).
