location             = "westeurope"
resource_group_name  = "rg-scepman-dev-002"
storage_account_name = "stscepmandev002"
key_vault_name       = "kv-scepman-prod-001"

service_plan_name                   = "plan-scepman-prod-002"
app_service_name_primary            = "app-scepman-dev-002"
app_service_name_certificate_master = "app-scepmancm-dev-002"

tags = {}

app_settings_primary = {
  "AppConfig:LicenseKey"                                   = "trial"
  "AppConfig:KeyVaultConfig:RootCertificateConfig:KeyType" = "RSA"
}
