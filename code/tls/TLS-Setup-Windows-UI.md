# Configuring TLS for SQL Server on Windows (UI Walkthrough)

This guide walks through configuring TLS encryption for SQL Server using the Windows UI. For a scripted approach, see [Setup-TLS-Windows.ps1](Setup-TLS-Windows.ps1) (PowerShell) or [setup-tls-linux.sh](setup-tls-linux.sh) (Linux).

> **Note:** This guide uses a self-signed certificate for demonstration purposes. In production, use a certificate issued by your enterprise Certificate Authority.

---

## Phase 1: Create a Certificate

### Open IIS Manager and navigate to Server Certificates

Open IIS Manager on the SQL Server machine. In the main pane, find and open **Server Certificates**.

![Server Certificates](../../presentation/assets/image/SSL%20Certificate/1%20-%20Server%20Certificates.png)

### Create a self-signed certificate

Click **Create Self-Signed Certificate** in the Actions pane on the right.

![Create Self-Signed Certificate](../../presentation/assets/image/SSL%20Certificate/2%20-%20Create%20Self-Signed%20Certificate.png)

### Specify a friendly name

Give the certificate a descriptive name so you can identify it later in the certificate store.

![Specify Name](../../presentation/assets/image/SSL%20Certificate/3%20-%20Specify%20Name.png)

### Confirm the certificate was created

The new certificate appears in the Server Certificates list.

![New Cert Created](../../presentation/assets/image/SSL%20Certificate/4%20-%20New%20Cert%20Created.png)

---

## Phase 2: Import into the Certificate Store and Grant Access

The certificate needs to be in the Windows Certificate Store (Local Computer > Personal) and the SQL Server service account needs read access to its private key.

### Open MMC

Run `mmc.exe` and add the **Certificates** snap-in.

![Open MMC](../../presentation/assets/image/SSL%20Certificate/11%20-%20Open%20MMC.png)

### Add the Certificates snap-in

Select **Certificates** from the available snap-ins.

![Add Certificates](../../presentation/assets/image/SSL%20Certificate/12%20-%20Add%20Certificates.png)

### Select Computer Account

Choose **Computer account** so you're managing machine-level certificates, not user-level.

![Computer Account](../../presentation/assets/image/SSL%20Certificate/13%20-%20Computer%20Account.png)

### Select Local Computer

Point to the local computer (the SQL Server host).

![Local Computer](../../presentation/assets/image/SSL%20Certificate/14%20-%20Local%20Computer.png)

### Verify the certificate is available

Navigate to **Personal > Certificates**. The self-signed certificate you created should appear here.

![Certificate Available](../../presentation/assets/image/SSL%20Certificate/15%20-%20Certificate%20Available.png)

### Manage Private Keys

Right-click the certificate and choose **All Tasks > Manage Private Keys**. This is where you grant the SQL Server service account access.

![Manage Private Keys](../../presentation/assets/image/SSL%20Certificate/16%20-%20Manage%20Private%20Keys.png)

### Add the SQL Server service account

Click **Add** to add a new account to the permissions list.

![Add Account](../../presentation/assets/image/SSL%20Certificate/17%20-%20Add%20Account.png)

### Find the service account

Enter the SQL Server service account name. For a default instance using a virtual account, this is `NT Service\MSSQLSERVER`. For a named instance, it would be `NT Service\MSSQL$InstanceName`.

![Add Service Account](../../presentation/assets/image/SSL%20Certificate/18%20-%20Add%20Service%20Account.png)

### Grant Read permissions

The service account only needs **Read** access to the private key. Do not grant Full Control.

![Service Account Read Permissions](../../presentation/assets/image/SSL%20Certificate/19%20-%20Service%20Account%20Read%20Permissions.png)

---

## Phase 3: Configure SQL Server and Verify

### Open SQL Server Configuration Manager

Navigate to **SQL Server Network Configuration > Protocols for [Instance]** and open the properties.

![Network Protocol Properties](../../presentation/assets/image/SSL%20Certificate/21%20-%20Network%20Protocol%20Properties.png)

### Select the certificate

On the **Certificate** tab, select the certificate you created from the dropdown. SQL Server will only show certificates that the service account has access to.

![Select Certificate](../../presentation/assets/image/SSL%20Certificate/22%20-%20Select%20Certificate.png)

### Enable Force Encryption

On the **Flags** tab, set **Force Encryption** to **Yes**. This requires all connections to use TLS. Without this setting, encryption is optional and clients can connect unencrypted.

![Force Encryption](../../presentation/assets/image/SSL%20Certificate/23%20-%20Force%20Encryption.png)

### Restart the SQL Server service

The certificate and encryption settings take effect after a service restart.

![Restart Service](../../presentation/assets/image/SSL%20Certificate/24%20-%20Restart%20Service.png)

---

## Phase 4: Verify from SSMS

### Connect with encryption options visible

In SSMS, click **Options** to expand the connection dialog before connecting.

![Expand Options](../../presentation/assets/image/SSL%20Certificate/31%20-%20Expand%20Options.png)

### Confirm Encrypt Connection is checked

On the **Connection Properties** tab, verify that **Encrypt connection** is checked. With Force Encryption enabled server-side, this should be the default.

![Encrypt Connection](../../presentation/assets/image/SSL%20Certificate/33%20-%20Encrypt%20Connection.png)

### Verify the encrypted connection

After connecting, you can verify encryption is active by running:

```sql
SELECT encrypt_option
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;
```

The result should show `TRUE`.

![New SSMS](../../presentation/assets/image/SSL%20Certificate/34%20-%20New%20SSMS.png)

---

## Next Steps

- Replace the self-signed certificate with a CA-issued certificate before going to production
- SQL Server 2025 supports **TLS 1.3** -- configure via `mssql-conf` on Linux or registry settings on Windows
- Consider enabling **strict connection encryption mode** (TDS 8.0) in SQL Server 2025 for TLS-first handshakes
