output "id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "name" {
  value = azurerm_log_analytics_workspace.this.name
}

output "workspace_id" {
  description = "Customer ID (GUID) du workspace, utilisé par les agents/queries KQL"
  value       = azurerm_log_analytics_workspace.this.workspace_id
}
