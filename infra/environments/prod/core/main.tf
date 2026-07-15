locals {
  project     = "hrl"
  workload    = "core"
  region_code = "wus3"

  resource_group_name          = "rg-${local.project}-${local.workload}-${var.environment}-${local.region_code}"
  log_analytics_workspace_name = "log-${local.project}-${local.workload}-${var.environment}-${local.region_code}"

  common_tags = {
    project     = "Healthy Rivers and Landscapes"
    environment = var.environment
    workload    = local.workload
    owner       = "HRL Program"
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "core" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_log_analytics_workspace" "core" {
  name                = local.log_analytics_workspace_name
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_in_days
  tags                = local.common_tags
}
