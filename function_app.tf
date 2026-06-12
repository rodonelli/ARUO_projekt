resource "azurerm_service_plan" "main" {
  name                = "sp-${var.function_app_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "Y1"
  
  tags = local.tags
}

resource "azurerm_linux_function_app" "main" {
  name                = var.function_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  
  service_plan_id = azurerm_service_plan.main.id

  # site_config block is required, even if minimal
  site_config {
    # linux_fx_version is automatic
    always_on = false 
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "AzureWebJobsStorage"      = azurerm_storage_account.main.primary_connection_string
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
