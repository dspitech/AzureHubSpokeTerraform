variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_name" {
  description = "Nom du VNet local (côté source du peering)"
  type        = string
}

variable "remote_vnet_id" {
  description = "ID du VNet distant"
  type        = string
}

variable "allow_forwarded_traffic" {
  description = "Indispensable pour que le trafic routé via le Firewall passe entre les Spokes"
  type        = bool
  default     = true
}
