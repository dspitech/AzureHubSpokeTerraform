# Peering dans un seul sens. Pour une liaison complète Hub<->Spoke,
# instancier ce module deux fois (voir main.tf racine).
resource "azurerm_virtual_network_peering" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.vnet_name
  remote_virtual_network_id    = var.remote_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
}
