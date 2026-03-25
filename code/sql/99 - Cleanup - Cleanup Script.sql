--Cleanup Script.sql
--This drops any certificates, keys, or objects we created
--as part of the demo.
--It is safe to re-run.

USE [master]
GO
IF DB_ID('AETest') IS NOT NULL
BEGIN
	ALTER DATABASE AETest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE AETest;
END
GO

IF DB_ID('RLSTest') IS NOT NULL
BEGIN
	ALTER DATABASE RLSTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE RLSTest;
END
GO

IF DB_ID('CLSTest') IS NOT NULL
BEGIN
	ALTER DATABASE CLSTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE CLSTest;
END
GO

IF DB_ID('TDETest') IS NOT NULL
BEGIN
	ALTER DATABASE TDETest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE TDETest;
END
GO

IF EXISTS
(
	SELECT 1 
	FROM sys.certificates
	WHERE name = N'TransparentDatabaseEncryptionCertificate'
)
BEGIN
	DROP CERTIFICATE [TransparentDatabaseEncryptionCertificate];
END
GO

IF EXISTS
(
	SELECT 1 
	FROM sys.certificates
	WHERE name = N'BackupEncryptionCertificate'
)
BEGIN
	DROP CERTIFICATE [BackupEncryptionCertificate];
END
GO

IF EXISTS
(
	SELECT 1 
	FROM sys.symmetric_keys
	WHERE name = N'CLSTestKey'
)
BEGIN
	DROP SYMMETRIC KEY [CLSTestKey];
END
GO

IF EXISTS
(
	SELECT 1 
	FROM sys.certificates
	WHERE name = N'CLSTestCert'
)
BEGIN
	DROP CERTIFICATE [CLSTestCert];
END
GO

IF EXISTS
(
	SELECT 1
	FROM sys.symmetric_keys
	WHERE
		name = N'##MS_DatabaseMasterKey##'
)
BEGIN
	DROP MASTER KEY;
END
GO

--Restart the SQL Server service to set tempdb encryption back to 0.
SELECT
	d.name,
	d.is_encrypted
FROM sys.databases d;
GO
