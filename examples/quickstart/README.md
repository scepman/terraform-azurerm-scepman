# SCEPman - Quickstart deployment

SCEPman deployment with reasonable defaults to get you started quickly

This example deploys the free Community Edition, but you can upgrade your existing SCEPman instance to an Enterprise Edition later by adding your [license key](https://docs.scepman.com/advanced-configuration/application-settings/basics#appconfig-licensekey).

Public network access to the storage account is disabled by default. If you need to expose it temporarily or enable Trusted Microsoft Services, set the corresponding variables when instantiating the module.

> **Azure AD authentication required**: Because shared keys are disabled, Terraform must talk to the storage account using Azure AD. Configure the provider with `storage_use_azuread = true` (or export `ARM_STORAGE_USE_AZUREAD=true`) and grant your deployment principal `Storage Queue Data Contributor` and `Storage Table Data Contributor` roles on the account.

## Using this example with Terraform CLI

### Variables

Edit the location variable in our example `terraform.tfvars` or use the default `westeurope`.

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