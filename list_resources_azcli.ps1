param(
    [string]$ResourceGroup = "rg-cloud-project",
    [string]$OutputDirectory = ".\evidence"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
}

$JsonPath = Join-Path $OutputDirectory "resources-azcli.json"
$TablePath = Join-Path $OutputDirectory "resources-azcli.txt"

Write-Host "Listing Azure resources in resource group '$ResourceGroup'..." -ForegroundColor Cyan

az resource list `
    --resource-group $ResourceGroup `
    --query "[].{name:name,type:type,location:location,resourceGroup:resourceGroup,id:id}" `
    --output json | Set-Content -Path $JsonPath -Encoding UTF8

az resource list `
    --resource-group $ResourceGroup `
    --query "[].{Name:name,Type:type,Location:location}" `
    --output table | Set-Content -Path $TablePath -Encoding UTF8

Write-Host "Saved:" -ForegroundColor Green
Write-Host "  $JsonPath"
Write-Host "  $TablePath"
