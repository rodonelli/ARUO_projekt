# Data source to get current Azure context (Tenant ID, Object ID, etc.)
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                        = "kvcloudproject${random_id.suffix.hex}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  # CRITICAL FIX: Allow Azure Services to bypass firewall for AGW access
  network_acls {
    default_action = "Allow" 
    bypass         = "AzureServices" 
  }

  # --- FIX: Add access_policy for App Gateway Identity ---
  # Using the nested block structure as per the provided documentation
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.appgw.principal_id

    certificate_permissions = [
      "Get",
      "List",
    ]

    secret_permissions = [
      "Get",
      "List",
    ]
  }

  # Existing Access Policy for Terraform/User
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]

    certificate_permissions = [
      "Get", "List", "Delete", "Purge", "ManageContacts", "ManageIssuers", "Import"
    ]
  }

  tags = local.tags
}

# Upload SSL Certificate to Key Vault
resource "azurerm_key_vault_certificate" "ssl" {
  name         = "agick8-cert"
  key_vault_id = azurerm_key_vault.main.id

  certificate {
    contents = filebase64(var.certificate_pfx_path)
    password = var.certificate_pfx_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    
    lifetime_action {
      action {
        action_type = "AutoRenew"
      }
      trigger {
        days_before_expiry = 30
      }
    }

    x509_certificate_properties {
      subject            = "CN=agick8.local"
      validity_in_months = 12

      key_usage = [
        "digitalSignature",
        "keyEncipherment"
      ]

      subject_alternative_names {
        dns_names = ["agick8.local"]
      }

      extended_key_usage = [
        "1.3.6.1.5.5.7.3.2",
        "1.3.6.1.5.5.7.3.1"
      ]
    }
  }

  # FIXED: Only depend on existing resources
  depends_on = [
    azurerm_key_vault.main
  ]
}

# Generate and Store PostgreSQL Password Secret
resource "random_password" "postgres" {
  length  = 20
  special = false
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  key_vault_id = azurerm_key_vault.main.id
  value        = random_password.postgres.result
}

# Private Endpoint for Key Vault (Access from AGW Subnet)
resource "azurerm_private_endpoint" "kv" {
  name                = "pe-kv-aks"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id = azurerm_subnet.pe_appgw.id 
  
  private_service_connection {
    name                           = "psc-kv"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
  }

  tags = local.tags
}

# Private Endpoint for Key Vault (Access from Jump VM Subnet)
resource "azurerm_private_endpoint" "kv_jump" {
  name                = "pe-kv-jump"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.jump.id
  
  private_service_connection {
    name                           = "psc-kv-jump"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
  }

  tags = local.tags
}
