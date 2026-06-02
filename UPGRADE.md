# Upgrade Guide

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
