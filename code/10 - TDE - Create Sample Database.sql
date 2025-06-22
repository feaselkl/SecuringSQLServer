--TDE
--1 - Create Sample Database
--The purpose of this script is to create a sample TDETest database for
--testing Transparent Data Encryption.

USE [master]
GO
CREATE DATABASE TDETest;
GO

USE [TDETest]
GO

CREATE TABLE dbo.TestTable
(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	SomePadding CHAR(50) NOT NULL
);

INSERT INTO dbo.TestTable
(
	SomePadding
)
SELECT
	REPLICATE('A', 50)
FROM sys.all_columns;
GO

--Note that databases are not encrypted
SELECT
	d.name,
	d.is_encrypted
FROM sys.databases d;