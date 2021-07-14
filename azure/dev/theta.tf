# -----------------------------
# NETWORK INTERFACES
# -----------------------------

resource "azurerm_network_interface" "theta-edge" {
  name                = "nic-theta-edge"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  #  enable_accelerated_networking = true
  internal_dns_name_label = "theta-edge"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.worker.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.theta-edge.id
  }

  tags = local.theta_tags
}

# -----------------------------
# VIRTUAL MACHINES
# -----------------------------
resource "azurerm_windows_virtual_machine" "theta-edge" {
  name                = "vm-theta-edge"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = var.windows_admin_password
  network_interface_ids = [
    azurerm_network_interface.theta-edge.id,
  ]

  os_disk {
    name                 = "theta-edge-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.theta_tags
}
