resource "azurerm_storage_account" "main" {
  name                          = "stcloudproject${random_id.suffix.hex}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  access_tier                   = "Hot"
  public_network_access_enabled = true

  tags = local.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = local.storage_allowed_admin_ip_ranges
  }

}

resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_app" {
  name                  = "storage-blob-app-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.app.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_jump" {
  name                  = "storage-blob-jump-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.jump.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_app" {
  name                  = "storage-file-app-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = azurerm_virtual_network.app.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_jump" {
  name                  = "storage-file-jump-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = azurerm_virtual_network.jump.id
  registration_enabled  = false
}

resource "azurerm_storage_container" "blob" {
  name = "blob-data"
  # FIX: Use storage_account_id instead of storage_account_name
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"

  depends_on = [
    azurerm_private_endpoint.storage_blob,
    azurerm_private_endpoint.storage_blob_jump
  ]
}

resource "azurerm_storage_share" "files" {
  name = "file-share"
  # FIX: Use storage_account_id instead of storage_account_name
  storage_account_id = azurerm_storage_account.main.id
  quota              = 50

  depends_on = [
    azurerm_private_endpoint.storage_file,
    azurerm_private_endpoint.storage_file_jump
  ]
}

# Private Endpoint for Blob Storage (Using dedicated subnet)
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-storage-blob"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.storage_pe.id

  private_service_connection {
    name                           = "psc-storage-blob"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-blob-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }

  tags = local.tags
}

# Private Endpoint for File Storage (Using dedicated subnet)
resource "azurerm_private_endpoint" "storage_file" {
  name                = "pe-storage-file"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.storage_pe.id

  private_service_connection {
    name                           = "psc-storage-file"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "storage-file-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_file.id]
  }

  tags = local.tags
}

# Private Endpoints for Jump VM to access Storage
resource "azurerm_private_endpoint" "storage_blob_jump" {
  name                = "pe-storage-blob-jump"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.jump.id

  private_service_connection {
    name                           = "psc-storage-blob-jump"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-blob-jump-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }

  tags = local.tags
}

resource "azurerm_private_endpoint" "storage_file_jump" {
  name                = "pe-storage-file-jump"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.jump.id

  private_service_connection {
    name                           = "psc-storage-file-jump"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "storage-file-jump-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_file.id]
  }

  tags = local.tags
}

resource "azurerm_storage_sync" "main" {
  name                = "sync-cloud-project"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

resource "azurerm_storage_sync_group" "main" {
  name            = "sync-group-cloud-project"
  storage_sync_id = azurerm_storage_sync.main.id
}

resource "azurerm_storage_sync_cloud_endpoint" "files" {
  count = var.create_file_sync_cloud_endpoint ? 1 : 0

  name                  = "cloud-endpoint-file-share"
  storage_sync_group_id = azurerm_storage_sync_group.main.id
  file_share_name       = azurerm_storage_share.files.name
  storage_account_id    = azurerm_storage_account.main.id

  depends_on = [
    azurerm_storage_share.files,
    azurerm_role_assignment.terraform_to_storage_account_contributor,
    azurerm_role_assignment.terraform_to_storage_file_data
  ]
}
