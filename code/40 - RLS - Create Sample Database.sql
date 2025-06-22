--Row Level Security
--1 - Create Sample Database
--The purpose of this script is to create a sample RLSTest database for
--testing Row Level Security.

USE [master]
GO
CREATE DATABASE RLSTest;
GO

USE [RLSTest]
GO

--Create two loginless users we can use for testing.
CREATE USER [Alice] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [Bob] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo];
GO

CREATE TABLE dbo.MessageLog
(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	MessageText VARCHAR(50) NOT NULL,
	MessageSender VARCHAR(20) NOT NULL
);
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.MessageLog TO Alice, Bob;
GO

INSERT INTO dbo.MessageLog
(
	MessageText,
	MessageSender
)
VALUES
('Greetings to Alice', 'Bob'),
('Salutations to Bob', 'Alice'),
('I do not see Charlie', 'Alice'),
('He is in a different security demo with Diane', 'Bob');
