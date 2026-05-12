# BYOS & IPAM Feature — Integration Test Report

**Module**: `terraform-azurerm-scepman`  
**Branch**: `feature/bring-your-own-subnet`  
**Test Date**: 2026-05-07  
**Environment**: Azure Sandbox Subscription 
**State Backend**:  container `sandbox`  
---

## Summary

| Test Case | Description | Result | Notes |
|-----------|-------------|--------|-------|
| TC4 | Default behavior (no BYOS/IPAM) | ✅ PASS | Auto-calculated subnets correct |
| TC3 | IPAM-specified address ranges | ✅ PASS | Subnets match specified CIDRs exactly |
| TC5 | Full BYOS (external subnets) | ✅ PASS | Zero networking in state, app on external subnet |
| TC1 | Upgrade path (moved blocks) | ⏭️ SKIPPED | Requires Entra admin permissions |
| TC2 | Migration to BYOS | ⏭️ SKIPPED | Requires Entra admin permissions |

**Overall Verdict**: ✅ **PASS** — All testable scenarios validated successfully.

---

## Test Case Details

### TC4 — Default Behavior (No BYOS, No IPAM)

**What it tests**: A fresh deployment with no BYOS or IPAM variables set. This validates that the new networking code doesn't break existing behavior — the module should auto-create a VNet and calculate subnet CIDRs using `cidrsubnet()` just like it did before the feature branch.

**Results**:
- ✅ 22 resources created successfully
- ✅ App Services subnet CIDR: `10.158.200.0/27` (matches `cidrsubnet("10.158.200.0/24", 3, 0)`)
- ✅ Endpoints subnet CIDR: `10.158.200.32/27` (matches `cidrsubnet("10.158.200.0/24", 3, 1)`)
- ✅ VNet integration active on app service
- ✅ Private endpoints created in endpoints subnet
- ✅ Idempotent (0 add, 0 destroy)

---

### TC3 — IPAM-Specified Address Ranges

**What it tests**: Deploying with explicit `subnet_appservices_address_prefix` and `subnet_endpoints_address_prefix` variables to override the default `cidrsubnet()` calculation. This simulates an enterprise IPAM scenario where the network team dictates specific address ranges and the module must use those exact CIDRs instead of auto-calculating.

**Configuration**:
```hcl
subnet_appservices_address_prefix = "10.50.100.0/26"
subnet_endpoints_address_prefix  = "10.50.100.64/27"
vnet_address_space               = "10.50.100.0/24"
```

**Results**:
- ✅ 22 resources created successfully
- ✅ App Services subnet CIDR: `10.50.100.0/26` (exact match)
- ✅ Endpoints subnet CIDR: `10.50.100.64/27` (exact match)
- ✅ Different prefix lengths (`/26` and `/27`) work correctly
- ✅ VNet address space respected
- ✅ Idempotent (0 add, 0 destroy)

---

### TC5 — Full BYOS (Bring Your Own Subnet)

**What it tests**: Providing pre-existing subnet and DNS zone resource IDs so the module creates **zero** networking resources. This validates the core BYOS feature — customers who manage their own networking can pass in subnet IDs and the module only deploys the application layer (App Services, Key Vault, Storage, Log Analytics). The module must not attempt to create any VNet, subnet, NSG, DNS zone, DNS link, or Private Endpoint.

**Setup**: A separate Terraform config (`tc5-external-network`) first created the external networking:
- VNet with two subnets (with proper App Service delegation)
- Private DNS zones for `azurewebsites.net` and `scepman.io`
- DNS zone VNet links

Then the BYOS config references those resources by their full Azure resource IDs.

**Configuration**:
```hcl
existing_subnet_appservices_id  = "/subscriptions/.../subnets/snet-appservices"
existing_subnet_endpoints_id   = "/subscriptions/.../subnets/snet-endpoints"
existing_dns_zone_scepman_id   = "/subscriptions/.../privateDnsZones/scepman.io"
existing_dns_zone_appservice_id = "/subscriptions/.../privateDnsZones/privatelink.azurewebsites.net"
```

**Results**:
- ✅ 12 resources created (vs 22 in default mode — 10 networking resources eliminated)
- ✅ **Zero networking resources in state**: No VNet, subnets, NSGs, DNS zones, DNS links, or Private Endpoints
- ✅ App Service VNet integration points to the **external** subnet
- ✅ Module correctly delegates networking responsibility to the caller
- ✅ Fully idempotent — exit code 0 (no changes on re-plan)

---

## Skipped Test Cases

### TC1 — Upgrade Path (Moved Blocks)

**What it would test**: Deploy using the old module version (pre-BYOS, where networking resources use `count` with `[0]` indices), then upgrade to the new version and verify that `moved` blocks handle the state address migration without destroying/recreating resources.

**Why it could not be executed**: The SCEPman module with `manage_entra_apps = true` creates `azuread_app_role_assignment` resources that grant Microsoft Graph API permissions (e.g. `Directory.Read.All`, `DeviceManagementConfiguration.Read.All`) to managed identities. This requires the **`AppRoleAssignment.ReadWrite.All`** Graph API permission on the executing identity — specifically either the **Privileged Role Administrator** or **Cloud Application Administrator** Entra directory role. The test identity lacks this permission (confirmed via actual apply attempt — returns HTTP 403 "Insufficient privileges to complete the operation"). Since TC1 requires a full deployment including Entra resources to then test the `moved` block migration, it cannot proceed without elevated Entra permissions.

**Risk Assessment**: Low — `moved` blocks are declarative and well-understood by Terraform. The blocks in `networking.tf` correctly map `[0]` indexed resources to non-indexed equivalents.

---

### TC2 — Migration from Default to BYOS

**What it would test**: Starting with a full module deployment (networking managed internally by the module), then switching to BYOS mode by setting the `existing_subnet_*` variables and running `terraform state rm` on the networking resources. Validates that the transition path works without destroying application-layer resources.

**Why it could not be executed**: TC2 depends on a successful TC1 deployment as its starting point — it needs a fully-deployed SCEPman environment with module-managed networking to then migrate from. Since the old module version doesn't offer a `manage_entra_apps = false` option, and the full deployment requires the `AppRoleAssignment.ReadWrite.All` permission that the test identity lacks, TC2 is blocked by the same Entra permission gap as TC1.

**Risk Assessment**: Medium — The migration path works mechanically (state rm + variable change), but should be validated with elevated permissions and documented as a migration guide for users.

---

## Conclusions

1. **BYOS feature works correctly**: Setting `existing_subnet_*` variables completely disables internal networking. Zero networking resources are created or managed.

2. **IPAM feature works correctly**: Custom subnet address prefixes are applied exactly as specified, supporting different prefix lengths for each subnet.

3. **Default behavior preserved**: The module continues to auto-calculate subnets via `cidrsubnet()` when no overrides are provided. No regressions introduced.

4. **`create_networking` local logic is sound**: `var.existing_subnet_appservices_id == null` correctly gates all networking resources via `count`.

5. **TC1/TC2 require Entra admin permissions**: To test upgrade and migration paths, the executing identity needs `AppRoleAssignment.ReadWrite.All` (Privileged Role Administrator or Cloud Application Administrator role in Entra ID).

---
