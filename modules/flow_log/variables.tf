variable "name" {
  type = string
}

variable "location" {
  type    = string
  default = null
}

variable "network_watcher_name" {
  type = string
}

variable "network_watcher_resource_group_name" {
  type = string
}

variable "network_security_group_id" {
  type = string
}

variable "storage_account_id" {
  type = string
}

variable "retention_days" {
  type    = number
  default = 30
}

variable "log_analytics_workspace_id" {
  description = "Resource ID du workspace pour Traffic Analytics. Laisser null pour désactiver (recommandé sur Azure Students)."
  type        = string
  default     = null
}

variable "log_analytics_workspace_guid" {
  description = "Workspace ID (GUID) - requis uniquement si log_analytics_workspace_id est renseigné"
  type        = string
  default     = null
}
