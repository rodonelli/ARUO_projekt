# NSG for Jump VM
resource "azurerm_network_security_group" "jump_nsg" {
  name                = "jump-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*" 
    destination_address_prefix = "*"
  }

  tags = local.tags
}

# Jump VM
resource "azurerm_windows_virtual_machine" "jump" {
  name                  = "jump-vm"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.jump_vm_size
  admin_username        = var.jump_vm_username
  admin_password        = "YourStr0ngP@ssw0rd!" # Change this
  network_interface_ids = [azurerm_network_interface.jump.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }


  tags = local.tags
}

resource "azurerm_network_interface" "jump" {
  name                = "jump-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jump.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump.id
  }

  tags = local.tags
}

resource "azurerm_network_interface_security_group_association" "jump_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.jump.id
  network_security_group_id = azurerm_network_security_group.jump_nsg.id
}
