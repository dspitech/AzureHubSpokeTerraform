output "id" {
  value = azurerm_key_vault.this.id
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "secret_ids" {
  description = "Map nom_secret => id du secret Key Vault (versioned)"
  value       = { for k, s in azurerm_key_vault_secret.this : k => s.id }
}
