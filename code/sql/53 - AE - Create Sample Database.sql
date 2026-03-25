--Always Encrypted
--1 - Create Sample Database
--The purpose of this script is to create a sample AETest database
--and set up Always Encrypted with Azure Key Vault as the CMK store.

--PREREQUISITES:
--  Run code/sql/50 - AE - Setup Azure Key Vault.sh first to create
--  the Azure Key Vault, RSA key, and service principal.
--  That script will output the KEY_PATH URL you need below.

--  Then run the PowerShell script 51 - AE - Provision Keys.ps1 to generate the Column
--  Encryption Key (CEK), which requires client-side access to AKV.

USE [master]
GO
CREATE DATABASE AETest;
GO

USE [AETest]
GO

--Step 1: Create the Column Master Key metadata.
--This is just a pointer to the key in Azure Key Vault.
--SQL Server never accesses AKV directly; clients use this URL.
--Replace the KEY_PATH with the output from 50.
CREATE COLUMN MASTER KEY [AE_ColumnMasterKey]
WITH
(
	KEY_STORE_PROVIDER_NAME = N'AZURE_KEY_VAULT',
	KEY_PATH = N'https://YOUR_VAULT_NAME.vault.azure.net/keys/AlwaysEncryptedCMK/YOUR_KEY_VERSION'
);
GO

--Step 2: Create the Column Encryption Key.
--The CEK must be generated and wrapped by a client that has access
--to Azure Key Vault. Run 51 - AE - Provision Keys.ps1 to do this.
--That script will output a CREATE COLUMN ENCRYPTION KEY statement
--with the correct encrypted value. Run that output here.

--Step 3: Create a table with encrypted columns.
--SSN uses Deterministic encryption (allows equality lookups).
--MedicalNotes uses Randomized encryption (stronger security).
--Deterministic string columns MUST use a BIN2 collation.
CREATE TABLE dbo.PatientRecords
(
	PatientId INT IDENTITY(1,1) PRIMARY KEY,
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,
	SSN CHAR(11) COLLATE Latin1_General_BIN2
		ENCRYPTED WITH (
			COLUMN_ENCRYPTION_KEY = [AE_ColumnEncryptionKey],
			ENCRYPTION_TYPE = DETERMINISTIC,
			ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'
		) NOT NULL,
	DateOfBirth DATE NOT NULL,
	MedicalNotes NVARCHAR(MAX)
		ENCRYPTED WITH (
			COLUMN_ENCRYPTION_KEY = [AE_ColumnEncryptionKey],
			ENCRYPTION_TYPE = RANDOMIZED,
			ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'
		) NULL
);
GO

--Step 4: Insert sample data.
--IMPORTANT: You must insert data from a client with
--"Column Encryption Setting=enabled" and access to AKV.
--From SSMS: connection dialog > Options > Additional Connection
--Parameters > add: Column Encryption Setting=enabled
--SSMS will encrypt the values client-side before sending to SQL Server.

--With an AE-enabled SSMS connection and parameterization enabled:
--  Query > Query Options > Execution > Advanced >
--  Enable Parameterization for Always Encrypted
DECLARE @FirstName NVARCHAR(50), @LastName NVARCHAR(50),
		@SSN CHAR(11), @DOB DATE, @Notes NVARCHAR(MAX);

SET @FirstName = N'Alice'; SET @LastName = N'Smith';
SET @SSN = '123-45-6789'; SET @DOB = '1985-03-15';
SET @Notes = N'Annual checkup - all clear';
INSERT INTO dbo.PatientRecords (FirstName, LastName, SSN, DateOfBirth, MedicalNotes)
VALUES (@FirstName, @LastName, @SSN, @DOB, @Notes);

SET @FirstName = N'Bob'; SET @LastName = N'Jones';
SET @SSN = '987-65-4321'; SET @DOB = '1990-07-22';
SET @Notes = N'Follow-up on knee surgery';
INSERT INTO dbo.PatientRecords (FirstName, LastName, SSN, DateOfBirth, MedicalNotes)
VALUES (@FirstName, @LastName, @SSN, @DOB, @Notes);

SET @FirstName = N'Carol'; SET @LastName = N'Williams';
SET @SSN = '555-12-3456'; SET @DOB = '1978-11-30';
SET @Notes = N'Prescription renewal - blood pressure medication';
INSERT INTO dbo.PatientRecords (FirstName, LastName, SSN, DateOfBirth, MedicalNotes)
VALUES (@FirstName, @LastName, @SSN, @DOB, @Notes);
GO
