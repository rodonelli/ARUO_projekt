# Managed Identities

# 1. AKS Node Pool Identity (User-Assigned)
resource "azurerm_user_assigned_identity" "aks" {
  name                = "mi-aks-nodepool"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

# 2. App Gateway Identity (User-Assigned)
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "mi-appgw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

# 3. Pod Identity (Azure AD Pod Identity)
resource "azurerm_user_assigned_identity" "pod" {
  name                = "mi-pod-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}
