variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "ID du subnet AzureFirewallSubnet"
  type        = string
}

variable "sku_tier" {
  type    = string
  default = "Standard"
}

variable "network_rule_collections" {
  description = "Collections de règles réseau du Firewall"
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name                   = string
      source_addresses       = list(string)
      destination_addresses  = list(string)
      destination_ports      = list(string)
      protocols              = list(string)
    }))
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
