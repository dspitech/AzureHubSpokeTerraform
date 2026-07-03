variable "name" {
  description = "Nom du groupe de ressources"
  type        = string
}

variable "location" {
  description = "Région Azure de déploiement"
  type        = string
}

variable "tags" {
  description = "Tags appliqués au groupe de ressources"
  type        = map(string)
  default     = {}
}
