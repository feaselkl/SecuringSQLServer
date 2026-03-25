--TDE
--2 - Encrypt Database
--The purpose of this script is to encrypt our TDETest database
--and manage the keys and certificates associated with it.

USE [master]
GO
--Check to see if you have a master key.  If you have one already, you can use it.
SELECT
	*
FROM sys.symmetric_keys
WHERE
	name = N'##MS_DatabaseMasterKey##';

--If you do not already have a master key on this instance, create one now:
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'This is where you put in a really good password.';
GO

--See if you already have a good certificate you can use.  If you have not already created one,
--you should do so below.
SELECT
	*
FROM sys.certificates;

--Now that we have a master key, we can create a certificate.
CREATE CERTIFICATE TransparentDatabaseEncryptionCertificate WITH SUBJECT = 'Transparent Database Encryption Certificate';
GO

USE [TDETest]
GO
--Now we can create a database encryption key for our test database, built off of the certificate created above.
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TransparentDatabaseEncryptionCertificate;
GO

--And this turns on TDE for our database:
ALTER DATABASE TDETest SET ENCRYPTION ON;
GO

--We can now see that TDETest AND tempdb have encryption set.
SELECT
	d.name,
	d.is_encrypted
FROM sys.databases d;
GO
