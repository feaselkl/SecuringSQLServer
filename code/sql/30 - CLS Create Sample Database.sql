--Column Level Security
--1 - Create Sample Database
--The purpose of this script is to create a sample CLSTest database for
--testing Column Level Security.

USE [master]
GO
CREATE DATABASE CLSTest;
GO

USE [CLSTest]
GO
--We need a database master key to encrypt our symmetric keys.
IF NOT EXISTS
(
	SELECT
		*
	FROM sys.symmetric_keys
	WHERE
		name = N'##MS_DatabaseMasterKey##'
)
BEGIN
	--If you do not already have a master key on this instance, create one now:
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'This is where we put the CLSTest master key password.';
END
ELSE
BEGIN
	-- If you do already have one, open the master key:
	OPEN MASTER KEY DECRYPTION BY PASSWORD = 'This is where we put the CLSTest master key password.';
END
GO
SELECT
	*
FROM sys.symmetric_keys
WHERE
	name = N'##MS_DatabaseMasterKey##';

CREATE TABLE dbo.MessageLog
(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	MessageText VARCHAR(50) NOT NULL,
	MessageSender VARCHAR(20) NOT NULL,
    SenderIPAddress VARBINARY(256) NOT NULL
);
GO

-- Create a certificate we can use for encryption.
CREATE CERTIFICATE CLSTestCert WITH SUBJECT = 'Certificate for testing Column Level Security';
GO
CREATE SYMMETRIC KEY CLSTestKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE CLSTestCert;
GO
--Back up the database master key and certificate we created.
BACKUP MASTER KEY TO FILE = '/tmp/MasterKey_CLSTest.key' ENCRYPTION BY PASSWORD = 'This is the database master key for the CLSTest database.';
GO
BACKUP CERTIFICATE [CLSTestCert] TO FILE = '/tmp/CLSTestCert.cert';
GO
