resource "azurerm_application_gateway" "main" {
  name                = var.app_gw_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "app-gw-ip-config"
    subnet_id = azurerm_subnet.agw.id
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "app-gw-public-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "aks-backend-pool"
  }

  backend_http_settings {
    name                  = "aks-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "aks-listener"
    frontend_ip_configuration_name = "app-gw-public-ip"
    frontend_port_name             = "https"
    protocol                       = "Https"
    ssl_certificate_name           = "app-gw-cert"
  }

  request_routing_rule {
    name                       = "aks-route-rule"
    rule_type                  = "Basic"
    http_listener_name         = "aks-listener"
    backend_address_pool_name  = "aks-backend-pool"
    backend_http_settings_name = "aks-http-settings"
    priority                   = 100
  }

  ssl_certificate {
    name                = "app-gw-cert"
    key_vault_secret_id = azurerm_key_vault_certificate.ssl.secret_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  tags = local.tags
}
