output "resource_group_name" {
  value = module.rg.name
}

output "firewall_public_ip" {
  description = "IP publique de sortie du Firewall"
  value       = module.firewall.public_ip_address
}

output "firewall_private_ip" {
  description = "IP privée du Firewall (next-hop des UDR)"
  value       = module.firewall.private_ip_address
}

output "bastion_dns_name" {
  value = module.bastion.dns_name
}

output "vm_spoke1_private_ip" {
  value = module.vm_spoke1.private_ip_address
}

output "vm_spoke2_private_ip" {
  value = module.vm_spoke2.private_ip_address
}
