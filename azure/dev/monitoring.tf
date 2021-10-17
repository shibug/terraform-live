# -----------------------------
# SUBNETS
# -----------------------------
resource "azurerm_subnet" "shared" {
  name                 = "shared-subnet"
  resource_group_name  = azurerm_resource_group.useast2.name
  virtual_network_name = azurerm_virtual_network.useast2.name
  address_prefixes     = ["10.0.0.0/27"]
}

# -----------------------------
# NETWORK SECURITY GROUPS
# -----------------------------
resource "azurerm_network_security_group" "shared" {
  name                = "nsg-shared"
  location            = azurerm_resource_group.useast2.location
  resource_group_name = azurerm_resource_group.useast2.name
  tags                = local.shared_tags
}

resource "azurerm_subnet_network_security_group_association" "shared" {
  subnet_id                 = azurerm_subnet.shared.id
  network_security_group_id = azurerm_network_security_group.shared.id
}

# --------------------------------------------------
# NETWORK SECURITY RULES
# --------------------------------------------------
# Allow ssh port access from Internet
resource "azurerm_network_security_rule" "sharedInboundInternetAllow" {
  name                        = "IInternetA"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_ranges     = ["80", "1122", "9090"]
  resource_group_name         = azurerm_resource_group.useast2.name
  network_security_group_name = azurerm_network_security_group.shared.name
}

# -----------------------------
# PUBLIC IPS
# -----------------------------
resource "azurerm_public_ip" "shared" {
  name                = "ip-shared"
  resource_group_name = azurerm_resource_group.useast2.name
  location            = azurerm_resource_group.useast2.location
  allocation_method   = "Static"
  tags                = local.shared_tags
}

# -----------------------------
# NETWORK INTERFACES
# -----------------------------
resource "azurerm_network_interface" "shared" {
  name                = "nic-shared"
  location            = azurerm_resource_group.useast2.location
  resource_group_name = azurerm_resource_group.useast2.name
  # enable_accelerated_networking = true
  internal_dns_name_label = "shared"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.shared.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.shared.id
  }

  tags = local.shared_tags
}

# ---------------------------------------------------------
# MANAGED DISK
# ---------------------------------------------------------
resource "azurerm_managed_disk" "shared" {
  name                 = "md-shared"
  location             = azurerm_resource_group.useast2.location
  resource_group_name  = azurerm_resource_group.useast2.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32

  lifecycle {
    prevent_destroy = true
  }
  
  tags = local.shared_tags
}

# -----------------------------
# VIRTUAL MACHINES
# -----------------------------
resource "azurerm_linux_virtual_machine" "shared" {
  name                = "use3lsharedprod"
  resource_group_name = azurerm_resource_group.useast2.name
  location            = azurerm_resource_group.useast2.location
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.shared.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "shared-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  custom_data = data.cloudinit_config.shared.rendered

  lifecycle {
    ignore_changes = [custom_data]
  }

  tags = local.shared_tags
}

# ------------------------------------
# VIRTUAL MACHINE DATA DISK ATTACHMENT
# ------------------------------------
resource "azurerm_virtual_machine_data_disk_attachment" "shared" {
  managed_disk_id    = azurerm_managed_disk.shared.id
  virtual_machine_id = azurerm_linux_virtual_machine.shared.id
  lun                = 1
  caching            = "ReadWrite"
}
