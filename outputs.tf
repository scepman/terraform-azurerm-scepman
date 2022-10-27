output "scepman_url" {
  value       = format("https://%s", azurerm_windows_web_app.app.default_hostname)
  description = "SCEPman Url"
}

output "scepman_certificate_master_url" {
  value       = format("https://%s", azurerm_windows_web_app.app_cm.default_hostname)
  description = "SCEPman Certificate Master Url"
}
