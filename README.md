# ARUO_projekt
Repository for my project files for Administering cloud solutions

## 🛠️ Prerequisites

Before deploying this infrastructure, ensure you have the following installed and configured:

*   **Terraform:** Version `>= 1.0` (Check current version with `terraform -v`).
*   **Azure CLI:** Latest version installed and logged in (`az login`).
*   **Helm:** Required for deploying the Application Gateway Ingress Controller (AGIC) to AKS post-deployment.
*   **Docker:** Required to build and push the sample application image to ACR.
*   **Azure Subscription:** With Contributor or Owner rights.
*   **SSL Certificate:** A `.pfx` file for the Application Gateway (placed in the root directory as `appgw.pfx`).

## 🚀 Deployment Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/rodonelli/azure-project-tf.git
cd azure-project-tf
```
### 2. Clone the Repository
Ensure that TenantID and SubscriptionID are valid in main.tf:
```
provider "azurerm" {
  tenant_id       = "YOUR TENANT ID
  subscription_id = "YOUR SUBSCRIPTION ID"
  
```
### 3. Configure Variables

Review the variables.tf file. Ensure the following are set correctly:
```
    certificate_pfx_path: Path to your SSL certificate.
    certificate_pfx_password: Password for the SSL certificate.
    postgres_admin_password: A strong password for the PostgreSQL database.
```
### 4. Initialize Terraform
```
terraform init
```
### 5. Plan the Deployment

Review the proposed changes to ensure they align with your expectations.
bash
```
terraform plan -out=tfplan
```
### 6. Apply the Infrastructure
bash
```
terraform apply tfplan
```
### 7. Post-Deployment Configuration (Manual Steps)

The following steps are required after Terraform applies to fully satisfy the "Compute" and "Networking" criteria:
#### A. Build and Push Docker Image
```
    Get the ACR login server from the Azure Portal or CLI:
    bash
```
```
    az acr login --name [YOUR_ACR_NAME]
```
```
    Build and push your sample app image:
    bash
```
```
    docker build -t [YOUR_ACR_NAME].azurecr.io/sampleapp:latest .
    docker push [YOUR_ACR_NAME].azurecr.io/sampleapp:latest
```
#### B. Install Application Gateway Ingress Controller (AGIC)

To enable traffic routing from the Application Gateway to AKS:

    Install the AGIC Helm chart into your AKS cluster.
    Create an Ingress Resource in Kubernetes pointing to your Sample App.

#### C. Enable Auto-Patching (Optional but Recommended)

    Jump VM: Enable "Virtual Machine Patching" in the Azure Portal under "Updates" for the Jump VM.
    AKS: Enable auto_upgrade_channel in the node pool settings.


## 📂 Project Structure
```
.
├── aks.tf                  # AKS Cluster, Node Pools, and Managed Identity
├── app_gateway.tf          # Application Gateway, Frontend/Backend Pools, SSL Cert
├── acr.tf                  # Azure Container Registry & Private Endpoints
├── function_app.tf         # Function App and Service Plan
├── iam.tf                  # RBAC Role Assignments (Least Privilege)
├── identity.tf             # User-Assigned Managed Identities
├── jump_vm.tf              # Jump VM, NSG, and NIC
├── keyvault.tf             # Key Vault, Certificates, Secrets, Private Endpoints
├── main.tf                 # Provider configuration and locals
├── monitoring.tf           # Log Analytics, Diagnostic Settings, Dashboard
├── networking.tf           # VNETs, Subnets, Peering, Public IPs
├── postgresql.tf           # PostgreSQL Flexible Server & Private DNS
├── storage.tf              # Storage Account, Containers, Shares, Private Endpoints
├── variables.tf            # Input variables
└── appgw.pfx               # SSL Certificate (Gitignored in .gitignore)
```

## 🔐 Security Notes
```
    Secrets: All secrets (passwords, keys) are handled via Terraform variables or Key Vault. Never commit .tfvars or secrets to the repository.
    Network Security: All services are accessed via Private Endpoints where possible. The Jump VM is the only entry point for management (RDP), restricted by NSG.
    Identities: Managed Identities are used for all service-to-service authentication following the Principle of Least Privilege.
```
