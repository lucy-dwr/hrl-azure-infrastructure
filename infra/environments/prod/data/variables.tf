variable "subscription_id" {
  description = "Azure subscription ID where production data resources will be deployed."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid Azure subscription UUID."
  }
}

variable "location" {
  description = "Azure region for production data resources."
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

variable "storage_account_replication_type" {
  description = "Replication type for the production data storage account."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Storage account replication type must be one of LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }
}

variable "public_exports_access_type" {
  description = "Anonymous access level for approved public export blobs. Use blob only if allowed by policy; use private if an API or proxy will serve public artifacts."
  type        = string
  default     = "blob"

  validation {
    condition     = contains(["private", "blob"], var.public_exports_access_type)
    error_message = "Public exports access type must be private or blob."
  }
}

variable "allowed_cors_origins" {
  description = "Allowed browser origins for reading public export blobs from the production map."
  type        = list(string)
  default     = []
}
