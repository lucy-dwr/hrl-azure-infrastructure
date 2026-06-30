resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  project     = "hrl"
  workload    = "tfstate"
  region_code = "wus3"

  resource_group_name  = "rg-${local.project}-${local.workload}-${var.environment}-${local.region_code}"
  storage_account_name = "st${local.project}${local.workload}${var.environment}${random_string.suffix.result}"

  common_tags = {
    project     = "Healthy Rivers and Landscapes"
    workload    = "terraform-state"
    environment = var.environment
    owner       = "HRL Program"
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "tfstate" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "tfstate" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = local.common_tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
