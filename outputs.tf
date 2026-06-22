output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.main.default_hostname
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "postgresql_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}
