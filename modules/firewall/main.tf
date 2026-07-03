resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier
  tags                = var.tags

  ip_configuration {
    name                 = "FW-Config"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

# Règles de filtrage inter-spoke (équivalent des Étapes 9 du script original)
# Générées dynamiquement à partir de la liste `network_rule_collections`
resource "azurerm_firewall_network_rule_collection" "this" {
  for_each = { for c in var.network_rule_collections : c.name => c }

  name                 = each.value.name
  azure_firewall_name  = azurerm_firewall.this.name
  resource_group_name  = var.resource_group_name
  priority             = each.value.priority
  action               = each.value.action

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                  = rule.value.name
      source_addresses      = rule.value.source_addresses
      destination_addresses = rule.value.destination_addresses
      destination_ports     = rule.value.destination_ports
      protocols             = rule.value.protocols
    }
  }
}
