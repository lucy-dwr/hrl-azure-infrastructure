output "resource_group_name" {
  description = "Resource group containing production app infrastructure."
  value       = azurerm_resource_group.apps.name
}

output "static_web_app_name" {
  description = "Production restoration map Static Web App name."
  value       = azurerm_static_web_app.restoration_map.name
}

output "static_web_app_location" {
  description = "Azure region for the production restoration map Static Web App."
  value       = azurerm_static_web_app.restoration_map.location
}

output "static_web_app_default_hostname" {
  description = "Default hostname for the production restoration map Static Web App."
  value       = azurerm_static_web_app.restoration_map.default_host_name
}
