variable "resource_group_name" {
  description = "Nom du groupe de ressources"
  type        = string
  default     = "RG-HUB-SPOKE-PROJECT"
}

variable "location" {
  description = "Région Azure de déploiement"
  type        = string
  default     = "norwayeast"
}

variable "admin_username" {
  description = "Identifiant administrateur des VMs"
  type        = string
  default     = "azure_admin"
}

variable "admin_password" {
  description = "Mot de passe administrateur des VMs (ne pas committer en clair - utiliser TF_VAR_admin_password ou un fichier tfvars ignoré par git)"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Taille des machines virtuelles"
  type        = string
  default     = "Standard_B2s"
}

variable "firewall_sku_tier" {
  description = "Tier du SKU Azure Firewall (Standard, Premium ou Basic)"
  type        = string
  default     = "Standard"
}

# --- Adressage réseau ---

variable "hub_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "hub_prod_subnet_prefix" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "hub_firewall_subnet_prefix" {
  type    = list(string)
  default = ["10.0.2.0/24"]
}

variable "hub_bastion_subnet_prefix" {
  type    = list(string)
  default = ["10.0.4.0/24"]
}

variable "spoke1_address_space" {
  type    = list(string)
  default = ["192.168.0.0/24"]
}

variable "spoke2_address_space" {
  type    = list(string)
  default = ["172.16.0.0/24"]
}

variable "tags" {
  description = "Tags communs appliqués à toutes les ressources"
  type        = map(string)
  default = {
    projet      = "AZ-PRO-HUB-SPOKE-NORWAY"
    environment = "lab"
    gere_par    = "terraform"
  }
}
