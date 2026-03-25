--Always Encrypted
--3 - Create Sample Database
--The purpose of this script is to set up Always Encrypted
--with Azure Key Vault as the CMK store in the AETest database.

--PREREQUISITES:
--  Run 50 - AE - Create Database.sql to create the AETest database.
--  Run code/sql/51 - AE - Setup Azure Key Vault.sh to create
--  the Azure Key Vault, RSA key, and service principal.
--  That script will output the KEY_PATH URL you need below.

--  Then run the PowerShell script 52 - AE - Provision Keys.ps1 to create the
--  Column Master Key metadata and Column Encryption Key (CEK).

USE [AETest]
GO

--Step 1: Create a table with encrypted columns.
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

--Step 2: Insert sample data.
--IMPORTANT: You must insert data from a client with
--"Column Encryption Setting=enabled" and access to AKV.
--
--Option A (SSMS on Windows):
--  Connection dialog > Options > Additional Connection
--  Parameters > add: Column Encryption Setting=enabled
--  Then: Query > Query Options > Execution > Advanced >
--  Enable Parameterization for Always Encrypted
--
--Option B (Linux / any platform):
--  cd code/ae && uv run insert_sample_data.py
--  (Requires .env with AKV credentials — see .env.example)
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
