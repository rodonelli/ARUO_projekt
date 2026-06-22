param(
    [string]$ResourceGroup = "rg-cloud-project",
    [string]$AksName = "aks-cloud-project",
    [string]$Namespace = "cloud-app",
    [string]$AcrName = "",
    [string]$ImageName = "cloud-app/nginx",
    [string]$ImageTag = "latest",
    [string]$DockerContext = ".\app",
    [string]$SourceImage = "mcr.microsoft.com/azuredocs/aks-helloworld:v1",
    [string]$SubscriptionId = "",
    [switch]$UseDirectKubectl
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [string]$Message,
        [scriptblock]$Command
    )

    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $Message"
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AKS application deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "For a private AKS cluster, the default mode uses 'az aks command invoke' so it can run without direct private API DNS access." -ForegroundColor Cyan

if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
    Invoke-Step "Selecting Azure subscription '$SubscriptionId'..." {
        az account set --subscription $SubscriptionId
    }
}

if ([string]::IsNullOrWhiteSpace($AcrName)) {
    $AcrName = az acr list --resource-group $ResourceGroup --query "[0].name" -o tsv
    if ([string]::IsNullOrWhiteSpace($AcrName)) {
        throw "Could not find an Azure Container Registry in resource group '$ResourceGroup'."
    }
}

$AcrLoginServer = az acr show --name $AcrName --query "loginServer" -o tsv
if ([string]::IsNullOrWhiteSpace($AcrLoginServer)) {
    throw "Could not resolve ACR login server for '$AcrName'."
}

$Image = "$AcrLoginServer/$ImageName`:$ImageTag"

if (Test-Path (Join-Path $DockerContext "Dockerfile")) {
    Invoke-Step "Building and pushing container image to ACR with az acr build..." {
        az acr build --registry $AcrName --image "$ImageName`:$ImageTag" $DockerContext
    }
}
else {
    Invoke-Step "No local Dockerfile found. Importing '$SourceImage' into private ACR as deployment evidence..." {
        az acr import `
            --name $AcrName `
            --source $SourceImage `
            --image "$ImageName`:$ImageTag" `
            --force
    }
}

$Manifest = @"
apiVersion: v1
kind: Namespace
metadata:
  name: $Namespace
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: $Namespace
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
      containers:
      - name: nginx
        image: $Image
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: $Namespace
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: $Namespace
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/backend-path-prefix: /
spec:
  rules:
  - http:
      paths:
      - path: /aks
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
"@

if ($UseDirectKubectl) {
    Invoke-Step "Getting AKS credentials..." {
        az aks get-credentials --resource-group $ResourceGroup --name $AksName --overwrite-existing
    }

    Invoke-Step "Verifying kubectl access..." {
        kubectl get nodes
    }

    Invoke-Step "Applying Kubernetes manifests..." {
        $Manifest | kubectl apply -f -
    }

    Invoke-Step "Waiting for rollout..." {
        kubectl rollout status deployment/nginx-deployment -n $Namespace --timeout=180s
    }

    Write-Host ""
    Write-Host "Deployment complete." -ForegroundColor Green
    kubectl get deploy,pods,svc,ingress -n $Namespace
}
else {
    $ManifestBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Manifest))
    $AksCommand = "echo $ManifestBase64 | base64 -d | kubectl apply -f - && kubectl rollout status deployment/nginx-deployment -n $Namespace --timeout=180s && kubectl get deploy,pods,svc,ingress -n $Namespace"

    Invoke-Step "Applying Kubernetes manifests through az aks command invoke..." {
        az aks command invoke `
            --resource-group $ResourceGroup `
            --name $AksName `
            --command $AksCommand
    }

    Write-Host ""
    Write-Host "Deployment complete." -ForegroundColor Green
}
