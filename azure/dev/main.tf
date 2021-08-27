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
resource "azurerm_virtual_network" "vn" {
  name                = "vn-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.cidrblock]

  tags = local.common_tags
}

resource "azurerm_virtual_network" "useast2" {
  name                = "vn-useast2"
  location            = azurerm_resource_group.useast2.location
  resource_group_name = azurerm_resource_group.useast2.name
  address_space       = [var.cidrblock]

  tags = local.common_tags
}

# -----------------------------
# SUBNETS
# -----------------------------
resource "azurerm_subnet" "worker" {
  name                 = "worker-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.0.0/24"]
}

# -----------------------------
# NETWORK SECURITY GROUPS
# -----------------------------

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.theta_tags
}

resource "azurerm_subnet_network_security_group_association" "nsga" {
  subnet_id                 = azurerm_subnet.worker.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# --------------------------------------------------
# NETWORK SECURITY RULES
# --------------------------------------------------

# Allow port 3389 access from Internet
resource "azurerm_network_security_rule" "workerInboundInternetAllow" {
  name                        = "IInternetA"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_ranges     = ["3389", "5900"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# -----------------------------
# PUBLIC IPS
# -----------------------------

resource "azurerm_public_ip" "theta-edge" {
  name                = "ip-theta-edge"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  tags                = local.theta_tags
}

locals {
  common_tags = {
    env = var.env
  }
  cardano_tags = {
    crypto = "cardano"
  }
  theta_tags = {
    crypto = "theta"
  }
  eth_tags = {
    crypto = "ethereum"
  }
}
