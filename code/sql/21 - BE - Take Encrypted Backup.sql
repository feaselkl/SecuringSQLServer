--Backup Encryption
--2 - Take Encrypted Backup
--The purpose of this script is to take an encrypted backup
--of our TDETest database.  Note that because TDETest already has
--Transparent Data Encryption enabled, we do NOT need to take an
--encrypted backup--the database is already encrypted at rest (including
--backups).  We can still safely do so, however.

USE [master]
GO
BACKUP DATABASE [TDETest] TO  DISK = N'/tmp/TDETest.bak'
	WITH FORMAT, INIT,  MEDIANAME = N'TDETest',
	NAME = N'TDETest-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,
	ENCRYPTION(ALGORITHM = AES_256, SERVER CERTIFICATE = [BackupEncryptionCertificate]),
	STATS = 10;
GO

--We should also test restoration of the database:
--Note that we don't need to specify a certificate here; it already exists on the instance.
ALTER DATABASE [TDETest] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [TDETest] FROM  DISK = N'/tmp/TDETest.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 5
ALTER DATABASE [TDETest] SET MULTI_USER
GO
