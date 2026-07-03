output "name" {
  description = "Nom du groupe de ressources"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Région du groupe de ressources"
  value       = azurerm_resource_group.this.location
}

output "id" {
  description = "ID du groupe de ressources"
  value       = azurerm_resource_group.this.id
}
