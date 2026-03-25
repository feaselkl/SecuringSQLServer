--TDE
--3 - Manage Certificates
--The purpose of this script is to back up our Transparent Database Encryption certificates.
--We will need these to restore backups on other instances.  If you lose the certificate,
--you WILL lose your data!

USE [master]
GO
--Back up the service master key
--Note that the password here is the FILE password and not the KEY password!
BACKUP SERVICE MASTER KEY TO FILE = '/tmp/ServiceMasterKey.key' ENCRYPTION BY PASSWORD = 'This is a service master key password.';
GO
--Back up the database master key
--Again, the password here is the FILE password and not the KEY password.
BACKUP MASTER KEY TO FILE = '/tmp/MasterKey.key' ENCRYPTION BY PASSWORD = 'This is the database key password for my master TDE certificate.';
GO
--Back up the TDE certificate we created.
--We could create a private key with password here as well.
BACKUP CERTIFICATE [TransparentDatabaseEncryptionCertificate] TO FILE = '/tmp/TransparentDataEncryptionCertificate.cert';
GO

USE [master]
GO
--Test restoration of the keys and certificate.
RESTORE SERVICE MASTER KEY FROM FILE = '/tmp/ServiceMasterKey.key' DECRYPTION BY PASSWORD = 'This is a service master key password.';
GO
--For the master key, we need to use the file decription and then the original password used for key encryption.  Otherwise,
--your restoration attempt will fail.
RESTORE MASTER KEY FROM FILE = '/tmp/MasterKey.key'
	DECRYPTION BY PASSWORD = 'This is the database key password for my master TDE certificate.'
	ENCRYPTION BY PASSWORD = 'This is where you put in a really good password.';
GO
--There is no RESTORE CERTIFICATE command.  You would need to drop and re-create the certificate like below.
--Note that because TDE is turned on for this database, you cannot drop this certificate as long as TDE is turned on.
DROP CERTIFICATE [TransparentDatabaseEncryptionCertificate];
CREATE CERTIFICATE TransparentDatabaseEncryptionCertificate FROM FILE = '/tmp/TransparentDataEncryptionCertificate.cert';