variable "name" {
  description = "Nom du VNet"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  description = "Plage(s) d'adresses du VNet"
  type        = list(string)
}

variable "subnets" {
  description = "Map des subnets à créer : { nom = { address_prefixes = [...] } }"
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
