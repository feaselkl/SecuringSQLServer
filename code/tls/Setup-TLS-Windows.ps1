# TLS Certificate Setup for SQL Server on Windows
# This script automates the TLS certificate configuration process
# that is shown in the presentation screenshots.
#
# Run as Administrator on the SQL Server machine.
# For demo purposes, this creates a self-signed certificate.
# In production, use an enterprise CA-issued certificate.

param(
    [string]$CertSubject = "SQL Server TLS Certificate",
    [string]$SqlServiceAccount = "NT Service\MSSQLSERVER",
    [string]$SqlInstanceName = "MSSQLSERVER",
    [int]$CertValidityYears = 2
)

$ErrorActionPreference = "Stop"

Write-Host "=== Step 1: Create Self-Signed Certificate ===" -ForegroundColor Cyan
$cert = New-SelfSignedCertificate `
    -Subject "CN=$CertSubject" `
    -DnsName $env:COMPUTERNAME, "localhost" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -KeySpec KeyExchange `
    -KeyLength 2048 `
    -KeyAlgorithm RSA `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears($CertValidityYears) `
    -FriendlyName $CertSubject

Write-Host "  Certificate created: $($cert.Thumbprint)"

Write-Host ""
Write-Host "=== Step 2: Grant SQL Server Service Account Access ===" -ForegroundColor Cyan

# Get the private key file path
$keyPath = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
$fullKeyPath = "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys\$keyPath"

# Grant read access to the SQL Server service account
$acl = Get-Acl $fullKeyPath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $SqlServiceAccount, "Read", "Allow")
$acl.AddAccessRule($rule)
Set-Acl $fullKeyPath $acl
Write-Host "  Granted Read access to $SqlServiceAccount"

Write-Host ""
Write-Host "=== Step 3: Configure SQL Server to Use the Certificate ===" -ForegroundColor Cyan

# Set the certificate thumbprint in SQL Server Configuration Manager via registry
$regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$SqlInstanceName\MSSQLServer\SuperSocketNetLib"

# Try to find the correct registry path for the instance
$instances = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "MSSQL\d+\.$SqlInstanceName" }

if ($instances) {
    $instancePath = ($instances | Select-Object -First 1).Name -replace "HKEY_LOCAL_MACHINE", "HKLM:"
    $regPath = "$instancePath\MSSQLServer\SuperSocketNetLib"
}

Set-ItemProperty -Path $regPath -Name "Certificate" -Value $cert.Thumbprint.ToLower()
Write-Host "  Certificate thumbprint set in registry"

Write-Host ""
Write-Host "=== Step 4: Enable Force Encryption ===" -ForegroundColor Cyan
Set-ItemProperty -Path $regPath -Name "ForceEncryption" -Value 1
Write-Host "  Force Encryption enabled"

Write-Host ""
Write-Host "=== Step 5: Restart SQL Server ===" -ForegroundColor Cyan
Write-Host "  Restarting SQL Server service..."
Restart-Service -Name $SqlInstanceName -Force
Write-Host "  SQL Server restarted"

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  TLS setup complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Certificate Thumbprint: $($cert.Thumbprint)"
Write-Host ""
Write-Host "To verify, connect in SSMS and check the connection"
Write-Host "properties: the Encrypt Connection property should"
Write-Host "show True, and you can verify with:"
Write-Host '  SELECT encrypt_option FROM sys.dm_exec_connections'
Write-Host '  WHERE session_id = @@SPID;'
Write-Host ""
Write-Host "For TLS 1.3 (SQL Server 2025), also check:"
Write-Host '  SELECT protocol_version FROM sys.dm_exec_connections'
Write-Host '  WHERE session_id = @@SPID;'
