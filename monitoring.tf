# --- Log Analytics Workspace ---
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

# --- Diagnostic Settings for Storage Account ---
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "storage-diag"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Omitted enabled_log due to API restrictions. Metrics are enabled.
  enabled_metric {
    category = "AllMetrics"
  }
}

# --- Diagnostic Settings for Key Vault ---
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "kv-diag"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }
  
  enabled_metric {
    category = "AllMetrics"
  }
}

# --- Diagnostic Settings for PostgreSQL ---
resource "azurerm_monitor_diagnostic_setting" "postgresql" {
  name                       = "psql-diag"
  target_resource_id         = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "PostgreSQLLogs"
  }
  
  enabled_metric {
    category = "AllMetrics"
  }
}

# --- Portal Dashboard for CPU Visualization ---
resource "azurerm_portal_dashboard" "main" {
  name                = "dashboard-main"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x       = 0
              y       = 0
              rowSpan = 4
              colSpan = 6
            }
            metadata = {
              inputs = [
                {
                  name    = "ComponentId"
                  value   = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/microsoft.compute/virtualMachines/${azurerm_windows_virtual_machine.jump.name}"
                }
              ]
              type               = "Extension/HubsExtension/PartType/VMWindowsPart"
              settings = {
                content = {
                  settings = {
                    content = ""
                  }
                }
              }
            }
          }
        }
      }
    }
    metadata = {
      model = {
        timeRange = {
          value = {
            relative = {
              duration = 24
              timeUnit = 1
            }
          }
          type = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        }
      }
    }
  })

  tags = local.tags
}
