locals {
  project     = "hrl"
  workload    = "data"
  application = "restoration-map"
  region_code = "wus3"

  resource_group_name  = "rg-${local.project}-${local.workload}-${var.environment}-${local.region_code}"
  storage_account_name = "st${local.project}${local.workload}${var.environment}${random_string.storage_account_suffix.result}"

  private_container_names = [
    "raw-submissions",
    "standardized",
    "validation-reports",
    "schema-snapshots",
  ]

  common_tags = {
    project             = "Healthy Rivers and Landscapes"
    environment         = var.environment
    workload            = local.workload
    application         = local.application
    owner               = "HRL Science Program"
    managed_by          = "terraform"
    data_classification = "public-and-internal"
  }
}

resource "random_string" "storage_account_suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_resource_group" "data" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "data" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.data.name
  location                        = azurerm_resource_group.data.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_account_replication_type
  account_kind                    = "StorageV2"
  access_tier                     = "Hot"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = var.public_exports_access_type != "private"
  is_hns_enabled                  = true

  blob_properties {
    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }

    dynamic "cors_rule" {
      for_each = length(var.allowed_cors_origins) > 0 ? [1] : []

      content {
        allowed_origins = var.allowed_cors_origins
        allowed_methods = [
          "GET",
          "HEAD",
          "OPTIONS",
        ]
        allowed_headers = [
          "Accept",
          "Content-Type",
          "Range",
        ]
        exposed_headers = [
          "Accept-Ranges",
          "Cache-Control",
          "Content-Length",
          "Content-Range",
          "Content-Type",
          "ETag",
          "Last-Modified",
        ]
        max_age_in_seconds = 3600
      }
    }
  }

  tags = local.common_tags
}

resource "azurerm_storage_container" "private" {
  for_each = toset(local.private_container_names)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "public_exports" {
  name                  = "public-exports"
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = var.public_exports_access_type
}
