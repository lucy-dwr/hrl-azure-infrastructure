terraform {
  required_version = ">= 1.13.0, < 2.0.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # azurerm_cognitive_account_project requires >= 4.55.0.
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }

    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}
