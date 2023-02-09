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