terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # Backend distant recommandé en production pour partager le state en équipe.
  # Décommenter et adapter (Storage Account déjà existant) :
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
