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

# PostgreSQL Variables
variable "postgres_admin_password" {
  description = "Password for PostgreSQL"
  type        = string
  sensitive   = true
  default     = "YourStrongP@ssw0rd!" # Change this for production
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

# Logging
variable "log_analytics_workspace_name" {
  default = "log-cloud-project"
}

# Application Gateway Ingress Controller (AGIC)
# Note: AGIC is often deployed via Helm after AKS is ready, 
# but we can define the Ingress Resource later.
