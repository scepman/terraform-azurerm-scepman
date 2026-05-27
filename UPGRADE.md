# Upgrade Guide

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
- **Certificate Master → Primary connectivity:** The Certificate Master communicates with the
  primary App Service via its public hostname. If you restrict or disable public access on the
  primary, ensure the Certificate Master's outbound traffic is allowed (e.g., by enabling
  `vnet_route_all_enabled` and adding the integrated subnet to the primary's allow list, or by
  using a private endpoint). Otherwise, Certificate Master requests to the primary will fail.
- IP restriction rules are evaluated by priority (lowest number = highest priority).
- Use `service_tag` for Azure service-level access (e.g., `AzureDevOps`, `AzureFrontDoor.Backend`).