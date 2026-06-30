output "resource_group_name" {
  description = "Resource group containing production data infrastructure."
  value       = azurerm_resource_group.data.name
}

output "storage_account_name" {
  description = "Production ADLS Gen2 storage account name."
  value       = azurerm_storage_account.data.name
}

output "container_names" {
  description = "Production data storage container names."
  value = concat(
    sort([for container in azurerm_storage_container.private : container.name]),
    [azurerm_storage_container.public_exports.name],
  )
}

output "public_exports_blob_endpoint" {
  description = "Blob endpoint for approved public export artifacts."
  value       = "${azurerm_storage_account.data.primary_blob_endpoint}${azurerm_storage_container.public_exports.name}/"
}

output "restoration_map_current_manifest_url" {
  description = "Expected URL for the current public restoration map data manifest."
  value       = "${azurerm_storage_account.data.primary_blob_endpoint}${azurerm_storage_container.public_exports.name}/restoration-map/restoration-projects/current/manifest.json"
}
