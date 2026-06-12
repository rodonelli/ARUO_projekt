# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# VNET 1: App Network
resource "azurerm_virtual_network" "app" {
  name                = var.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.1.0.0/16"]
  tags                = local.tags
}

# Subnets for App VNET
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.1.0.0/24"]
  
  # REMOVE the delegation block here
  # Delegation is handled by azurerm_kubernetes_cluster.main
  
  service_endpoints = ["Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
}


resource "azurerm_subnet" "function" {
  name                 = "function-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.1.2.0/24"]
  
  delegation {
    name = "psql-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}


resource "azurerm_subnet" "agw" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.1.3.0/24"]
}

# NEW: Dedicated subnet for Private Endpoints (cannot be delegated)
resource "azurerm_subnet" "storage_pe" {
  name                         = "storage-pe-subnet"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.app.name
  address_prefixes             = ["10.1.4.0/24"]
  private_endpoint_network_policies = "Disabled"
}

# VNET 2: Jump Network
resource "azurerm_virtual_network" "jump" {
  name                = var.jump_vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.2.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "jump" {
  name                 = "jump-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.jump.name
  address_prefixes     = ["10.2.0.0/24"]
}

# VNET Peering
resource "azurerm_virtual_network_peering" "app_to_jump" {
  name                      = "peering-app-to-jump"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.app.name
  remote_virtual_network_id = azurerm_virtual_network.jump.id
  
  # Ensure VNETs are done before peering
  depends_on = [
    azurerm_virtual_network.app,
    azurerm_virtual_network.jump,
    # Also depends on subnets if they trigger updates on the VNET
    azurerm_subnet.aks,
    azurerm_subnet.jump
  ]
}

resource "azurerm_virtual_network_peering" "jump_to_app" {
  name                      = "peering-jump-to-app"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.jump.name
  remote_virtual_network_id = azurerm_virtual_network.app.id
  
  depends_on = [
    azurerm_virtual_network.app,
    azurerm_virtual_network.jump,
    azurerm_subnet.aks,
    azurerm_subnet.jump
  ]
}

# Public IPs (Only 2 allowed)
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_public_ip" "jump" {
  name                = "pip-jump"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_subnet" "pe_appgw" {
  name                         = "pe-appgw-subnet"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.app.name
  address_prefixes             = ["10.1.5.0/24"]
  private_endpoint_network_policies = "Disabled"
}