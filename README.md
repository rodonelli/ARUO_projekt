# Azure Cloud Administration Project

Terraform projekt za implementaciju sigurnije Azure infrastrukture prema kriterijima kolegija *Administering cloud solutions*. Rješenje koristi privatni pristup za ključne servise, segmentirane virtualne mreže, Application Gateway routing, AKS, Function App, PostgreSQL, Storage, Key Vault i centralizirani monitoring.

## Arhitektura

Glavne komponente:

- Resource Group: `rg-cloud-project`
- VNet za aplikaciju: `vnet-app`
- VNet za administraciju: `vnet-jump`
- Jump VM s ograničenim RDP pristupom
- Private AKS cluster
- Azure Container Registry s private endpointom
- Azure Key Vault s firewall pravilom `default_action = "Deny"`
- Storage Account s firewall pravilom `default_action = "Deny"`
- PostgreSQL Flexible Server bez javnog pristupa
- Linux Function App s private endpointom
- Application Gateway s path-based routingom
- Log Analytics Workspace, Azure Monitor Agent, Data Collection Rule i Workbook
- Azure File Sync service i sync group

Arhitekturni dijagram je u datoteci:

```text
architecture_diagram.md
```

## Mrežni dizajn

Projekt koristi dvije virtualne mreže:

- `vnet-app` za AKS, Function App, Application Gateway, PostgreSQL i private endpointove
- `vnet-jump` za Jump VM i administrativni pristup privatnim servisima

VNetovi su povezani peeringom. Servisi koji trebaju biti privatni koriste private endpointove i private DNS zone. Storage i Key Vault imaju firewall pravila s `default_action = "Deny"`.

RDP pristup Jump VM-u ograničen je varijablom:

```hcl
allowed_rdp_source_prefixes = ["YOUR_PUBLIC_IP/32"]
```

Administrativni pristup firewalled PaaS servisima ograničen je varijablom:

```hcl
allowed_admin_ip_ranges = ["YOUR_PUBLIC_IP/32"]
```

## Application Gateway Routing

Application Gateway koristi HTTPS listener i path-based routing:

- `/aks/*` ide prema AKS backendu
- `/functionapp/*` ide prema Function App backendu
- `/functionap/*` je dodan kao alternativni path zbog kriterija/provjere

TLS certifikat se učitava iz lokalnog PFX certifikata i sprema u Key Vault.

## Certifikat

Terraform koristi lokalni certifikat:

```text
appgw.pfx
```

Putanja je definirana u `variables.tf`:

```hcl
certificate_pfx_path = "./appgw.pfx"
```

PFX sadrži privatni ključ. Za javni GitHub repo preporuka je ne commitati `appgw.pfx`, nego ga generirati lokalno ili priložiti samo u privatnoj predaji ako je riječ o demo/self-signed certifikatu.

## Preduvjeti

Potrebno je imati instalirano:

- Terraform
- Azure CLI
- kubectl
- Python 3 za Python resource inventory skriptu

Prijava u Azure:

