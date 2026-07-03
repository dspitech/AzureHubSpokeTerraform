###############################################################################
# 1. Groupe de ressources
###############################################################################

module "rg" {
  source   = "./modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

###############################################################################
# 2. Réseaux virtuels (Hub + 2 Spokes) et sous-réseaux
###############################################################################

module "vnet_hub" {
  source               = "./modules/network"
  name                 = "VnetHub"
  location             = var.location
  resource_group_name  = module.rg.name
  address_space        = var.hub_address_space
  tags                 = var.tags

  subnets = {
    # Nom réservé Azure - requis tel quel pour le déploiement du Firewall
    "AzureFirewallSubnet" = { address_prefixes = var.hub_firewall_subnet_prefix }
    # Nom réservé Azure - requis tel quel pour le déploiement de Bastion
    "AzureBastionSubnet"  = { address_prefixes = var.hub_bastion_subnet_prefix }
    "Prod"                = { address_prefixes = var.hub_prod_subnet_prefix }
  }
}

module "vnet_spoke1" {
  source               = "./modules/network"
  name                 = "VnetSpoke1"
  location             = var.location
  resource_group_name  = module.rg.name
  address_space        = var.spoke1_address_space
  tags                 = var.tags

  subnets = {
    "Prod" = { address_prefixes = var.spoke1_address_space }
  }
}

module "vnet_spoke2" {
  source               = "./modules/network"
  name                 = "VnetSpoke2"
  location             = var.location
  resource_group_name  = module.rg.name
  address_space        = var.spoke2_address_space
  tags                 = var.tags

  subnets = {
    "Prod" = { address_prefixes = var.spoke2_address_space }
  }
}

###############################################################################
# 3. Network Security Groups (autorisation ICMP + association aux subnets Prod)
###############################################################################

module "nsg_spoke1" {
  source               = "./modules/nsg"
  name                 = "NSG-Spoke1"
  location             = var.location
  resource_group_name  = module.rg.name
  subnet_id            = module.vnet_spoke1.subnet_ids["Prod"]
  tags                 = var.tags

  rules = [
    {
      name                        = "Allow-Ping-Inbound"
      priority                    = 100
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Icmp"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
    }
  ]
}

module "nsg_spoke2" {
  source               = "./modules/nsg"
  name                 = "NSG-Spoke2"
  location             = var.location
  resource_group_name  = module.rg.name
  subnet_id            = module.vnet_spoke2.subnet_ids["Prod"]
  tags                 = var.tags

  rules = [
    {
      name                        = "Allow-Ping-Inbound"
      priority                    = 100
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Icmp"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
    }
  ]
}

###############################################################################
# 4. Machines virtuelles (sans IP publique)
###############################################################################

module "vm_spoke1" {
  source               = "./modules/vm"
  name                 = "VM-SPOKE-1"
  location             = var.location
  resource_group_name  = module.rg.name
  subnet_id            = module.vnet_spoke1.subnet_ids["Prod"]
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  tags                 = var.tags

  depends_on = [module.nsg_spoke1]
}

module "vm_spoke2" {
  source               = "./modules/vm"
  name                 = "VM-SPOKE-2"
  location             = var.location
  resource_group_name  = module.rg.name
  subnet_id            = module.vnet_spoke2.subnet_ids["Prod"]
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  tags                 = var.tags

  depends_on = [module.nsg_spoke2]
}

###############################################################################
# 5. Azure Firewall + règles de filtrage inter-spoke
###############################################################################

module "firewall" {
  source               = "./modules/firewall"
  name                 = "AzureFireWall"
  location             = var.location
  resource_group_name  = module.rg.name
  subnet_id            = module.vnet_hub.subnet_ids["AzureFirewallSubnet"]
  sku_tier             = var.firewall_sku_tier
  tags                 = var.tags

  network_rule_collections = [
    {
      name     = "Allow-InterSpoke"
      priority = 100
      action   = "Allow"
      rules = [
        {
          name                   = "Spoke1-to-Spoke2-Ping"
          source_addresses       = var.spoke1_address_space
          destination_addresses  = var.spoke2_address_space
          destination_ports      = ["*"]
          protocols              = ["ICMP"]
        },
        {
          name                   = "Spoke2-to-Spoke1-Ping"
          source_addresses       = var.spoke2_address_space
          destination_addresses  = var.spoke1_address_space
          destination_ports      = ["*"]
          protocols              = ["ICMP"]
        }
      ]
    }
  ]
}

###############################################################################
# 6. Tables de routage (UDR) - next hop = IP privée du Firewall
#    (calculée automatiquement, plus besoin de la saisir manuellement)
###############################################################################

module "udr_spoke1" {
  source               = "./modules/route_table"
  name                 = "UdrSpoke1"
  location             = var.location
  resource_group_name  = module.rg.name
  subnet_id            = module.vnet_spoke1.subnet_ids["Prod"]
  tags                 = var.tags

  routes = [
    {
      name                   = "To-Spoke2"
      address_prefix         = var.spoke2_address_space[0]
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip_address
    }
  ]
}

module "udr_spoke2" {
  source               = "./modules/route_table"
  name                 = "UdrSpoke2"
  location             = var.location
  resource_group_name  = module.rg.name
  subnet_id            = module.vnet_spoke2.subnet_ids["Prod"]
  tags                 = var.tags

  routes = [
    {
      name                   = "To-Spoke1"
      address_prefix         = var.spoke1_address_space[0]
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip_address
    }
  ]
}

###############################################################################
# 7. Peering Hub <-> Spokes (bidirectionnel, forwarded traffic activé)
###############################################################################

module "peering_hub_to_spoke1" {
  source                   = "./modules/peering"
  name                     = "HubToSpoke1"
  resource_group_name      = module.rg.name
  vnet_name                = module.vnet_hub.vnet_name
  remote_vnet_id           = module.vnet_spoke1.vnet_id
  allow_forwarded_traffic  = true
}

module "peering_spoke1_to_hub" {
  source                   = "./modules/peering"
  name                     = "Spoke1ToHub"
  resource_group_name      = module.rg.name
  vnet_name                = module.vnet_spoke1.vnet_name
  remote_vnet_id           = module.vnet_hub.vnet_id
  allow_forwarded_traffic  = true
}

module "peering_hub_to_spoke2" {
  source                   = "./modules/peering"
  name                     = "HubToSpoke2"
  resource_group_name      = module.rg.name
  vnet_name                = module.vnet_hub.vnet_name
  remote_vnet_id           = module.vnet_spoke2.vnet_id
  allow_forwarded_traffic  = true
}

module "peering_spoke2_to_hub" {
  source                   = "./modules/peering"
  name                     = "Spoke2ToHub"
  resource_group_name      = module.rg.name
  vnet_name                = module.vnet_spoke2.vnet_name
  remote_vnet_id           = module.vnet_hub.vnet_id
  allow_forwarded_traffic  = true
}

###############################################################################
# 8. Azure Bastion
###############################################################################

module "bastion" {
  source               = "./modules/bastion"
  name                 = "AzureBastion"
  location             = var.location
  resource_group_name  = module.rg.name
  subnet_id            = module.vnet_hub.subnet_ids["AzureBastionSubnet"]
  tags                 = var.tags
}
