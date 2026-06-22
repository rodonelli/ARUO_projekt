# --- Log Analytics Workspace ---
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

# --- Diagnostic Settings for Storage Account Metrics ---
resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  name                       = "storage-account-diag"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_metric {
    category = "AllMetrics"
  }
}

# --- Diagnostic Settings for Blob Access Logs ---
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "storage-blob-diag"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

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

# --- Azure Monitor Agent and Data Collection for Jump VM ---
resource "azurerm_virtual_machine_extension" "jump_ama" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.jump.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  tags = local.tags
}

resource "azurerm_monitor_data_collection_rule" "jump_vm" {
  name                = "dcr-jump-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kind                = "Windows"

  destinations {
    log_analytics {
      name                  = "log-analytics"
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
    }
  }

  data_sources {
    performance_counter {
      name                          = "windows-performance"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\% Free Space"
      ]
    }

    windows_event_log {
      name    = "windows-security-events"
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Security!*[System[(band(Keywords,13510798882111488))]]",
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "System!*[System[(Level=1 or Level=2 or Level=3)]]"
      ]
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Event"]
    destinations = ["log-analytics"]
  }

  tags = local.tags
}

resource "azurerm_monitor_data_collection_rule_association" "jump_vm" {
  name                    = "dcr-association-jump-vm"
  target_resource_id      = azurerm_windows_virtual_machine.jump.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.jump_vm.id
}

resource "random_uuid" "workbook" {}

resource "azurerm_application_insights_workbook" "main" {
  name                = random_uuid.workbook.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  display_name        = "Cloud Project Monitoring Workbook"
  source_id           = lower(azurerm_log_analytics_workspace.main.id)
  category            = "workbook"

  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json = "# Cloud Project Monitoring\nWorkbook for VM CPU, security events, PostgreSQL logs, and Storage blob access logs."
        }
        name = "title"
      },
      {
        type = 3
        content = {
          version       = "KqlItem/1.0"
          query         = "Perf\n| where Computer has \"jump-vm\"\n| where ObjectName == \"Processor\" and CounterName == \"% Processor Time\" and InstanceName == \"_Total\"\n| summarize AvgCPU = avg(CounterValue) by bin(TimeGenerated, 5m)\n| render timechart"
          size          = 0
          title         = "Jump VM CPU usage"
          queryType     = 0
          resourceType  = "microsoft.operationalinsights/workspaces"
          visualization = "timechart"
        }
        name = "jump-vm-cpu"
      },
      {
        type = 3
        content = {
          version       = "KqlItem/1.0"
          query         = "Event\n| where EventLog == \"Security\"\n| summarize Events = count() by EventID, bin(TimeGenerated, 1h)\n| order by TimeGenerated desc"
          size          = 0
          title         = "Jump VM security events"
          queryType     = 0
          resourceType  = "microsoft.operationalinsights/workspaces"
          visualization = "table"
        }
        name = "security-events"
      },
      {
        type = 3
        content = {
          version       = "KqlItem/1.0"
          query         = "StorageBlobLogs\n| where OperationName has_any (\"GetBlob\", \"PutBlob\", \"DeleteBlob\")\n| summarize Operations = count() by OperationName, bin(TimeGenerated, 1h)\n| render columnchart"
          size          = 0
          title         = "Storage blob read/write/delete operations"
          queryType     = 0
          resourceType  = "microsoft.operationalinsights/workspaces"
          visualization = "barchart"
        }
        name = "storage-blob-access"
      },
      {
        type = 3
        content = {
          version       = "KqlItem/1.0"
          query         = "AzureDiagnostics\n| where ResourceProvider == \"MICROSOFT.DBFORPOSTGRESQL\"\n| summarize LogEvents = count() by Category, bin(TimeGenerated, 1h)\n| order by TimeGenerated desc"
          size          = 0
          title         = "PostgreSQL diagnostic logs"
          queryType     = 0
          resourceType  = "microsoft.operationalinsights/workspaces"
          visualization = "table"
        }
        name = "postgresql-logs"
      }
    ]
    styleSettings = {}
    isLocked      = false
    fallbackResourceIds = [
      lower(azurerm_log_analytics_workspace.main.id)
    ]
  })

  tags = local.tags
}
