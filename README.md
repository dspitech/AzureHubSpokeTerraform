# Azure Hub & Spoke Sécurisée — Déploiement Terraform

Portage du déploiement Azure CLI/PowerShell original vers une infrastructure
Terraform modulaire. Même architecture, même adressage, même logique de
sécurité (Firewall central, Bastion, UDR forçant le trafic inter-spoke via
le Firewall), mais 100% déclaratif, idempotent et versionnable.

## Architecture

- **VnetHub** (10.0.0.0/16) : AzureFirewallSubnet, AzureBastionSubnet, Prod
- **VnetSpoke1** (192.168.0.0/24) : Prod (VM-SPOKE-1)
- **VnetSpoke2** (172.16.0.0/24) : Prod (VM-SPOKE-2)
- **Azure Firewall** : inspection et filtrage ICMP entre les deux spokes
- **Azure Bastion** : seul point d'accès RDP aux VMs (aucune IP publique sur les VMs)
- **UDR** : force le trafic Spoke1<->Spoke2 à transiter par le Firewall
- **Peering** : Hub<->Spoke1 et Hub<->Spoke2, bidirectionnel, `allow_forwarded_traffic = true`

## Arborescence

```
terraform-hub-spoke/
├── main.tf                  # assemblage des modules (le "script" principal)
├── variables.tf              # variables racine (adressage, tailles, tags...)
├── outputs.tf                 # IP firewall, IP VMs, DNS bastion...
├── providers.tf               # provider azurerm + backend (à configurer)
├── terraform.tfvars.example    # modèle de fichier de variables
├── .gitignore
├── modules/
│   ├── resource_group/        # groupe de ressources
│   ├── network/                # VNet + subnets (réutilisé pour Hub/Spoke1/Spoke2)
│   ├── nsg/                     # NSG + règles + association subnet
│   ├── vm/                       # VM Windows Server 2022, sans IP publique
│   ├── firewall/                  # Azure Firewall + IP publique + règles réseau
│   ├── route_table/                # UDR + routes + association subnet
│   ├── peering/                     # peering VNet (instancié 2x par paire hub/spoke)
│   └── bastion/                      # Azure Bastion + IP publique
```

## Différences notables vs le script original

- **Next-hop du Firewall** : plus besoin de le saisir manuellement
  (`Read-Host`). Terraform le récupère automatiquement via
  `module.firewall.private_ip_address` et le référence dans les UDR — élimine
  tout risque d'erreur de frappe et rend le déploiement 100% non-interactif.
- **Mot de passe VM** : sorti du code, doit être fourni via variable
  d'environnement ou fichier `tfvars` non committé (voir plus bas).
- **Idempotence** : `terraform apply` peut être relancé sans dupliquer ou
  casser les ressources existantes, contrairement aux commandes `az` lancées
  telles quelles.
- **Ordre de dépendance** : géré automatiquement par le graphe Terraform
  (plus besoin de respecter l'ordre des étapes 1 à 10 manuellement).

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6
- Azure CLI connecté (`az login`) — Terraform réutilise cette session
- Un compte avec les droits Contributor sur l'abonnement cible

## Déploiement

```bash
cd terraform-hub-spoke

# 1. Initialiser (télécharge le provider azurerm)
terraform init

# 2. Définir le mot de passe admin SANS le committer
export TF_VAR_admin_password="VotreMotDePasseComplexe!2025"

# 3. (Optionnel) copier et adapter le fichier de variables
cp terraform.tfvars.example terraform.tfvars

# 4. Vérifier le plan
terraform plan

# 5. Déployer
terraform apply
```

## Nettoyage

```bash
terraform destroy
```

Équivalent Terraform de l'Étape 14 (`az group delete`), mais qui ne supprime
que ce que Terraform a créé et met à jour le state en conséquence.

## Sécurité — points d'attention

- Ne jamais committer `terraform.tfvars` ni `*.tfstate` (le state contient le
  mot de passe VM en clair) : `.gitignore` les exclut déjà.
- Pour un usage au-delà d'un lab, stocker le state dans un backend distant
  chiffré (`azurerm` backend sur un Storage Account) — bloc prêt à
  décommenter dans `providers.tf`.
- Pour aller plus loin : générer le mot de passe avec la ressource
  `random_password` et le stocker dans Azure Key Vault plutôt que de le
  passer en variable.
