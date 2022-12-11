# -----------------------------
# SUBNETS
# -----------------------------
resource "azurerm_subnet" "adarly" {
  name                 = "adarly-subnet"
  resource_group_name  = azurerm_resource_group.useast2.name
  virtual_network_name = azurerm_virtual_network.useast2.name
  address_prefixes     = ["10.0.1.0/25"]
}

resource "azurerm_subnet" "adabp" {
  name                 = "adabp-subnet"
  resource_group_name  = azurerm_resource_group.useast2.name
  virtual_network_name = azurerm_virtual_network.useast2.name
  address_prefixes     = ["10.0.1.128/25"]
}

resource "azurerm_subnet" "cardano-relay" {
  name                 = "cardano-relay-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ussouth.name
  address_prefixes     = ["10.0.65.0/25"]
}

# -----------------------------
# PUBLIC IPS
# -----------------------------
resource "azurerm_public_ip" "adarly01" {
  name                = "ip-adarly01"
  resource_group_name = azurerm_resource_group.useast2.name
  location            = azurerm_resource_group.useast2.location
  allocation_method   = "Static"
  tags                = local.cardano_tags
}

/* resource "azurerm_public_ip" "adarly02" {
  name                = "ip-adarly02"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  tags                = local.cardano_tags
} */

resource "azurerm_public_ip" "adabp" {
  name                = "ip-adabp"
  resource_group_name = azurerm_resource_group.useast2.name
  location            = azurerm_resource_group.useast2.location
  allocation_method   = "Static"
  tags                = local.cardano_tags
}

# -----------------------------
# NETWORK SECURITY GROUPS
# -----------------------------
resource "azurerm_network_security_group" "adarly" {
  name                = "nsg-adarly"
  location            = azurerm_resource_group.useast2.location
  resource_group_name = azurerm_resource_group.useast2.name
  tags                = local.cardano_tags
}

resource "azurerm_subnet_network_security_group_association" "adarly" {
  subnet_id                 = azurerm_subnet.adarly.id
  network_security_group_id = azurerm_network_security_group.adarly.id
}

resource "azurerm_network_security_group" "adabp" {
  name                = "nsg-adabp"
  location            = azurerm_resource_group.useast2.location
  resource_group_name = azurerm_resource_group.useast2.name
  tags                = local.cardano_tags
}

resource "azurerm_subnet_network_security_group_association" "adabp" {
  subnet_id                 = azurerm_subnet.adabp.id
  network_security_group_id = azurerm_network_security_group.adabp.id
}

resource "azurerm_network_security_group" "cardano-relay" {
  name                = "nsg-cardano-relay"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.cardano_tags
}

resource "azurerm_subnet_network_security_group_association" "cardano-relay" {
  subnet_id                 = azurerm_subnet.cardano-relay.id
  network_security_group_id = azurerm_network_security_group.cardano-relay.id
}

# --------------------------------------------------
# NETWORK SECURITY RULES
# --------------------------------------------------
# Allow port 22 access from Internet
resource "azurerm_network_security_rule" "adarlyInboundInternetAllow" {
  name                        = "IInternetA"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_ranges     = ["1122", "6000", "8090"]
  resource_group_name         = azurerm_resource_group.useast2.name
  network_security_group_name = azurerm_network_security_group.adarly.name
}

resource "azurerm_network_security_rule" "adarly2InboundInternetAllow" {
  name                        = "IInternetA"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_ranges     = ["1122", "6000"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.cardano-relay.name
}

# Allow port 22 access from Internet
resource "azurerm_network_security_rule" "adabpInboundInternetAllow" {
  name                        = "IInternetA"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "1122"
  resource_group_name         = azurerm_resource_group.useast2.name
  network_security_group_name = azurerm_network_security_group.adabp.name
}
# Allow port 6000 access from relay nodes subnet
resource "azurerm_network_security_rule" "adabpInboundRelayAllow" {
  name                        = "IRelayA"
  priority                    = 1100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefixes     = ["137.116.58.123", "40.84.235.38"]
  source_port_range           = "*"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "6000"
  resource_group_name         = azurerm_resource_group.useast2.name
  network_security_group_name = azurerm_network_security_group.adabp.name
}

# -----------------------------
# NETWORK INTERFACES
# -----------------------------
resource "azurerm_network_interface" "adarly01" {
  name                          = "nic-adarly01"
  location                      = azurerm_resource_group.useast2.location
  resource_group_name           = azurerm_resource_group.useast2.name
  enable_accelerated_networking = true
  internal_dns_name_label       = "adarly01"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.adarly.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.adarly01.id
  }

  tags = local.cardano_tags
}

