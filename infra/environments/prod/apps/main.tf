locals {
  project       = "hrl"
  workload      = "apps"
  application   = "restoration-map"
  region_code   = "wus3"
  app_name_slug = "restoration-map"

  resource_group_name      = "rg-${local.project}-${local.workload}-${var.environment}-${local.region_code}"
  static_web_app_name      = "stapp-${local.project}-${local.app_name_slug}-${var.environment}"
  front_door_profile_name  = "afd-${local.project}-${var.environment}"
  front_door_endpoint_name = "fde-${local.project}-${var.environment}"
  front_door_waf_name      = "waf-${local.project}-${var.environment}"

  common_tags = {
    project     = "Healthy Rivers and Landscapes"
    environment = var.environment
    workload    = local.workload
    application = local.application
    owner       = "HRL Program"
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "apps" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_static_web_app" "restoration_map" {
  name                = local.static_web_app_name
  resource_group_name = azurerm_resource_group.apps.name
  location            = var.static_web_app_location

  sku_tier                      = var.static_web_app_sku_tier
  sku_size                      = var.static_web_app_sku_tier
  preview_environments_enabled  = var.preview_environments_enabled
  public_network_access_enabled = true

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      repository_branch,
      repository_url,
    ]
  }
}