```powershell
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

Ako novi subscription nema registriran Storage Sync provider:

```powershell
az provider register --namespace Microsoft.StorageSync
az provider show --namespace Microsoft.StorageSync --query registrationState -o tsv
```

## Konfiguracija

Prije pokretanja promijeniti u `variables.tf`:

```hcl
allowed_admin_ip_ranges     = ["YOUR_PUBLIC_IP/32"]
allowed_rdp_source_prefixes = ["YOUR_PUBLIC_IP/32"]
```

Po potrebi promijeniti subscription u `main.tf`:

```hcl
subscription_id = "<SUBSCRIPTION_ID>"
```

Function App plan koristi varijablu:

```hcl
function_app_service_plan_sku_name = "B1"
```

Ako lab policy ne dopušta `B1`, promijeniti na dopušteni SKU.

## Deployment

Pokretanje Terraform deploymenta:

```powershell
terraform init
terraform plan
terraform apply
```

Ako Terraform koristi lokalni CLI config iz projekta:

```powershell
$env:TF_CLI_CONFIG_FILE = "$PWD\terraform.rc"
terraform plan
terraform apply
```

## Azure File Sync napomena

Projekt definira:

- Storage Sync Service
- Sync Group
- File Share

Cloud endpoint je parametriziran:

```hcl
create_file_sync_cloud_endpoint = false
```

Razlog: u lab subscriptionu Storage Sync cloud endpoint može biti blokiran kada Storage Account ima firewall `default_action = "Deny"`. Time se čuva sigurnosni kriterij za Storage privatni pristup, a Terraform deployment može završiti.

Ako okolina dopušta cloud endpoint, postaviti:

```hcl
create_file_sync_cloud_endpoint = true
```

## Deployment aplikacije na AKS

Skripta:

```powershell
.\deploy_app.ps1
```

Skripta ne koristi ACR admin credentials. Koristi Azure login i ACR build/import, a AKS povlači image preko managed identity i `AcrPull` role assignmenta.

Za privatni AKS cluster skriptu pokrenuti s Jump VM-a ili računala koje može pristupiti privatnom AKS API endpointu.

## Deployment Function App koda

Skripta:

```powershell
.\deploy_function_app.ps1
```

Ako ne postoji lokalni source folder, skripta generira minimalni HTTP trigger, zapakira ga u zip i deploya na Function App.

Za privatni Function App deployment pokrenuti iz mreže koja ima pristup privatnom endpointu.

## Popis resursa

Azure CLI dokaz:

```powershell
.\list_resources_azcli.ps1
```

Python dokaz:

```powershell
python -m pip install -r requirements.txt
python .\list_resources_python.py --subscription-id "<SUBSCRIPTION_ID>"
```

Skripte spremaju rezultate u mapu `evidence`.

## PostgreSQL pristup

PostgreSQL je privatan i koristi:

- password authentication
- Microsoft Entra authentication
- private DNS zonu povezanu s `vnet-app` i `vnet-jump`

Pomoćna skripta za testiranje:

```powershell
.\test_postgresql_access.ps1
```

Pokrenuti s Jump VM-a i spremiti screenshot `psql` sesije kao dokaz.

## Monitoring

Monitoring uključuje:

- Log Analytics Workspace
- Azure Monitor Agent na Jump VM-u
- Data Collection Rule za performance countere i Windows event logove
- Storage blob diagnostic logs za `StorageRead`, `StorageWrite`, `StorageDelete`
- Key Vault audit logs
- PostgreSQL logs
- Log Analytics Workbook s KQL upitima

Workbook sadrži CPU vizualizaciju za Jump VM i dodatne KQL panele za sigurnosne evente, Storage blob operacije i PostgreSQL logove.


## Datoteke

- `main.tf` - Terraform provider, subscription, lokalne vrijednosti i tagovi
- `networking.tf` - resource group, VNetovi, subneti, peering i public IP adrese
- `identity.tf` - managed identities
- `iam.tf` - role assignmenti
- `acr.tf` - Azure Container Registry i private endpoint
- `aks.tf` - private AKS cluster
- `app_gateway.tf` - Application Gateway i path-based routing
- `function_app.tf` - Linux Function App i private endpoint
- `keyvault.tf` - Key Vault, certifikat i private endpoint
- `storage.tf` - Storage Account, private endpointi, File Share i Azure File Sync
- `postgresql.tf` - PostgreSQL Flexible Server i Entra administrator
- `monitoring.tf` - Log Analytics, diagnostics, DCR, AMA i Workbook
- `deploy_app.ps1` - deployment aplikacije na AKS
- `deploy_function_app.ps1` - deployment Function App koda
- `list_resources_azcli.ps1` - popis resursa preko Azure CLI-ja
- `list_resources_python.py` - popis resursa preko Python SDK-a
- `test_postgresql_access.ps1` - pomoć za dokaz pristupa bazi
- `architecture_diagram.md` - Dijagram Arhitekture
