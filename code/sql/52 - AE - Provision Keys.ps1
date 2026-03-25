# Always Encrypted - Provision Column Encryption Key
# This script uses the SqlServer and Az PowerShell modules to
# generate a CEK and wrap it with the CMK in Azure Key Vault.
#
# Prerequisites:
#   Install-Module SqlServer
#   Install-Module Az.Accounts
#   Run 51 - AE - Setup Azure Key Vault.sh first to create the AKV resources.

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerName = "localhost,1433",

    [Parameter(Mandatory=$true)]
    [string]$DatabaseName = "AETest",

    [string]$SaPassword = "YourStrongPassword!",

    [Parameter(Mandatory=$true)]
    [string]$KeyVaultUrl,  # Full key URL from 51 - AE - Setup Azure Key Vault.sh output

    [Parameter(Mandatory=$true)]
    [string]$TenantId,

    [Parameter(Mandatory=$true)]
    [string]$ClientId,

    [Parameter(Mandatory=$true)]
    [string]$ClientSecret
)

# Install modules if not already available
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Write-Host "Installing SqlServer module..."
    Install-Module SqlServer -Force -AllowClobber -Scope CurrentUser
}
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Host "Installing Az.Accounts module..."
    Install-Module Az.Accounts -Force -AllowClobber -Scope CurrentUser
}

Import-Module SqlServer
Import-Module Az.Accounts

# Authenticate to Azure using the service principal
$secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($ClientId, $secureSecret)
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $TenantId

# Connect to SQL Server
$securePassword = ConvertTo-SecureString $SaPassword -AsPlainText -Force
$securePassword.MakeReadOnly()
$sqlCredential = New-Object System.Management.Automation.PSCredential("sa", $securePassword)
$database = Get-SqlDatabase -ServerInstance $ServerName -Name $DatabaseName -Credential $sqlCredential -TrustServerCertificate

if (-not $database) {
    Write-Error "Failed to connect to database '$DatabaseName' on '$ServerName'."
    exit 1
}

# Get an access token for Key Vault operations
$keyVaultToken = (Get-AzAccessToken -ResourceUrl "https://vault.azure.net").Token

# Create the Column Master Key metadata in SQL Server.
# This registers a pointer to the key in Azure Key Vault;
# SQL Server never accesses AKV directly.
Write-Host "Creating Column Master Key metadata..."
$cmkSettings = New-SqlColumnMasterKeySettings -KeyStoreProviderName "AZURE_KEY_VAULT" -KeyPath $KeyVaultUrl
New-SqlColumnMasterKey `
    -Name "AE_ColumnMasterKey" `
    -InputObject $database `
    -ColumnMasterKeySettings $cmkSettings

# Create the Column Encryption Key
# This generates a random symmetric key, wraps it using the CMK in AKV,
# and stores the encrypted value in SQL Server metadata.
Write-Host "Creating Column Encryption Key..."
New-SqlColumnEncryptionKey `
    -Name "AE_ColumnEncryptionKey" `
    -InputObject $database `
    -ColumnMasterKey "AE_ColumnMasterKey" `
    -KeyVaultAccessToken $keyVaultToken

Write-Host ""
Write-Host "Column Encryption Key created successfully."
Write-Host "You can now run script 53 to create the encrypted table."
Write-Host ""
Write-Host "To connect from SSMS with decryption:"
Write-Host "  Connection dialog > Options > Additional Connection Parameters"
Write-Host "  Add: Column Encryption Setting=enabled"
