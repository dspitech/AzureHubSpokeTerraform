# NSG Flow Log : capture le trafic réel autorisé/bloqué par le NSG et l'archive
# dans un compte de stockage. C'est la preuve concrète du filtrage réseau en soutenance.
resource "azurerm_network_watcher_flow_log" "this" {
  name                     = var.name
  network_watcher_name     = var.network_watcher_name
  resource_group_name      = var.network_watcher_resource_group_name
  network_security_group_id = var.network_security_group_id
  storage_account_id       = var.storage_account_id
  enabled                  = true

  retention_policy {
    enabled = true
    days    = var.retention_days
  }

  # Traffic Analytics désactivé par défaut : nécessite un 2e workspace Log Analytics
  # facturé séparément. A activer uniquement si le budget Azure Students le permet.
  dynamic "traffic_analytics" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_guid
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_id
      interval_in_minutes   = 60
    }
  }
}
