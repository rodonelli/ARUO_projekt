variable "location" {
  default = "westeurope"
}

variable "resource_group_name" {
  default = "rg-cloud-project"
}

# Certificate details
variable "certificate_pfx_password" {
  description = "Password for the SSL certificate PFX file"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!" # Change this if your appgw.pfx has a different password
}

variable "certificate_pfx_path" {
  description = "Path to the SSL certificate PFX file"
  type        = string
  default     = "./appgw.pfx" # UPDATED: Points to appgw.pfx
}

variable "allowed_admin_ip_ranges" {
  description = "Public IP ranges allowed for temporary administrative access to firewalled Azure PaaS resources. Replace the default with your public IP in CIDR format, for example 203.0.113.10/32."
  type        = list(string)
  default     = ["109.60.95.99/32"]
}

# PostgreSQL details
variable "postgres_admin_username" {
  default = "psqladmin"
}

# AGIC / App Gateway
variable "app_gw_name" {
  default = "app-gw-cloud-project"
}

variable "aks_name" {
  default = "aks-cloud-project"
}

variable "vnet_name" {
  default = "vnet-app"
}

variable "jump_vnet_name" {
  default = "vnet-jump"
}
# AKS Variables
variable "aks_node_count" {
  default = 1
}

variable "aks_node_vm_size" {
  default = "Standard_D2s_v3" # Changed from Standard_B2s
}


# Function App Variables
variable "function_app_name" {
  default = "func-cloud-project2"
}

variable "function_app_service_plan_sku_name" {
  description = "App Service Plan SKU for the Function App. B1 is used because lab policies often block Elastic Premium EP1."
  type        = string
  default     = "B1"
}

variable "create_file_sync_cloud_endpoint" {
  description = "Creates the Azure File Sync cloud endpoint for the file share. Disabled by default because the lab subscription blocks Storage Sync from reading firewalled storage accounts."
  type        = bool
  default     = false
}

# PostgreSQL Variables
variable "postgres_admin_password" {
  description = "Password for PostgreSQL"
  type        = string
  sensitive   = true
  default     = "YourStrongP@ssw0rd!" # Change this for production
}

variable "postgres_entra_admin_object_id" {
  description = "Object ID of the Microsoft Entra user or group that will administer PostgreSQL. Defaults to the identity running Terraform."
  type        = string
  default     = null
}

variable "postgres_entra_admin_principal_name" {
  description = "Display name or UPN of the Microsoft Entra PostgreSQL administrator."
  type        = string
  default     = "terraform-admin"
}

variable "postgres_entra_admin_principal_type" {
  description = "Microsoft Entra principal type for PostgreSQL administrator: User, Group, or ServicePrincipal."
  type        = string
  default     = "User"
}

variable "postgres_sku_name" {
  description = "SKU name for the PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms" # Correct format for Azure API
}



# Jump VM Variables
variable "jump_vm_size" {
  default = "Standard_B1s"
}

variable "jump_vm_username" {
  default = "azureuser"
}

variable "jump_vm_admin_password" {
  description = "Password for the Jump VM local administrator."
  type        = string
  sensitive   = true
  default     = "YourStr0ngP@ssw0rd!"
}

variable "allowed_rdp_source_prefixes" {
  description = "CIDR ranges allowed to RDP to the Jump VM. Replace the default with your public IP, for example 203.0.113.10/32."
  type        = list(string)
  default     = ["109.60.95.99/32"]
}

# Logging
variable "log_analytics_workspace_name" {
  default = "log-cloud-project"
}

# Application Gateway Ingress Controller (AGIC)
# Note: AGIC is often deployed via Helm after AKS is ready, 
# but we can define the Ingress Resource later.
