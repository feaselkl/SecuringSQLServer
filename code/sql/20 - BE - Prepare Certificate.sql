--Backup Encryption
--1 - Prepare Certificate
--The purpose of this script is to ensure that we have a valid
--certificate for taking encrypted backups.

USE [master]
GO
--Check to see if you have a master key.  If you have one already, you can use it.
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
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'This is where you put in a really good password.';
END
ELSE
BEGIN
	OPEN MASTER KEY DECRYPTION BY PASSWORD = 'This is where you put in a really good password.';
END
GO

--See if you already have a good certificate you can use.  If you have not already created one,
--you should do so below.
SELECT
	*
FROM sys.certificates;

--Now that we have a master key, we can create a certificate.
--You COULD use the same certificate as you used with the TDE example, but we'll use separate
--certs in this case, just to show it's possible.
CREATE CERTIFICATE BackupEncryptionCertificate WITH SUBJECT = 'Backup Encryption Certificate';
GO

--Back up the backup encryption certificate we created.
--We could create a private key with password here as well.
BACKUP CERTIFICATE [BackupEncryptionCertificate] 
    TO FILE = '/tmp/BackupEncryptionCertificate.cert'
    WITH PRIVATE KEY (
        FILE = '/tmp/BackupEncryptionCertificate.key',
        ENCRYPTION BY PASSWORD = 'Some!Str@ngPasswordHere'
    );
GO
