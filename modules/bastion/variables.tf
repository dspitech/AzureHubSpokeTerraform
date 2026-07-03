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
  description = "ID du subnet AzureBastionSubnet"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
