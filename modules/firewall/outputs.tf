output "id" {
  value = azurerm_firewall.this.id
}

output "name" {
  value = azurerm_firewall.this.name
}

output "public_ip_address" {
  value = azurerm_public_ip.this.ip_address
}

output "private_ip_address" {
  description = "IP privée du Firewall, utilisée comme next-hop dans les UDR"
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}
