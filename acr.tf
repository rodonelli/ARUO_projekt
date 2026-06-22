resource "azurerm_container_registry" "main" {
  name                          = "acrcloudproject${random_id.suffix.hex}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = local.tags
  network_rule_bypass_option    = "AzureServices"
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_app" {
  name                  = "acr-app-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.app.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_jump" {
  name                  = "acr-jump-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.jump.id
  registration_enabled  = false
}

# Private Endpoint for ACR (Access from AGW Subnet)
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.pe_appgw.id

  private_service_connection {
    name                           = "psc-acr"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
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

  private_dns_zone_group {
    name                 = "acr-jump-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  tags = local.tags
}
