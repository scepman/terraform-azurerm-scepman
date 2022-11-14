location             = "westeurope"
resource_group_name  = "rg-scepman-dev-025"
storage_account_name = "stscepmandev025"
key_vault_name       = "kv-scepman-prod-025"

service_plan_name                   = "plan-scepman-prod-025"
app_service_name_primary            = "app-scepman-dev-025"
app_service_name_certificate_master = "app-scepmancm-dev-025"

tags = {}

app_settings_primary = {
  "AppConfig:LicenseKey"                                   = "trial"
  "AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType" = "RSA"
}
