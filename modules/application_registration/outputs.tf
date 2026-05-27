output "client_id" {
  description = "The Client ID for the application"
  value       = azuread_application_registration.this.client_id
}

output "disabled_by_microsoft" {
  description = "Whether Microsoft has disabled the registered application. If the application is disabled, this will be a string indicating the status/reason, e.g. DisabledDueToViolationOfServicesAgreement"
  value       = azuread_application_registration.this.disabled_by_microsoft
}

output "id" {
  description = "The Terraform resource ID for the application, for use when referencing this resource in your Terraform configuration."
  value       = azuread_application_registration.this.id
}

output "object_id" {
  description = "The object ID of the application within the tenant."
  value       = azuread_application_registration.this.object_id
}

output "publisher_domain" {
  description = "The verified publisher domain for the application."
  value       = azuread_application_registration.this.publisher_domain
}

output "app_role_ids" {
  description = "Map of app role values to their UUIDs"
  value       = { for k, v in azuread_application_app_role.this : k => v.role_id }
}
