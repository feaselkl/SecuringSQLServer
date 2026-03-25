# Always Encrypted - Provision Column Encryption Key
# This script uses the SqlServer and Az PowerShell modules to
# generate a CEK and wrap it with the CMK in Azure Key Vault.
#
# Prerequisites:
#   Install-Module SqlServer
#   Install-Module Az.Accounts
#   Run 50 - AE - Setup Azure Key Vault.sh first to create the AKV resources.

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerName = "localhost,1433",

    [Parameter(Mandatory=$true)]
    [string]$DatabaseName = "AETest",

    [string]$SaPassword = "SecureSQLServer2025!",

    [Parameter(Mandatory=$true)]
    [string]$KeyVaultUrl,  # Full key URL from 50 - AE - Setup Azure Key Vault.sh output

    [Parameter(Mandatory=$true)]
    [string]$TenantId,

    [Parameter(Mandatory=$true)]
    [string]$ClientId,

    [Parameter(Mandatory=$true)]
    [string]$ClientSecret
)

Import-Module SqlServer
Import-Module Az.Accounts

# Authenticate to Azure using the service principal
$secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($ClientId, $secureSecret)
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $TenantId

# Connect to SQL Server
$connStr = "Server=$ServerName; Database=$DatabaseName; User Id=sa; Password=$SaPassword; TrustServerCertificate=True"
$database = Get-SqlDatabase -ConnectionString $connStr

# Get an access token for Key Vault operations
$keyVaultToken = (Get-AzAccessToken -ResourceUrl "https://vault.azure.net").Token

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
Write-Host "You can now run script 50 to create the encrypted table."
Write-Host ""
Write-Host "To connect from SSMS with decryption:"
Write-Host "  Connection dialog > Options > Additional Connection Parameters"
Write-Host "  Add: Column Encryption Setting=enabled"
