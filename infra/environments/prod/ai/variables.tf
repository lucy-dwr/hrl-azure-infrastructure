variable "subscription_id" {
  description = "Azure subscription ID where production AI resources will be deployed."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid Azure subscription UUID."
  }
}

variable "location" {
  description = "Azure region for production AI resources."
  type        = string
  default     = "westus3"
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

variable "model_name" {
  description = "Foundry model catalog name to deploy."
  type        = string
  default     = "claude-sonnet-5"
}

variable "model_version" {
  description = "Model version to deploy, as listed in the Foundry model catalog for this region."
  type        = string
  default     = "2"
}

variable "model_format" {
  description = "Model publisher format understood by azurerm_cognitive_deployment (e.g. Anthropic, OpenAI)."
  type        = string
  default     = "Anthropic"
}

variable "deployment_sku_name" {
  description = "SKU for the model deployment."
  type        = string
  default     = "GlobalStandard"
}

variable "deployment_capacity" {
  description = "Throughput capacity for the model deployment, in the model's billing units (check current quota with az cognitiveservices usage list before raising)."
  type        = number
  default     = 10
}

variable "model_provider_organization_name" {
  description = "Organization name reported to the model provider (e.g. Anthropic) for third-party model deployments. Required by the Azure API; not currently exposed by azurerm."
  type        = string
  default     = "Healthy Rivers and Landscapes"
}

variable "model_provider_industry" {
  description = "Industry classification reported to the model provider for third-party model deployments."
  type        = string
  default     = "government"
}

variable "model_provider_country_code" {
  description = "ISO country code reported to the model provider for third-party model deployments."
  type        = string
  default     = "US"
}
