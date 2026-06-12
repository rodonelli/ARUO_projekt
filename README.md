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
git clone https://github.com/[YOUR_USERNAME]/azure-project-tf.git
cd azure-project-tf
```

###2. Configure Variables

Review the variables.tf file. Ensure the following are set correctly:

    certificate_pfx_path: Path to your SSL certificate.
    certificate_pfx_password: Password for the SSL certificate.
    postgres_admin_password: A strong password for the PostgreSQL database.

###3. Initialize Terraform
bash

terraform init

###4. Plan the Deployment

Review the proposed changes to ensure they align with your expectations.
bash

terraform plan -out=tfplan

###5. Apply the Infrastructure
bash

terraform apply tfplan

###6. Post-Deployment Configuration (Manual Steps)

The following steps are required after Terraform applies to fully satisfy the "Compute" and "Networking" criteria:
####A. Build and Push Docker Image

    Get the ACR login server from the Azure Portal or CLI:
    bash

    az acr login --name [YOUR_ACR_NAME]

    Build and push your sample app image:
    bash

    docker build -t [YOUR_ACR_NAME].azurecr.io/sampleapp:latest .
    docker push [YOUR_ACR_NAME].azurecr.io/sampleapp:latest

####B. Install Application Gateway Ingress Controller (AGIC)

To enable traffic routing from the Application Gateway to AKS:

    Install the AGIC Helm chart into your AKS cluster.
    Create an Ingress Resource in Kubernetes pointing to your Sample App.

####C. Enable Auto-Patching (Optional but Recommended)

    Jump VM: Enable "Virtual Machine Patching" in the Azure Portal under "Updates" for the Jump VM.
    AKS: Enable auto_upgrade_channel in the node pool settings.

####D. Configure Azure File Sync (If Required)

If your project requires Azure File Sync, you must register the Jump VM as a server endpoint in the Azure Portal, as this is a complex manual configuration often left out of IaC for simplicity.
##📂 Project Structure
