param(
    [string]$ResourceGroup = "rg-cloud-project",
    [string]$ServerName = "psql-cloud-project",
    [string]$DatabaseName = "postgres",
    [string]$AdminUser = "psqladmin"
)

$ErrorActionPreference = "Stop"

Write-Host "Resolving PostgreSQL private FQDN..." -ForegroundColor Cyan
$Fqdn = az postgres flexible-server show `
    --resource-group $ResourceGroup `
    --name $ServerName `
    --query "fullyQualifiedDomainName" `
    -o tsv

if ([string]::IsNullOrWhiteSpace($Fqdn)) {
    throw "Could not resolve PostgreSQL FQDN."
}

Write-Host ""
Write-Host "Password authentication test:" -ForegroundColor Yellow
Write-Host "  psql `"host=$Fqdn port=5432 dbname=$DatabaseName user=$AdminUser sslmode=require`""

Write-Host ""
Write-Host "Microsoft Entra authentication test:" -ForegroundColor Yellow
Write-Host "  `$env:PGPASSWORD = az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv"
Write-Host "  psql `"host=$Fqdn port=5432 dbname=$DatabaseName user=<entra-upn> sslmode=require`""

Write-Host ""
Write-Host "Run these from the Jump VM, then capture the psql session output as evidence." -ForegroundColor Green
