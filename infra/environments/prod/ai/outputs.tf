output "resource_group_name" {
  description = "Resource group containing production AI infrastructure."
  value       = azurerm_resource_group.ai.name
}

output "cognitive_account_id" {
  description = "Resource ID of the Foundry account. Reference this from other components to grant a caller's managed identity a role such as Cognitive Services User."
  value       = azurerm_cognitive_account.foundry.id
}

output "cognitive_account_name" {
  description = "Name of the Foundry account."
  value       = azurerm_cognitive_account.foundry.name
}

output "cognitive_account_endpoint" {
  description = "Base endpoint URL for calling the Foundry account."
  value       = azurerm_cognitive_account.foundry.endpoint
}

output "project_name" {
  description = "Name of the Foundry project."
  value       = azurerm_cognitive_account_project.endpoint.name
}

output "deployment_name" {
  description = "Name of the model deployment, used as the deployment/model identifier in API calls."
  value       = azapi_resource.llm.name
}

output "key_vault_name" {
  description = "Key Vault provisioned for this component's secrets. Currently empty; see the resource comment in main.tf for what's still needed before it holds the API key."
  value       = azurerm_key_vault.ai.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault provisioned for this component's secrets."
  value       = azurerm_key_vault.ai.vault_uri
}
