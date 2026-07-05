terraform {
  required_version = ">= 1.6.0"

  # --- Backend distant : Terraform Cloud (HCP Terraform), tier gratuit ---
  # 1. Créer un compte sur https://app.terraform.io et une organisation.
  # 2. Créer un workspace "azure-hub-spoke" en mode CLI-driven.
  # 3. Remplacer "TON_ORG_TERRAFORM_CLOUD" ci-dessous par le nom de ton organisation.
  # 4. `terraform login` (génère un jeton API local) puis `terraform init`.
  #
  # IMPORTANT (comptes Azure Students liés à un tenant d'établissement) :
  # si `az ad sp create-for-rbac` échoue avec "Insufficient privileges" (App
  # Registration désactivée par une politique du tenant), passer le workspace
  # en Execution Mode = "Local" (Settings > General) au lieu de "Remote".
  # Le state reste stocké/verrouillé sur Terraform Cloud, mais `plan`/`apply`
  # s'exécutent en local en réutilisant la session `az login` existante -
  # aucun Service Principal n'est alors nécessaire.
  #
  # Le state est alors stocké chiffré côté Terraform Cloud, versionné et verrouillé
  # (state locking) automatiquement à chaque apply - plus besoin de gérer un
  # Storage Account Azure dédié uniquement pour le state.
  cloud {
    organization = "TON_ORG_TERRAFORM_CLOUD"

    workspaces {
      name = "azure-hub-spoke"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # --- Alternative : backend azurerm (Storage Account) ---
  # Mutuellement exclusif avec le bloc `cloud` ci-dessus : ne garder qu'un seul des deux.
  #
  # backend "azurerm" {
  #   resource_group_name  = "RG-TFSTATE"
  #   storage_account_name = "sttfstatehubspoke"
  #   container_name       = "tfstate"
  #   key                  = "hub-spoke.tfstate"
  # }
}

provider "azurerm" {
  features {}
}
