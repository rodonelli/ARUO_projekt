param(
    [string]$ResourceGroup = "rg-cloud-project",
    [string]$FunctionAppName = "func-cloud-project2",
    [string]$SourcePath = ".\function-src",
    [string]$PackagePath = ".\dist\function-app.zip",
    [string]$SubscriptionId = "",
    [string]$StorageAccountName = "",
    [string]$PackageContainer = "function-packages",
    [int]$SasExpiryDays = 30
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
Write-Host "Function App code deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "For a private Function App, run this from the Jump VM or another allowed administrative network path." -ForegroundColor Cyan

if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
    Invoke-Step "Selecting Azure subscription '$SubscriptionId'..." {
        az account set --subscription $SubscriptionId
    }
}

if (-not (Test-Path $SourcePath)) {
    Write-Host "No function source folder found. Creating a minimal HTTP-triggered Node.js function..." -ForegroundColor Yellow

    New-Item -ItemType Directory -Force -Path $SourcePath | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $SourcePath "HttpExample") | Out-Null

    @"
{
  "version": "2.0"
}
"@ | Set-Content -Path (Join-Path $SourcePath "host.json") -Encoding UTF8

    @"
{
  "scripts": {
    "start": "func start"
  },
  "dependencies": {}
}
"@ | Set-Content -Path (Join-Path $SourcePath "package.json") -Encoding UTF8

    @"
{
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": [ "get" ],
      "route": "health"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ]
}
"@ | Set-Content -Path (Join-Path $SourcePath "HttpExample\function.json") -Encoding UTF8

    @"
module.exports = async function (context, req) {
  context.res = {
    status: 200,
    body: {
      status: "ok",
      app: "cloud-project-function"
    }
  };
};
"@ | Set-Content -Path (Join-Path $SourcePath "HttpExample\index.js") -Encoding UTF8
}

$PackageDirectory = Split-Path $PackagePath -Parent
if (-not (Test-Path $PackageDirectory)) {
    New-Item -ItemType Directory -Force -Path $PackageDirectory | Out-Null
}

if (Test-Path $PackagePath) {
    Remove-Item $PackagePath -Force
}

Write-Host ""
Write-Host "Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path (Join-Path $SourcePath "*") -DestinationPath $PackagePath -Force

if ([string]::IsNullOrWhiteSpace($StorageAccountName)) {
    $StorageAccountName = az storage account list `
        --resource-group $ResourceGroup `
        --query "[?starts_with(name, 'stcloudproject')].name | [0]" `
        -o tsv

    if ([string]::IsNullOrWhiteSpace($StorageAccountName)) {
        throw "Could not find the project Storage Account in resource group '$ResourceGroup'."
    }
}

$PackageFullPath = (Resolve-Path $PackagePath).Path
$BlobName = "function-app-$((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')).zip"
$SasExpiry = (Get-Date).ToUniversalTime().AddDays($SasExpiryDays).ToString("yyyy-MM-ddTHH:mmZ")

$StorageAccountKey = az storage account keys list `
    --resource-group $ResourceGroup `
    --account-name $StorageAccountName `
    --query "[0].value" `
    -o tsv

if ([string]::IsNullOrWhiteSpace($StorageAccountKey)) {
    throw "Could not read a storage account key for '$StorageAccountName'."
}

Invoke-Step "Creating private package container '$PackageContainer'..." {
    az storage container create `
        --account-name $StorageAccountName `
        --account-key $StorageAccountKey `
        --name $PackageContainer `
        --public-access off `
        -o none
}

Invoke-Step "Uploading Function App package to Storage..." {
    az storage blob upload `
        --account-name $StorageAccountName `
        --account-key $StorageAccountKey `
        --container-name $PackageContainer `
        --name $BlobName `
        --file $PackageFullPath `
        --overwrite true `
        -o none
}

$SasToken = az storage blob generate-sas `
    --account-name $StorageAccountName `
    --account-key $StorageAccountKey `
    --container-name $PackageContainer `
    --name $BlobName `
    --permissions r `
    --expiry $SasExpiry `
    -o tsv

if ([string]::IsNullOrWhiteSpace($SasToken)) {
    throw "Could not generate a read SAS token for the Function App package."
}

$PackageUrl = "https://$StorageAccountName.blob.core.windows.net/$PackageContainer/$BlobName" + "?" + $SasToken
$SettingsPath = Join-Path $PackageDirectory "function-app-settings.json"

@{
    FUNCTIONS_WORKER_RUNTIME        = "node"
    WEBSITE_NODE_DEFAULT_VERSION    = "~18"
    SCM_DO_BUILD_DURING_DEPLOYMENT  = "false"
    ENABLE_ORYX_BUILD               = "false"
    WEBSITE_RUN_FROM_PACKAGE        = $PackageUrl
} | ConvertTo-Json | Set-Content -Path $SettingsPath -Encoding UTF8

$SettingsFileArgument = "@$((Resolve-Path $SettingsPath).Path)"

Invoke-Step "Configuring Function App to run from the uploaded package..." {
    az functionapp config appsettings set `
        --resource-group $ResourceGroup `
        --name $FunctionAppName `
        --settings $SettingsFileArgument `
        -o none
}

Invoke-Step "Restarting Function App..." {
    az functionapp restart `
        --resource-group $ResourceGroup `
        --name $FunctionAppName
}

Write-Host ""
Write-Host "Deployment complete. Test path: /api/health" -ForegroundColor Green
Write-Host "Package blob: $PackageContainer/$BlobName" -ForegroundColor Cyan
