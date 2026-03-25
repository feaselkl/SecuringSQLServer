# SQL Server Hardening Checklist

A practical checklist for securing SQL Server instances. Items marked with **(demo)** have working scripts in the `code/` directory.

## Installation and Configuration

- [ ] Remove unnecessary components (SSRS, SSAS, SSIS, ML Services, SSMS) from production instances
- [ ] Remove sample databases (AdventureWorks, WideWorldImporters, Northwind, Contoso)
- [ ] Disable unnecessary services (SQL Server Browser, VSS Writer)
- [ ] Use virtual accounts or gMSAs instead of domain accounts for service accounts
- [ ] Ensure service accounts do not have Domain Admin rights
- [ ] Disable Named Pipes; use TCP/IP for remote and Shared Memory for local connections
- [ ] Enable contained database authentication where appropriate
- [ ] Configure Microsoft Entra ID authentication (Azure SQL DB/MI, or SQL Server 2025 on-premises)

## Patch Management

- [ ] Know your current build (`SELECT @@VERSION`) and compare to [sqlserverversions.com](https://sqlserverversions.com)
- [ ] Confirm no instances are running on versions past extended support (SQL Server 2014 and earlier)
- [ ] Establish a patching cadence: apply CUs within 2-3 weeks of release after community validation
- [ ] Apply GDRs (critical security patches) as soon as feasible after testing
- [ ] Test CUs in a non-production environment before applying to production

## Data Encryption

- [ ] Enable TDE or full-disk encryption (e.g., BitLocker) for data at rest **(demo: scripts 10-12)**
- [ ] Back up TDE certificates and keys; store them securely outside the SQL Server instance **(demo: script 12)**
- [ ] Enable backup encryption **(demo: scripts 20-21)**
- [ ] Evaluate column-level encryption for sensitive columns that need to be visible in plaintext **(demo: scripts 30-32)**
- [ ] Evaluate Always Encrypted with Azure Key Vault for columns that should be hidden from DBAs **(demo: scripts 50-51)**

## Access Control

- [ ] Implement Row-Level Security where user-scoped access to rows is needed **(demo: scripts 40-42)**
- [ ] Do not rely on Dynamic Data Masking as a security control (it is easily bypassed)

## Connection Security

- [ ] Configure TLS with a valid certificate (enterprise CA, not self-signed in production)
- [ ] Enable Force Encryption in SQL Server Configuration Manager **(scripts: code/tls/)**
- [ ] Upgrade to TLS 1.3 where possible (SQL Server 2025)
- [ ] Consider strict connection encryption mode (TDS 8.0) for SQL Server 2025
- [ ] Restrict network access via firewalls, subnets, VLANs, or VNets
- [ ] Disable or restrict outbound internet access from SQL Server

## Data Classification and Auditing

- [ ] Classify sensitive columns using `ADD SENSITIVITY CLASSIFICATION` **(demo: script 60)**
- [ ] Enable SQL Server Audit on tables containing sensitive data
- [ ] Keep audit scope narrow to avoid performance impact
- [ ] Consider Microsoft Purview for cross-estate classification and sensitivity labels

## Ledger and Tamper Protection

- [ ] Evaluate ledger tables for regulatory or forensic audit trail requirements
- [ ] Consider Azure Confidential Ledger integration for independent digest verification (SQL Server 2025)

## Assessment Tooling

- [ ] Run [dbachecks](https://dbachecks.io) against your instances (CIS framework checks)
- [ ] Run [sp_CheckSecurity](https://straightpathsql.com) for instance- and database-level security checks
- [ ] Enable Microsoft Defender for SQL (Azure SQL DB, MI, Azure VM, or Arc-enabled)

---

## Beyond This Talk

These items are outside the scope of the presentation but are essential to a complete security posture.

### Permissions and Access

- [ ] Audit sysadmin role membership; remove any accounts that don't need it
- [ ] Review all login and user permissions using `sys.server_permissions` and `sys.database_permissions`
- [ ] Remove orphaned users (`sp_change_users_login @Action='Report'` or `ALTER USER ... WITH LOGIN`)
- [ ] Enforce password policies on SQL logins (`CHECK_POLICY = ON, CHECK_EXPIRATION = ON`)
- [ ] Disable or rename the `sa` account
- [ ] Review linked server credential mappings; avoid storing passwords in plaintext
- [ ] Use module signing to grant scoped permissions to stored procedures

### Application Security

- [ ] Implement parameterized queries or stored procedures to prevent SQL injection
- [ ] Use application-level connection pooling with least-privilege accounts
- [ ] Avoid using `sa` or sysadmin-level accounts in application connection strings
- [ ] Implement code signing for database deployment scripts

### Backup and Recovery

- [ ] Regularly test backup restores (not just backup success)
- [ ] Store backup encryption certificates separately from the backups themselves
- [ ] Document and test your disaster recovery plan at least annually

### Monitoring

- [ ] Monitor failed login attempts
- [ ] Set up alerts for permission changes (new sysadmin members, new logins)
- [ ] Monitor for brute-force attacks on SQL Server ports
