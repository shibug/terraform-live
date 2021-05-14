# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_version = ">= 0.15"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.59.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# -----------------------------
# RESOURCE GROUPS
# -----------------------------
resource "azurerm_resource_group" "dev" {
  name     = var.env
  location = "South Central US"
  tags = {
    env   = var.env
  }
}

# -----------------------------
# VIRTUAL NETWORK
# -----------------------------
resource "azurerm_virtual_network" "network" {
  name                = var.env
  address_space       = [var.cidrblock]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  tags = {
    env   = var.env
  }
}

