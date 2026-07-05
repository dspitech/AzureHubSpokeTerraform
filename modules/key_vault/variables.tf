variable "name" {
  description = "Nom du Key Vault (globalement unique sur Azure, 3-24 caractères alphanumériques)"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku_name" {
  description = "SKU du Key Vault (standard ou premium)"
  type        = string
  default     = "standard"
}

variable "secrets" {
  description = "Map nom_secret => valeur, stockée dans le Key Vault"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
