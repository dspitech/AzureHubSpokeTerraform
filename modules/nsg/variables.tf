variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "rules" {
  description = "Liste des règles NSG"
  type = list(object({
    name                        = string
    priority                    = number
    direction                   = string
    access                      = string
    protocol                    = string
    source_port_range           = string
    destination_port_range      = string
    source_address_prefix       = string
    destination_address_prefix  = string
  }))
  default = []
}

variable "subnet_id" {
  description = "ID du subnet à associer au NSG (null = pas d'association)"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
