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

output "front_door_profile_name" {
  description = "Shared Azure Front Door profile name for HRL public applications."
  value       = azurerm_cdn_frontdoor_profile.apps.name
}

output "front_door_endpoint_name" {
  description = "Azure Front Door endpoint name."
  value       = azurerm_cdn_frontdoor_endpoint.apps.name
}

output "front_door_endpoint_hostname" {
  description = "Azure-generated Front Door hostname for pre-DNS routing tests."
  value       = azurerm_cdn_frontdoor_endpoint.apps.host_name
}

output "front_door_endpoint_url" {
  description = "Azure-generated Front Door URL for the restoration map route."
  value       = "https://${azurerm_cdn_frontdoor_endpoint.apps.host_name}/restoration-map/"
}

output "restoration_map_origin_hostname" {
  description = "Azure Static Web App hostname configured as the Front Door origin."
  value       = azurerm_static_web_app.restoration_map.default_host_name
}

output "restoration_map_public_url" {
  description = "Final public map URL when the DTS-managed custom domain is enabled."
  value       = "https://${var.custom_domain_hostname}/restoration-map/"
}

output "custom_domain_hostname" {
  description = "DTS-managed custom hostname, or null until custom-domain provisioning is enabled."
  value       = var.custom_domain_enabled ? azurerm_cdn_frontdoor_custom_domain.hrl[0].host_name : null
}

output "custom_domain_dns_validation_record_name" {
  description = "DNS TXT record name DTS must create when custom-domain provisioning is enabled."
  value       = var.custom_domain_enabled ? "_dnsauth.${var.custom_domain_hostname}" : null
}

output "custom_domain_validation_token" {
  description = "DNS TXT record value DTS must create when custom-domain provisioning is enabled."
  value       = var.custom_domain_enabled ? azurerm_cdn_frontdoor_custom_domain.hrl[0].validation_token : null
  sensitive   = true
}