/* resource "azurerm_network_interface" "adarly02" {
  name                          = "nic-adarly02"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  enable_accelerated_networking = true
  internal_dns_name_label       = "adarly02"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cardano-relay.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.adarly02.id
  }

  tags = local.cardano_tags
} */

resource "azurerm_network_interface" "adabp" {
  name                          = "nic-adabp"
  location                      = azurerm_resource_group.useast2.location
  resource_group_name           = azurerm_resource_group.useast2.name
  enable_accelerated_networking = true
  internal_dns_name_label       = "adabp"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.adabp.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.adabp.id
  }

  tags = local.cardano_tags
}

# ---------------------------------------------------------
# MANAGED DISK
# ---------------------------------------------------------
resource "azurerm_managed_disk" "adarly01" {
  name                 = "md-adarly01"
  location             = azurerm_resource_group.useast2.location
  resource_group_name  = azurerm_resource_group.useast2.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256

  lifecycle {
    prevent_destroy = true
  }

  tags = local.cardano_tags
}

/* resource "azurerm_managed_disk" "adarly02" {
  name                 = "md-adarly02"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128

  lifecycle {
    prevent_destroy = true
  }

  tags = local.cardano_tags
} */

resource "azurerm_managed_disk" "adabp" {
  name                 = "md-adabp"
  location             = azurerm_resource_group.useast2.location
  resource_group_name  = azurerm_resource_group.useast2.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256

  lifecycle {
    prevent_destroy = true
  }

  tags = local.cardano_tags
}

# -----------------------------
# VIRTUAL MACHINES
# -----------------------------
resource "azurerm_linux_virtual_machine" "adarly01" {
  name                = "use1ladarly01prod"
  resource_group_name = azurerm_resource_group.useast2.name
  location            = azurerm_resource_group.useast2.location
  size                = "Standard_E2s_v5"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.adarly01.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "adarly01-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  custom_data = data.cloudinit_config.default.rendered

  lifecycle {
    ignore_changes = [custom_data]
  }

  tags = local.cardano_tags
}

/* resource "azurerm_linux_virtual_machine" "adarly02" {
  name                = "use1ladarly02prod"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_E2s_v4"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.adarly02.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "adarly02-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  custom_data = data.cloudinit_config.default.rendered

  lifecycle {
    ignore_changes = [custom_data]
  }

  tags = local.cardano_tags
} */

resource "azurerm_linux_virtual_machine" "adabp" {
  name                = "use2ladabpprod"
  resource_group_name = azurerm_resource_group.useast2.name
  location            = azurerm_resource_group.useast2.location
  size                = "Standard_E4s_v5"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.adabp.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "adabp-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  custom_data = data.cloudinit_config.default.rendered

  lifecycle {
    ignore_changes = [custom_data]
  }

  tags = local.cardano_tags
}

# ------------------------------------
# VIRTUAL MACHINE DATA DISK ATTACHMENT
# ------------------------------------
resource "azurerm_virtual_machine_data_disk_attachment" "adarly01" {
  managed_disk_id    = azurerm_managed_disk.adarly01.id
  virtual_machine_id = azurerm_linux_virtual_machine.adarly01.id
  lun                = 1
  caching            = "ReadWrite"
}

/* resource "azurerm_virtual_machine_data_disk_attachment" "adarly02" {
  managed_disk_id    = azurerm_managed_disk.adarly02.id
  virtual_machine_id = azurerm_linux_virtual_machine.adarly02.id
  lun                = 1
  caching            = "ReadWrite"
}
 */
resource "azurerm_virtual_machine_data_disk_attachment" "adabp" {
  managed_disk_id    = azurerm_managed_disk.adabp.id
  virtual_machine_id = azurerm_linux_virtual_machine.adabp.id
  lun                = 1
  caching            = "ReadWrite"
}
