# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_version = ">= 0.15"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.59.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.2.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "3e46348d-8a24-4177-9e0f-b159c0b62dd0"
}

data "azurerm_client_config" "current" {
}

# -----------------------------
# RESOURCE GROUPS
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.env}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "useast2" {
  name     = "rg-useast2"
  location = var.useast2loc
  tags     = local.common_tags
}

# -----------------------------
# VIRTUAL NETWORK
# -----------------------------
resource "azurerm_virtual_network" "ussouth" {
  name                = "vn-ussouth"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.64.0/18"]

  tags = local.common_tags
}

resource "azurerm_virtual_network" "useast2" {
  name                = "vn-useast2"
  location            = azurerm_resource_group.useast2.location
  resource_group_name = azurerm_resource_group.useast2.name
  address_space       = ["10.0.0.0/18"]

  tags = local.common_tags
}

# -----------------------------
# VIRTUAL NETWORK PEERING
# -----------------------------
resource "azurerm_virtual_network_peering" "southeast2" {
  name                      = "southtoeast2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.ussouth.name
  remote_virtual_network_id = azurerm_virtual_network.useast2.id
}

resource "azurerm_virtual_network_peering" "east2south" {
  name                      = "east2tosouth"
  resource_group_name       = azurerm_resource_group.useast2.name
  virtual_network_name      = azurerm_virtual_network.useast2.name
  remote_virtual_network_id = azurerm_virtual_network.ussouth.id
}

locals {
  common_tags = {
    env = var.env
  }
  cardano_tags = {
    crypto = "cardano"
  }
}
