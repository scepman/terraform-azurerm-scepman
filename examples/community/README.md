# SCEPman - Community deployment

Trial SCEPman deployment using local state

## Using this example with Terraform CLI

### Variables

Edit variables in our example `terraform.tfvars`

Note: Following Azure Resource names must be globaly unique

- storage_account_name
- key_vault_name
- app_service_name_primary
- app_service_name_certificate_master

### Deploy Configuration

```hcl
terraform init
terraform plan
terraform apply
```

### Post-Deployment Steps

[Managed Identities](https://docs.scepman.com/scepman-deployment/permissions/post-installation-config)

### Clean up resources

```hcl
terraform destroy
```