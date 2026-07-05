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
  description = "Mot de passe administrateur des VMs. Utilisé uniquement si generate_admin_password = false. Sinon, ignoré : le mot de passe est généré automatiquement et stocké dans Key Vault."
  type        = string
  sensitive   = true
  default     = null
}

variable "generate_admin_password" {
  description = "Si true (recommandé), génère un mot de passe VM aléatoire (random_password) et le stocke dans Azure Key Vault au lieu de le passer en clair via une variable."
  type        = bool
  default     = true
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

# --- Observabilité (Log Analytics + Diagnostic Settings) ---

variable "log_retention_in_days" {
  description = "Durée de rétention des logs dans Log Analytics"
  type        = number
  default     = 30
}

variable "log_daily_quota_gb" {
  description = "Plafond quotidien d'ingestion de logs en Go (maîtrise du coût sur Azure Students)"
  type        = number
  default     = 0.5
}

variable "enable_nsg_flow_logs" {
  description = "Active les NSG Flow Logs (nécessite Network Watcher activé sur l'abonnement + un compte de stockage dédié). Mettre à false si NetworkWatcherRG n'existe pas dans ton abonnement Students."
  type        = bool
  default     = true
}
