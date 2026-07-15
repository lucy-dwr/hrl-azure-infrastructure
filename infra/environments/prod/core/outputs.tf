output "resource_group_name" {
  description = "Resource group containing shared production foundation resources."
  value       = azurerm_resource_group.core.name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the shared production Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.core.id
}

output "log_analytics_workspace_name" {
  description = "Name of the shared production Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.core.name
}
