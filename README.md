# Azure Hub & Spoke - Infrastructure as Code avec Terraform

![Microsoft Azure](https://img.shields.io/badge/Microsoft%20Azure-Cloud-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Windows Server 2022](https://img.shields.io/badge/Windows%20Server-2022-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![Azure Firewall](https://img.shields.io/badge/Azure-Firewall-0C6F82?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Azure Bastion](https://img.shields.io/badge/Azure-Bastion-0089D6?style=for-the-badge&logo=microsoftazure&logoColor=white)
![VNet Peering](https://img.shields.io/badge/Azure-VNet%20Peering-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)
![Security](https://img.shields.io/badge/Cybersecurity-Hardened-success?style=for-the-badge&logo=shield&logoColor=white)

## Auteur

**LO Pape** — [pape.lo@estiam.com](mailto:pape.lo@estiam.com)

Projet : `AZ-PRO-HUB-SPOKE-NORWAY` · Région : `norwayeast` · Environnement de développement : Cloud Shell

## Description
Déploiement automatisé et 100 % reproductible d'une architecture réseau **Hub & Spoke** sécurisée sur Microsoft Azure, entièrement modularisée en Terraform.

---

## Sommaire

- [Aperçu du projet](#aperçu-du-projet)
- [Architecture](#architecture)
- [Schéma du réseau](#schéma-du-réseau)
- [Flux de trafic et sécurité](#flux-de-trafic-et-sécurité)
- [Structure du dépôt](#structure-du-dépôt)
- [Modules Terraform](#modules-terraform)
- [Plan d'adressage IP](#plan-dadressage-ip)
- [Variables d'entrée](#variables-dentrée)
- [Sorties (outputs)](#sorties-outputs)
- [Prérequis](#prérequis)
- [Installation et déploiement](#installation-et-déploiement)
- [Connexion aux machines virtuelles](#connexion-aux-machines-virtuelles)
- [Tests de validation](#tests-de-validation)
- [Nettoyage des ressources](#nettoyage-des-ressources)
- [Bonnes pratiques de sécurité](#bonnes-pratiques-de-sécurité)
- [Gestion du state Terraform](#gestion-du-state-terraform)
- [Estimation des coûts](#estimation-des-coûts)
- [Pistes d'amélioration](#pistes-damélioration)
- [Dépannage (Troubleshooting)](#dépannage-troubleshooting)
- [Licence](#licence)
- [Auteur](#auteur)

---

## Aperçu du projet

Ce projet déploie, via **Terraform**, une architecture réseau Azure de type **Hub & Spoke** — un modèle de référence largement adopté en entreprise pour centraliser la sécurité et la gouvernance réseau tout en isolant les charges applicatives.

Un **VNet Hub** central héberge les services de sécurité partagés (pare-feu, bastion), tandis que deux **VNets Spoke** hébergent chacun une charge de travail applicative (une VM Windows Server). Tout le trafic entre les Spokes est **forcé de transiter par le Firewall central** grâce à des tables de routage définies par l'utilisateur (UDR), et l'accès administratif aux VMs se fait exclusivement via **Azure Bastion**, sans aucune IP publique exposée sur les machines virtuelles.

**Points clés du projet :**

| Caractéristique | Détail |
|---|---|
| Infrastructure as Code | 100 % Terraform, modulaire et réutilisable |
| Idempotence | `terraform apply` peut être rejoué sans dupliquer ou casser les ressources |
| Sécurité réseau | Aucune IP publique sur les VMs, inspection centralisée du trafic inter-Spoke |
| Accès administratif | Azure Bastion (RDP/SSH via portail, sans IP publique ni agent) |
| Automatisation | Next-hop du Firewall calculé automatiquement (plus de saisie manuelle) |
| Secrets | Mot de passe VM externalisé (variable sensible, non committé) |

---

## Architecture

L'architecture repose sur un **VNet Hub** central connecté à deux **VNets Spoke** par peering VNet bidirectionnel. Le Hub concentre les composants de sécurité et d'administration partagés par l'ensemble de la plateforme.

- **VnetHub** (`10.0.0.0/16`) — contient :
  - `AzureFirewallSubnet` → Azure Firewall (inspection et filtrage du trafic inter-Spoke)
  - `AzureBastionSubnet` → Azure Bastion (point d'accès administratif unique)
  - `Prod` → réservé à de futures ressources centrales
- **VnetSpoke1** (`192.168.0.0/24`) — sous-réseau `Prod` hébergeant `VM-SPOKE-1`
- **VnetSpoke2** (`172.16.0.0/24`) — sous-réseau `Prod` hébergeant `VM-SPOKE-2`

Le trafic entre Spoke1 et Spoke2 ne passe **jamais directement** par le peering : des routes définies par l'utilisateur (UDR) forcent ce trafic à transiter par l'IP privée de l'Azure Firewall, qui applique ensuite ses règles de filtrage réseau avant de router le paquet vers sa destination.

## Schéma du réseau

```mermaid
flowchart TB
    subgraph HUB["VNet Hub — 10.0.0.0/16"]
        FW["Azure Firewall<br/>AzureFirewallSubnet — 10.0.2.0/24"]
        BAS["Azure Bastion<br/>AzureBastionSubnet — 10.0.4.0/24"]
        PIP1[["IP publique Firewall"]]
        PIP2[["IP publique Bastion"]]
        FW --- PIP1
        BAS --- PIP2
    end

    subgraph SPOKE1["VNet Spoke1 — 192.168.0.0/24"]
        VM1["VM-SPOKE-1<br/>Windows Server 2022<br/>(pas d'IP publique)"]
        UDR1["UDR Spoke1<br/>route vers Spoke2 → Firewall"]
    end

    subgraph SPOKE2["VNet Spoke2 — 172.16.0.0/24"]
        VM2["VM-SPOKE-2<br/>Windows Server 2022<br/>(pas d'IP publique)"]
        UDR2["UDR Spoke2<br/>route vers Spoke1 → Firewall"]
    end

    HUB <-->|Peering<br/>allow_forwarded_traffic| SPOKE1
    HUB <-->|Peering<br/>allow_forwarded_traffic| SPOKE2

    VM1 -.->|Trafic inter-Spoke<br/>forcé via UDR| FW
    FW -.->|Filtré puis routé| VM2

    ADMIN(["Administrateur"]) -->|HTTPS 443<br/>portail Azure| BAS
    BAS -->|RDP privé| VM1
    BAS -->|RDP privé| VM2

    INTERNET(["Internet"]) -.->|Sortie NAT| FW
```

## Flux de trafic et sécurité

| Flux | Chemin | Contrôle appliqué |
|---|---|---|
| Administrateur → VM-SPOKE-1 / VM-SPOKE-2 | Portail Azure → Azure Bastion → NIC privée de la VM | Aucune IP publique sur les VMs ; accès centralisé via Bastion |
| VM-SPOKE-1 → VM-SPOKE-2 | Peering Spoke1↔Hub → UDR → Azure Firewall → Peering Hub↔Spoke2 | Règle réseau `Spoke1-to-Spoke2-Ping` (ICMP) sur le Firewall |
| VM-SPOKE-2 → VM-SPOKE-1 | Peering Spoke2↔Hub → UDR → Azure Firewall → Peering Hub↔Spoke1 | Règle réseau `Spoke2-to-Spoke1-Ping` (ICMP) sur le Firewall |
| VM → Internet | Sortie via SNAT du Firewall (IP publique associée) | Filtrage centralisé, traçable |
| Trafic entrant non sollicité | — | Bloqué : NSG sur chaque subnet `Prod`, aucune IP publique exposée |

Chaque subnet `Prod` (Spoke1 et Spoke2) est également protégé par un **Network Security Group** dédié, qui n'autorise explicitement que le trafic ICMP entrant nécessaire aux tests de connectivité — tout le reste est implicitement refusé par les règles par défaut d'Azure.

---

## Structure du dépôt

```
AzureHubSpokeTerraform/
├── main.tf                       # Assemblage de tous les modules
├── variables.tf                  # Variables racine (adressage, tailles, tags...)
├── outputs.tf                    # IP Firewall, IP VMs, DNS Bastion...
├── providers.tf                  # Provider azurerm + bloc backend (à activer)
├── terraform.tfvars.example      # Modèle de fichier de variables à copier
├── .gitignore                    # Exclusion des states et secrets
├── LICENSE                       # Licence MIT
├── README.md
└── modules/
    ├── resource_group/           # Groupe de ressources
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── network/                  # VNet + subnets (réutilisé pour Hub / Spoke1 / Spoke2)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── nsg/                      # Network Security Group + règles + association subnet
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── vm/                       # VM Windows Server 2022, sans IP publique
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── firewall/                 # Azure Firewall + IP publique + règles réseau
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── route_table/               # UDR + routes + association subnet
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── peering/                   # Peering VNet (instancié 2x par paire Hub/Spoke)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── bastion/                   # Azure Bastion + IP publique
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

Le projet suit une architecture **100 % modulaire** : chaque brique Azure (réseau, sécurité, calcul, routage) est isolée dans son propre module Terraform, réutilisable et testable indépendamment. Le fichier `main.tf` à la racine agit comme un **orchestrateur** qui assemble ces modules dans le bon ordre logique.

---

## Modules Terraform

| Module | Ressources Azure créées | Rôle |
|---|---|---|
| `resource_group` | `azurerm_resource_group` | Conteneur logique de toutes les ressources du projet |
| `network` | `azurerm_virtual_network`, `azurerm_subnet` | Création générique d'un VNet et de ses subnets (réutilisé 3 fois : Hub, Spoke1, Spoke2) |
| `nsg` | `azurerm_network_security_group`, `azurerm_network_security_rule`, `azurerm_subnet_network_security_group_association` | Filtrage du trafic au niveau subnet, règles dynamiques |
| `vm` | `azurerm_network_interface`, `azurerm_windows_virtual_machine` | VM Windows Server 2022, carte réseau sans IP publique |
| `firewall` | `azurerm_public_ip`, `azurerm_firewall`, `azurerm_firewall_network_rule_collection` | Pare-feu centralisé, règles réseau générées dynamiquement |
| `route_table` | `azurerm_route_table`, `azurerm_route`, `azurerm_subnet_route_table_association` | UDR forçant le trafic inter-Spoke via le Firewall |
| `peering` | `azurerm_virtual_network_peering` | Peering VNet à sens unique (instancié deux fois pour une liaison bidirectionnelle) |
| `bastion` | `azurerm_public_ip`, `azurerm_bastion_host` | Point d'accès administratif unique, sans exposition des VMs |

### Ordre de déploiement logique (géré automatiquement par le graphe Terraform)

1. **Groupe de ressources**
2. **Réseaux virtuels** (Hub, Spoke1, Spoke2) et leurs sous-réseaux
3. **Network Security Groups** et association aux subnets `Prod`
4. **Machines virtuelles** (dépendent des NSG via `depends_on`)
5. **Azure Firewall** et règles de filtrage inter-Spoke
6. **Tables de routage (UDR)** — le next-hop est calculé automatiquement à partir de l'IP privée du Firewall (`module.firewall.private_ip_address`)
7. **Peering VNet** Hub↔Spoke1 et Hub↔Spoke2 (bidirectionnel, `allow_forwarded_traffic = true`)
8. **Azure Bastion**

Terraform résout ces dépendances via son graphe de ressources ; aucune intervention manuelle sur l'ordre n'est nécessaire.

---

## Plan d'adressage IP

| Réseau | Plage CIDR | Sous-réseau | Plage du sous-réseau | Usage |
|---|---|---|---|---|
| VnetHub | `10.0.0.0/16` | AzureFirewallSubnet | `10.0.2.0/24` | Azure Firewall (nom réservé Azure) |
| VnetHub | `10.0.0.0/16` | AzureBastionSubnet | `10.0.4.0/24` | Azure Bastion (nom réservé Azure) |
| VnetHub | `10.0.0.0/16` | Prod | `10.0.1.0/24` | Réservé, extension future |
| VnetSpoke1 | `192.168.0.0/24` | Prod | `192.168.0.0/24` | VM-SPOKE-1 |
| VnetSpoke2 | `172.16.0.0/24` | Prod | `172.16.0.0/24` | VM-SPOKE-2 |

Les noms `AzureFirewallSubnet` et `AzureBastionSubnet` sont des **noms réservés par Azure** : ils doivent être utilisés tels quels, sans variation, pour que les services correspondants puissent y être déployés.

---

## Variables d'entrée

Ces variables sont définies dans `variables.tf` à la racine et peuvent être surchargées via `terraform.tfvars` ou des variables d'environnement `TF_VAR_*`.

| Variable | Type | Valeur par défaut | Description |
|---|---|---|---|
| `resource_group_name` | `string` | `RG-HUB-SPOKE-PROJECT` | Nom du groupe de ressources |
| `location` | `string` | `norwayeast` | Région Azure de déploiement |
| `admin_username` | `string` | `azure_admin` | Identifiant administrateur des VMs |
| `admin_password` | `string` *(sensible)* | — *(obligatoire)* | Mot de passe administrateur des VMs |
| `vm_size` | `string` | `Standard_B2s` | Taille des machines virtuelles |
| `firewall_sku_tier` | `string` | `Standard` | Tier du SKU Azure Firewall (`Standard`, `Premium` ou `Basic`) |
| `hub_address_space` | `list(string)` | `["10.0.0.0/16"]` | Plage d'adresses du VNet Hub |
| `hub_prod_subnet_prefix` | `list(string)` | `["10.0.1.0/24"]` | Sous-réseau Prod du Hub |
| `hub_firewall_subnet_prefix` | `list(string)` | `["10.0.2.0/24"]` | Sous-réseau du Firewall |
| `hub_bastion_subnet_prefix` | `list(string)` | `["10.0.4.0/24"]` | Sous-réseau du Bastion |
| `spoke1_address_space` | `list(string)` | `["192.168.0.0/24"]` | Plage d'adresses de Spoke1 |
| `spoke2_address_space` | `list(string)` | `["172.16.0.0/24"]` | Plage d'adresses de Spoke2 |
| `tags` | `map(string)` | `{ projet, environment, gere_par }` | Tags communs appliqués à toutes les ressources |

---

## Sorties (outputs)

Après un `terraform apply` réussi, les valeurs suivantes sont affichées (définies dans `outputs.tf`) :

| Output | Description |
|---|---|
| `resource_group_name` | Nom du groupe de ressources créé |
| `firewall_public_ip` | IP publique de sortie du Firewall |
| `firewall_private_ip` | IP privée du Firewall, utilisée comme next-hop dans les UDR |
| `bastion_dns_name` | Nom DNS d'Azure Bastion |
| `vm_spoke1_private_ip` | IP privée de VM-SPOKE-1 |
| `vm_spoke2_private_ip` | IP privée de VM-SPOKE-2 |

Consulter une sortie individuelle après déploiement :

```bash
terraform output firewall_public_ip
terraform output -json
```

---

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/downloads) ≥ 1.6.0
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installée et authentifiée (`az login`) — Terraform réutilise cette session
- Un abonnement Azure actif avec un rôle **Contributor** (ou équivalent) sur le scope cible
- Le provider `azurerm` (`~> 3.100`), téléchargé automatiquement par `terraform init`

Vérification rapide de l'environnement :

```bash
terraform version
az account show
```

---

## Installation et déploiement

```bash
# 1. Cloner le dépôt et se placer à sa racine
git clone https://github.com/dspitech/AzureHubSpokeTerraform.git
cd AzureHubSpokeTerraform

# 2. Initialiser Terraform (téléchargement du provider azurerm)
terraform init

# 3. Formatage et validation
terraform fmt && terraform validate

# 4. Copier et adapter le fichier de variables (optionnel mais recommandé)
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars : adapter resource_group_name, location, tags, etc.

# 5. Définir le mot de passe admin SANS le committer
admin_password="VotreMotDePasseComplexe!2025"

# 6. Vérifier le plan d'exécution
terraform plan

# 7. Déployer l'infrastructure
terraform apply -auto-approve
```

À l'issue du déploiement (environ 10 à 15 minutes, principalement pour le provisioning du Firewall et du Bastion), Terraform affiche les outputs définis ci-dessus.

---

## Connexion aux machines virtuelles

Les VMs `VM-SPOKE-1` et `VM-SPOKE-2` ne possèdent **aucune IP publique**. L'unique point d'accès est **Azure Bastion** :

1. Depuis le [portail Azure](https://portal.azure.com), ouvrir la ressource `VM-SPOKE-1` ou `VM-SPOKE-2`.
2. Cliquer sur **Connect** → **Bastion**.
3. Renseigner `admin_username` et le mot de passe défini via `admin_password` dans le fichier `terraform.tfvars`.
4. La session RDP s'ouvre directement dans le navigateur, en HTTPS, sans exposer la VM à Internet.

---

## Tests de validation

Une fois connecté aux deux VMs via Bastion, valider le bon fonctionnement du filtrage inter-Spoke :

```powershell
# Depuis VM-SPOKE-1, tester la connectivité vers VM-SPOKE-2
ping  <ip_privee_vm_spoke2>

# Depuis VM-SPOKE-2, tester la connectivité vers VM-SPOKE-1
ping -ComputerName <ip_privee_vm_spoke1>
```

Le ping doit aboutir : le trafic transite par le Firewall (visible dans **Azure Firewall → Logs et métriques**), qui applique la règle réseau `Allow-InterSpoke` avant de router le paquet. Toute autre règle non définie explicitement est bloquée par défaut.

---

## Nettoyage des ressources

```bash
terraform destroy -auto-approve
```

Cette commande supprime uniquement les ressources gérées par Terraform et met à jour le state en conséquence — contrairement à une suppression manuelle du groupe de ressources, elle garantit la cohérence entre l'infrastructure réelle et l'état Terraform.

---

## Bonnes pratiques de sécurité

- **Ne jamais committer** `terraform.tfvars` ni `*.tfstate` : le state Terraform contient le mot de passe VM en clair. Ces fichiers sont déjà exclus par `.gitignore`.
- Préférer une **variable d'environnement** (`TF_VAR_admin_password`) ou un secret manager plutôt qu'un fichier tfvars pour le mot de passe.
- Pour un usage au-delà d'un lab, stocker le state dans un **backend distant chiffré** (`azurerm` backend sur un Storage Account) — le bloc est déjà présent, commenté, dans `providers.tf`.
- Envisager de générer le mot de passe avec la ressource `random_password` et de le stocker dans **Azure Key Vault** plutôt que de le passer en variable brute.
- Les VMs n'ayant aucune IP publique, la surface d'attaque exposée à Internet se limite aux IP publiques du Firewall et du Bastion — toutes deux protégées par les contrôles natifs de ces services managés.
- Envisager l'activation de **Microsoft Defender for Cloud** pour un monitoring de sécurité continu sur l'ensemble de l'abonnement.

---

## Gestion du state Terraform

Par défaut, ce projet utilise un **state local** (`terraform.tfstate`), adapté à un usage individuel ou de lab. Pour un contexte d'équipe ou de production, activer le backend distant prêt à l'emploi dans `providers.tf` :

```hcl
backend "azurerm" {
  resource_group_name  = "RG-TFSTATE"
  storage_account_name = "sttfstatehubspoke"
  container_name       = "tfstate"
  key                  = "hub-spoke.tfstate"
}
```

Ce backend nécessite un Storage Account existant, créé au préalable (hors scope de ce projet), et permet le verrouillage du state (`state locking`) pour éviter les écritures concurrentes.

---

## Estimation des coûts

Les composants les plus significatifs en termes de coût sont :

| Ressource | Facteur de coût principal |
|---|---|
| Azure Firewall | Facturation horaire fixe + volume de données traité (le poste le plus coûteux de l'architecture) |
| Azure Bastion | Facturation horaire fixe (SKU Standard) |
| VMs Windows Server | Taille de VM (`Standard_B2s` par défaut) + licence Windows incluse |
| IP publiques Standard | Facturation horaire, faible impact |

Pensez à exécuter `terraform destroy` en dehors des périodes d'utilisation (lab, formation, démonstration) : le Firewall et le Bastion sont facturés en continu tant qu'ils sont provisionnés, indépendamment de leur utilisation réelle.

---

## Pistes d'amélioration

- Génération automatique du mot de passe VM via `random_password` + stockage dans **Azure Key Vault**
- Ajout d'un **Azure Firewall Policy** dédié pour découpler les règles du cycle de vie du Firewall
- Mise en place de **Log Analytics** et de diagnostics settings sur le Firewall, le Bastion et les NSG
- Ajout de tests automatisés (`terraform validate`, `tflint`, `checkov`) dans une pipeline CI/CD (GitHub Actions)
- Passage à des images Linux (Ubuntu 22.04) en complément ou remplacement du Windows Server pour réduire les coûts de licence
- Ajout d'un troisième Spoke pour valider le passage à l'échelle du modèle

---

## Dépannage (Troubleshooting)

| Symptôme | Cause probable | Solution |
|---|---|---|
| `Error: building AzureRM Client: ... could not be obtained` | Session Azure CLI expirée ou absente | Relancer `az login` puis `az account set --subscription <id>` |
| `admin_password is required` | Variable sensible non fournie | Exporter `TF_VAR_admin_password` avant `terraform apply` |
| Ping inter-Spoke qui échoue | Règle Firewall non propagée ou UDR mal associée | Vérifier `terraform plan` pour un drift, puis les logs du Firewall dans le portail |
| `terraform apply` bloqué sur le Bastion | Provisioning normalement long (5–10 min) | Patienter ; Azure Bastion est un service géré à démarrage plus lent que les autres ressources |
| Conflit d'adressage IP | Chevauchement entre `hub_address_space`, `spoke1_address_space`, `spoke2_address_space` | Adapter les plages CIDR dans `terraform.tfvars` avant tout déploiement |

---

## Licence

Ce projet est distribué sous licence **MIT** — voir le fichier [`LICENSE`](./LICENSE) pour le texte complet.

---

