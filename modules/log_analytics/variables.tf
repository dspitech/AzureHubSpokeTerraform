variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "retention_in_days" {
  description = "Durée de rétention des logs (jours). 30 jours = inclus dans le prix de l'ingestion."
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Plafond quotidien d'ingestion en Go, pour éviter une dérive de coût (recommandé sur Azure Students)"
  type        = number
  default     = 0.5
}

variable "tags" {
  type    = map(string)
  default = {}
}
