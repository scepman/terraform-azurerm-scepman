terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0, < 4.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.9, < 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
  }
}
