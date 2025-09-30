subscription_id = "00000000-0000-0000-0000-000000000000"

organization_name   = "my-org"
location            = "westeurope"
resource_group_name = "rg-scepman-dev-025"

storage_account_name                     = "stscepmandev025"
key_vault_name                           = "kv-scepman-prod-025"
law_name                                 = "law-scepman-prod-025"
storage_account_managed_identity_enabled = false

service_plan_os_type                = "Linux"
service_plan_name                   = "plan-scepman-prod-025"
service_plan_sku                    = "B2"
app_service_name_primary            = "app-scepman-dev-025"
app_service_name_certificate_master = "app-scepmancm-dev-025"


enable_application_insights = false

tags = {}

app_settings_primary = {
  "AppConfig:LicenseKey"                                   = "trial"
  "AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType" = "RSA"
}
