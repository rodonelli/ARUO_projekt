resource "azurerm_container_registry" "main" {
  name                = "acrcloudproject${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Premium"
  admin_enabled       = false
  tags                = local.tags

  # Removed network_rule_set to avoid v4 syntax errors
  # Access is handled via Private Endpoints below
}

# Private Endpoint for ACR (Access from AGW Subnet)
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id = azurerm_subnet.pe_appgw.id
  
  private_service_connection {
    name                           = "psc-acr"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
  }

  tags = local.tags
}

# Private Endpoint for ACR (Access from Jump VM Subnet)
resource "azurerm_private_endpoint" "acr_jump" {
  name                = "pe-acr-jump"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.jump.id
  
  private_service_connection {
    name                           = "psc-acr-jump"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
  }

  tags = local.tags
}
