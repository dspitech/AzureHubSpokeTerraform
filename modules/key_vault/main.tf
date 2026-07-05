# Identité de l'appelant Terraform (utilisée pour l'access policy du Key Vault)
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name
  tags                = var.tags

  # Purge protection désactivée pour permettre un `terraform destroy` propre en lab.
  # A activer (purge_protection_enabled = true) pour un usage réel au-delà d'un lab.
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  # Accès accordé à l'identité qui exécute Terraform (utilisateur az login ou Service Principal).
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }
}

# Un secret Key Vault par entrée de la map `secrets` (ex: identifiants VM)
resource "azurerm_key_vault_secret" "this" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.this.id
}
