variable "name" {
  type = string
}

variable "target_resource_id" {
  description = "ID de la ressource Azure à diagnostiquer (Firewall, Bastion, NSG...)"
  type        = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "log_categories" {
  description = "Catégories de logs à activer (dépend du type de ressource - voir `az monitor diagnostic-settings categories list`)"
  type        = list(string)
  default     = []
}

variable "metric_categories" {
  description = "Catégories de métriques à activer"
  type        = list(string)
  default     = ["AllMetrics"]
}
