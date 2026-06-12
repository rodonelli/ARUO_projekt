# deploy_app.ps1
# Run this script AFTER terraform apply has finished.

# --- CONFIGURATION ---
$RESOURCE_GROUP = "rg-cloud-project"
$AKS_NAME = "aks-cloud-project"
$NAMESPACE = "cloud-app"
$ACR_NAME = "acrcloudproject1d2f5375" # Updated to your actual ACR name

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting AKS Application Deployment..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Get AKS Credentials
Write-Host "1. Getting AKS credentials..." -ForegroundColor Yellow
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get AKS credentials. Ensure AKS is deployed and you are logged in." -ForegroundColor Red
    exit 1
}

# 2. Verify kubectl connection
Write-Host "2. Verifying kubectl connection..." -ForegroundColor Yellow
kubectl get nodes
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: kubectl is not configured correctly." -ForegroundColor Red
    exit 1
}

# 3. Create Namespace
Write-Host "3. Creating namespace '$NAMESPACE'..." -ForegroundColor Yellow
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 4. Get ACR Credentials for Kubernetes Secret
Write-Host "4. Configuring ACR Authentication Secret..." -ForegroundColor Yellow

# Get ACR Password
$ACR_PASSWORD = az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv
# Get ACR Username
$ACR_USER = az acr credential show --name $ACR_NAME --query "username" -o tsv

# Create the Kubernetes Secret using kubectl
# This allows the AKS cluster to pull images from your private ACR
kubectl create secret docker-registry acr-secret `
    --docker-server="$ACR_NAME.azurecr.io" `
    --docker-username="$ACR_USER" `
    --docker-password="$ACR_PASSWORD" `
    --namespace=$NAMESPACE `
    --dry-run=client -o yaml | kubectl apply -f -

if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Could not create ACR Secret. Ensure ACR name is correct and Admin is enabled." -ForegroundColor Yellow
    Write-Host "Run: az acr update -n $ACR_NAME --admin-enabled true" -ForegroundColor Yellow
}

# 5. Deploy Example App (Nginx)
Write-Host "5. Deploying Nginx Example App..." -ForegroundColor Yellow

# Note: Fixed YAML indentation for 'imagePullSecrets'
$k8s_manifest = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: $NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      imagePullSecrets:
        - name: acr-secret
      containers:
      - name: nginx
        image: $ACR_NAME.azurecr.io/nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: $NAMESPACE
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
"@

# Apply the manifest
$k8s_manifest | kubectl apply -f -

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to deploy Nginx app. Check YAML syntax." -ForegroundColor Red
    exit 1
}

# 6. Verify Deployment
Write-Host "6. Verifying Deployment Status..." -ForegroundColor Yellow
kubectl get pods -n $NAMESPACE -w
$pid = $LASTEXITCODE # Note: -w keeps the stream open, so we start a separate check

Write-Host "Fetching initial pod status..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
kubectl get pods -n $NAMESPACE

Write-Host "Fetching Service status..." -ForegroundColor Yellow
kubectl get svc -n $NAMESPACE

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Check the pods in the '$NAMESPACE' namespace." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
