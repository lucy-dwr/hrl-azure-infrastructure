variable "subscription_id" {
  description = "Azure subscription ID where production app resources will be deployed."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid Azure subscription UUID."
  }
}

variable "location" {
  description = "Azure region for production app resources."
  type        = string
  default     = "westus3"
}

variable "static_web_app_location" {
  description = "Azure region for the Static Web App. Azure Static Web Apps is not available in every Azure region."
  type        = string
  default     = "westus2"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"

  validation {
    condition     = var.environment == "prod"
    error_message = "This root is for the prod environment only."
  }
}

variable "static_web_app_sku_tier" {
  description = "SKU tier for the production restoration map Static Web App."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_sku_tier)
    error_message = "Static Web App SKU tier must be Free or Standard."
  }
}

variable "preview_environments_enabled" {
  description = "Whether Azure Static Web Apps preview environments are enabled."
  type        = bool
  default     = true
}
