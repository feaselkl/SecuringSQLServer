# Securing SQL Server

This repository provides the supporting code for my presentation entitled [Securing SQL Server](https://www.catallaxyservices.com/presentations/securing-sql-server/).

## Repository Structure

- `code/sql/` - Demo SQL scripts covering TDE, backup encryption, column-level security, row-level security, Always Encrypted, and data classification
- `code/tls/` - Scripts for configuring TLS on Linux and Windows
- `CHECKLIST.md` - A practical SQL Server hardening checklist

## Running the Code

### Building the Docker Container Image

The demo scripts run against SQL Server 2025 in a Docker container. Build the image from the `code/` directory:

```bash
cd code
docker build -t securing-sql-server .
```

### Running the Container

Pass the required environment variables when starting the container:

```bash
docker run -d -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=YourStrongPassword!" \
  -e "MSSQL_PID=Developer" \
  -p 14330:1433 \
  --name securing-sql-server \
  securing-sql-server
```

Replace `YourStrongPassword!` with a password that meets the [SQL Server password policy](https://learn.microsoft.com/en-us/sql/relational-databases/security/password-policy) (at least 10 characters, including uppercase, lowercase, digits, and symbols).

### Demo Scripts

Once the container is running, demo scripts are available inside the container at `/var/opt/mssql/scripts/sql/`. You can connect to the SQL Server instance on `localhost,14330` using the `sa` account and run the scripts in order:

| Scripts | Topic |
|---------|-------|
| 10-12 | Transparent Data Encryption (TDE) |
| 20-21 | Backup Encryption |
| 30-32 | Column-Level Security |
| 40-42 | Row-Level Security |
| 50-53 | Always Encrypted with Azure Key Vault |
| 60 | Data Classification |
| 99 | Cleanup |

### TLS Configuration

The `code/tls/` directory contains scripts for configuring TLS encryption on SQL Server:

- `setup-tls-linux.sh` - Linux setup script
- `Setup-TLS-Windows.ps1` - Windows PowerShell setup script
- `TLS-Setup-Windows-UI.md` - Instructions for configuring TLS via the Windows UI

### Always Encrypted with Azure Key Vault

Scripts 50-53 require an Azure Key Vault instance. See the shell and PowerShell scripts in `code/sql/` prefixed with `50` for setup instructions.
