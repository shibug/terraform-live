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
  }

  tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "theta-edge" {
  name                = "vm-theta-edge"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "groot"
  network_interface_ids = [
    azurerm_network_interface.theta-edge.id,
  ]

  admin_ssh_key {
    username   = "groot"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "theta-edge-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }

  tags = local.common_tags
}