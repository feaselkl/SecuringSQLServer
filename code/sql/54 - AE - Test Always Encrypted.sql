--Always Encrypted
--2 - Test Always Encrypted
--The purpose of this script is to demonstrate how Always Encrypted
--behaves from different connection contexts.

USE [AETest]
GO

--Test 1: Query WITHOUT "Column Encryption Setting=enabled".
--You will see encrypted (binary) values for SSN and MedicalNotes.
--This is what a DBA or attacker sees, even with sysadmin rights.
SELECT
	PatientId,
	FirstName,
	LastName,
	SSN,
	DateOfBirth,
	MedicalNotes
FROM dbo.PatientRecords;
GO

--Test 2: Connect with a NEW SSMS connection.
--  Options > Additional Connection Parameters >
--  Column Encryption Setting=enabled
--
--SSMS will use its AKV provider to decrypt. You must be
--authenticated to Azure (SSMS uses your Azure account).
--Now the same query shows plaintext values.
--
--On Linux: cd code/ae && uv run query_encrypted_data.py
--  runs all three tests with side-by-side output.

--Test 3: With an AE-enabled connection, try a parameterized
--equality lookup on the deterministically encrypted SSN column.
--  Query > Query Options > Execution > Advanced >
--  Enable Parameterization for Always Encrypted
DECLARE @SSN CHAR(11) = '123-45-6789';
SELECT
	PatientId,
	FirstName,
	LastName,
	SSN,
	DateOfBirth
FROM dbo.PatientRecords
WHERE SSN = @SSN;
GO

--Test 4: LIKE queries on encrypted columns will FAIL.
--Always Encrypted does not support pattern matching
--without secure enclaves.

--SELECT * FROM dbo.PatientRecords WHERE SSN LIKE '123%';
--Msg 33277: Encryption scheme mismatch for columns/variables

--Test 5: Range comparisons also FAIL without enclaves.

--SELECT * FROM dbo.PatientRecords WHERE SSN > '100-00-0000';
--Msg 33277: Encryption scheme mismatch for columns/variables

--Key takeaway: Without secure enclaves, Always Encrypted supports
--only equality comparisons on deterministically encrypted columns,
--and no query operations on randomly encrypted columns.
--
--Secure enclaves (VBS in SQL Server 2025) enable pattern matching,
--range comparisons, and sorting on encrypted data, but enclaves
--are not supported on Linux containers.
