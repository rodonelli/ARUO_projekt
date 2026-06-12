# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "psql-${random_id.suffix.hex}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

# Link the Private DNS Zone to the App VNET
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "postgresql-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.app.id
  depends_on            = [azurerm_subnet.db]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-cloud-project"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  version             = "14"
  administrator_login = var.postgres_admin_username
  administrator_password = var.postgres_admin_password
  sku_name            = var.postgres_sku_name
  storage_mb          = 32768
  zone                = "1"

  # The subnet must be delegated to Microsoft.DBforPostgreSQL/flexibleServers
  delegated_subnet_id  = azurerm_subnet.db.id
  
  # Link the Private DNS Zone created above
  private_dns_zone_id  = azurerm_private_dns_zone.postgresql.id
  
  # CRITICAL FIX: Must be false when using delegated subnets or private endpoints
  public_network_access_enabled = false

  # FIX: Add Backup Configuration for LO4
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = local.tags
}
