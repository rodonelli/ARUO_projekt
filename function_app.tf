resource "azurerm_service_plan" "main" {
  name                = "sp-${var.function_app_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.function_app_service_plan_sku_name

  tags = local.tags
}

resource "azurerm_linux_function_app" "main" {
  name                          = var.function_app_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  storage_account_name          = azurerm_storage_account.main.name
  storage_account_access_key    = azurerm_storage_account.main.primary_access_key
  public_network_access_enabled = false
  https_only                    = true

  service_plan_id           = azurerm_service_plan.main.id
  virtual_network_subnet_id = azurerm_subnet.function.id

  site_config {
    always_on              = true
    vnet_route_all_enabled = true

    application_stack {
      node_version = "18"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "node"
    "AzureWebJobsStorage"          = azurerm_storage_account.main.primary_connection_string
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    "WEBSITE_CONTENTOVERVNET"      = "1"
    "WEBSITE_RUN_FROM_PACKAGE"     = "1"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_private_dns_zone" "function_app" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "function_app_app" {
  name                  = "function-app-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.function_app.name
  virtual_network_id    = azurerm_virtual_network.app.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "function_app_jump" {
  name                  = "function-jump-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.function_app.name
  virtual_network_id    = azurerm_virtual_network.jump.id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "function_app" {
  name                = "pe-function-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.pe_appgw.id

  private_service_connection {
    name                           = "psc-function-app"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_function_app.main.id
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "function-app-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.function_app.id]
  }

  tags = local.tags
}
