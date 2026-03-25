--Data Discovery and Classification
--T-SQL Demo
--This script demonstrates data classification using T-SQL,
--which works on SQL Server 2019+ including Linux containers.
--No SSMS UI required.

--We will use the TDETest database for this demo.
--Run scripts 10 and 11 first to create it.

USE [TDETest]
GO

--Step 1: View current sensitivity classifications.
--Initially, there are none.
SELECT
	s.name AS SchemaName,
	o.name AS TableName,
	c.name AS ColumnName,
	sc.information_type,
	sc.information_type_id,
	sc.label,
	sc.label_id,
	sc.rank,
	sc.rank_desc
FROM sys.sensitivity_classifications sc
INNER JOIN sys.objects o ON sc.major_id = o.object_id
INNER JOIN sys.columns c ON sc.major_id = c.object_id
	AND sc.minor_id = c.column_id
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id;
GO

--Step 2: Add sensitivity classifications to columns.
--These use the built-in information types and labels
--from the SQL Information Protection policy.
ADD SENSITIVITY CLASSIFICATION TO dbo.TestTable.Col1
WITH (
	LABEL = 'Confidential',
	LABEL_ID = '331f0b13-76b5-2f1b-a77b-def5a73c73c2',
	INFORMATION_TYPE = 'Financial',
	INFORMATION_TYPE_ID = 'd22fa6e9-5ee4-3bde-4c2b-a409d9c890a0',
	RANK = MEDIUM
);
GO

--Step 3: Verify the classification was applied.
SELECT
	s.name AS SchemaName,
	o.name AS TableName,
	c.name AS ColumnName,
	sc.information_type,
	sc.label,
	sc.rank_desc
FROM sys.sensitivity_classifications sc
INNER JOIN sys.objects o ON sc.major_id = o.object_id
INNER JOIN sys.columns c ON sc.major_id = c.object_id
	AND sc.minor_id = c.column_id
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id;
GO

--Step 4: Classifications show up in audit logs.
--If you have SQL Server Audit configured, access to classified
--columns will include the sensitivity label in the audit record.
--This is useful for compliance reporting.

--The data_sensitivity_information column in the audit log
--contains an XML fragment like:
--  <sensitivity_attributes>
--    <sensitivity_attribute label="Confidential"
--      information_type="Financial" />
--  </sensitivity_attributes>

--Step 5: You can also remove a classification.
--DROP SENSITIVITY CLASSIFICATION FROM dbo.TestTable.Col1;
--GO

--Common information types and their IDs:
--  Contact Info:     5c503e21-22c6-81fa-620b-f369b8ec38d1
--  Credentials:      c64aba7b-3a3e-95b6-535d-3bc535da5a59
--  Credit Card:      d7e75df0-0209-4be4-89e2-17150c95b518
--  Financial:        d22fa6e9-5ee4-3bde-4c2b-a409d9c890a0
--  Health:           6e2c5b18-97d2-46db-a220-da43b90cb117
--  National ID:      6f5a11a7-08b1-19c3-59e5-8c89cf4f8444
--  SSN:              d936ec2c-04a4-4968-be24-27d185529954

--Common labels and their IDs:
--  Public:                  1866ca45-1973-4c28-9d12-04d407f147ad
--  General:                 684a0db2-d514-49d8-8c0c-df84a7b083eb
--  Confidential:            331f0b13-76b5-2f1b-a77b-def5a73c73c2
--  Confidential - GDPR:     989adc05-3f3f-0588-a635-f475b994915b
--  Highly Confidential:     b82ce05b-60a9-4cf3-8a8a-d6a0bb76e903
--  Highly Confidential - GDPR: 3302ae7f-b8ac-46bc-97f8-378828781f68
