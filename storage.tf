resource "azurerm_storage_account" "main" {
  name                     = "stcloudproject${random_id.suffix.hex}"
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  
  tags = local.tags

  network_rules {
    default_action             = "Allow" # Temporarily allow all
    bypass                     = ["AzureServices"]
  }

}

resource "azurerm_storage_container" "blob" {
  name                 = "blob-data"
  # FIX: Use storage_account_id instead of storage_account_name
  storage_account_id   = azurerm_storage_account.main.id
  container_access_type = "private"
  
  depends_on = [
    azurerm_private_endpoint.storage_blob,
    azurerm_private_endpoint.storage_blob_jump
  ]
}

resource "azurerm_storage_share" "files" {
  name                 = "file-share"
  # FIX: Use storage_account_id instead of storage_account_name
  storage_account_id   = azurerm_storage_account.main.id
  quota                = 50
  
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

  tags = local.tags
}
