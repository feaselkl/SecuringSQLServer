--Always Encrypted
--0 - Create the AETest Database
--Run this before the other AE scripts so the database exists
--for key provisioning and table creation.

USE [master]
GO
CREATE DATABASE AETest;
GO
