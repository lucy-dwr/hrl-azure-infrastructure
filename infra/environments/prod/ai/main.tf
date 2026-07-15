data "azurerm_client_config" "current" {}

locals {
  project     = "hrl"
  workload    = "ai"
  application = "llm-endpoint"
  region_code = "wus3"

  resource_group_name    = "rg-${local.project}-${local.workload}-${var.environment}-${local.region_code}"
  cognitive_account_name = "cog-${local.project}-${local.workload}-${var.environment}-${random_string.suffix.result}"
  key_vault_name         = "kv-${local.project}-${local.workload}-${var.environment}-${random_string.suffix.result}"
  project_name           = "${local.project}-${local.workload}-${var.environment}"

  common_tags = {
    project     = "Healthy Rivers and Landscapes"
    environment = var.environment
    workload    = local.workload
    application = local.application
    owner       = "HRL Program"
    managed_by  = "terraform"
  }
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_resource_group" "ai" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# The Foundry resource. kind = "AIServices" plus project_management_enabled
# is what makes this a Foundry account rather than a single-service
# Cognitive Services account.
resource "azurerm_cognitive_account" "foundry" {
  name                = local.cognitive_account_name
  resource_group_name = azurerm_resource_group.ai.name
  location            = azurerm_resource_group.ai.location
  kind                = "AIServices"
  sku_name            = "S0"

  custom_subdomain_name         = local.cognitive_account_name
  project_management_enabled    = true
  public_network_access_enabled = true

  # Keep both auth paths open: API key for the app that needs one,
  # Entra ID/managed identity + RBAC for anything added later.
  local_auth_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_cognitive_account_project" "endpoint" {
  name                 = local.project_name
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = azurerm_resource_group.ai.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# azurerm_cognitive_deployment has no argument for modelProviderData, which
# the Azure API requires for third-party (e.g. Anthropic) model deployments.
# Provider gap: https://github.com/hashicorp/terraform-provider-azurerm/issues/31140
# Use azapi directly for this one resource until azurerm catches up.
resource "azapi_resource" "llm" {
  type                      = "Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview"
  name                      = var.model_name
  parent_id                 = azurerm_cognitive_account.foundry.id
  schema_validation_enabled = false

  body = {
    properties = {
      model = {
        format  = var.model_format
        name    = var.model_name
        version = var.model_version
      }
      modelProviderData = {
        organizationName = var.model_provider_organization_name
        industry         = var.model_provider_industry
        countryCode      = var.model_provider_country_code
      }
      versionUpgradeOption = "OnceNewDefaultVersionAvailable"
    }
    sku = {
      name     = var.deployment_sku_name
      capacity = var.deployment_capacity
    }
  }
}

# Dedicated to this component for now. Fold into prod/core's Key Vault
# once that component exists. Left empty for now: writing the account's
# API key into it needs either RBAC role-assignment rights (which this
# deployer doesn't have) or switching the vault to the access-policy
# model — deferred until that's decided.
resource "azurerm_key_vault" "ai" {
  name                          = local.key_vault_name
  resource_group_name           = azurerm_resource_group.ai.name
  location                      = azurerm_resource_group.ai.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = true

  tags = local.common_tags
}
