# SCEPman - Quickstart deployment

SCEPman deployment with reasonable defaults to get you started quickly

## Using this example with Terraform CLI

### Variables

Edit the location variable in our example `terraform.tfvars` or use the default `westeurope`

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