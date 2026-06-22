# Get resource IDs
data "azurerm_subscription" "current" {}

# 1. AKS Identity -> ACR (AcrPull)
resource "azurerm_role_assignment" "aks_to_acr" {
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  scope                = azurerm_container_registry.main.id
  depends_on           = [azurerm_container_registry.main]
}

# 2. AKS Identity -> Storage (Blob & File Data Contributor)
resource "azurerm_role_assignment" "aks_to_storage_blob" {
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  scope                = azurerm_storage_account.main.id
  depends_on           = [azurerm_storage_account.main]
}

resource "azurerm_role_assignment" "aks_to_storage_file" {
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  scope                = azurerm_storage_account.main.id
  depends_on           = [azurerm_storage_account.main]
}

# 3. AKS Identity -> Key Vault (Secrets User)
resource "azurerm_role_assignment" "aks_to_kv_secrets" {
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  scope                = azurerm_key_vault.main.id
  depends_on           = [azurerm_key_vault.main]
}

# 4. Pod Identity -> ACR (AcrPull)
resource "azurerm_role_assignment" "pod_to_acr" {
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.pod.principal_id
  scope                = azurerm_container_registry.main.id
  depends_on           = [azurerm_container_registry.main]
}

# 5. Pod Identity -> Storage (Blob & File Data Contributor)
resource "azurerm_role_assignment" "pod_to_storage_blob" {
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.pod.principal_id
  scope                = azurerm_storage_account.main.id
  depends_on           = [azurerm_storage_account.main]
}

resource "azurerm_role_assignment" "pod_to_storage_file" {
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_user_assigned_identity.pod.principal_id
  scope                = azurerm_storage_account.main.id
  depends_on           = [azurerm_storage_account.main]
}

# 6. Pod Identity -> Key Vault (Secrets User)
resource "azurerm_role_assignment" "pod_to_kv_secrets" {
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.pod.principal_id
  scope                = azurerm_key_vault.main.id
  depends_on           = [azurerm_key_vault.main]
}

# 7. App Gateway Identity -> Key Vault (Certificates Officer & Secrets User)
resource "azurerm_role_assignment" "appgw_to_kv_cert" {
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
  scope                = azurerm_key_vault.main.id
  depends_on           = [azurerm_key_vault.main]
}

resource "azurerm_role_assignment" "appgw_to_kv_secrets" {
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
  scope                = azurerm_key_vault.main.id
  depends_on           = [azurerm_key_vault.main]
}

# 8. Your User (Terraform Provider) -> Contributor on Resource Group
resource "azurerm_role_assignment" "terraform_to_rg" {
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_resource_group.main.id
  depends_on           = [azurerm_resource_group.main]
}

# 9. Your User (Terraform Provider) -> Storage Data Roles (Explicitly needed for Containers/Shares)
resource "azurerm_role_assignment" "terraform_to_storage_blob_data" {
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_storage_account.main.id
  depends_on           = [azurerm_storage_account.main]
}

resource "azurerm_role_assignment" "terraform_to_storage_file_data" {
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_storage_account.main.id
  depends_on           = [azurerm_storage_account.main]
}

# 10. Your User (Terraform Provider) -> Storage Account Contributor for Azure File Sync cloud endpoint creation
resource "azurerm_role_assignment" "terraform_to_storage_account_contributor" {
  role_definition_name = "Storage Account Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_storage_account.main.id
  depends_on           = [azurerm_storage_account.main]
}

# 11. Your User (Terraform Provider) -> Key Vault Certificate Permissions
resource "azurerm_role_assignment" "terraform_to_kv_cert" {
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_key_vault.main.id
  depends_on           = [azurerm_key_vault.main]
}
