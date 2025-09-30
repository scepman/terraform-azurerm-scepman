# SCEPman - Advanced deployment

SCEPman deployment with sophisticated configuration using local state

## Using this example with Terraform CLI

### Variables

Edit the variables in the example `terraform.tfvars`.

Note: The following Azure Resource names must be globally unique:

- `storage_account_name`
- `key_vault_name`
- `app_service_name_primary`
- `app_service_name_certificate_master`

If you want to deploy the Community Edition, leave `AppConfig:LicenseKey` in `app_settings_primary` as *trial*. If you want to deploy the Enterprise Edition, use your valid license key.

> **Azure AD authentication required**: Shared keys are disabled by default. Set `storage_use_azuread = true` (or export `ARM_STORAGE_USE_AZUREAD=true`) in your provider configuration and assign the deploying identity the `Storage Queue Data Contributor` and `Storage Table Data Contributor` roles on the storage account.

### Storage hardening options

The module now disables storage account public network access and shared key authentication by default. You can override the behavior through the following optional variables when needed:

- `storage_account_public_network_access_enabled`
- `storage_account_trusted_services_enabled`
- `storage_account_min_tls_version`
- `storage_account_sas_expiration_period`
- `storage_account_blob_soft_delete_retention_days`
- `storage_account_container_soft_delete_retention_days`
- `storage_account_managed_identity_enabled`

### Deploy Configuration

```hcl
terraform init
terraform plan
terraform apply
```

### Post-Deployment Steps

Visit the homepage of your SCEPman App Service and follow the instructions for running the CMDlet `Complete-SCEPmanDeployment` of the [SCEPman PowerShell module](https://www.powershellgallery.com/packages/SCEPman/). This configures the [Managed Identities](https://docs.scepman.com/scepman-deployment/permissions/post-installation-config) of your App Services.

### Clean up resources

```hcl
terraform destroy
```