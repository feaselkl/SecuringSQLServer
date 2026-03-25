--Column Level Security
--2 - Create Procedures
--The purpose of this script is to create stored procedures to insert and retrieve messages
-- in the CLSTest database. One get procedure retrieves messages but does not perform decryption,
-- and the other retrieves decrypted IP addresses.
USE [CLSTest]
GO
CREATE OR ALTER PROCEDURE [dbo].[MessageLog_InsertMessage]
  @MessageText VARCHAR(50),
  @MessageSender VARCHAR(20),
  @SenderIPAddress NVARCHAR(50)
WITH EXECUTE AS OWNER AS
BEGIN
    OPEN SYMMETRIC KEY CLSTestKey DECRYPTION BY CERTIFICATE CLSTestCert;

    INSERT INTO dbo.MessageLog
    (
        MessageText,
        MessageSender,
        SenderIPAddress
    )
    VALUES
    (
        @MessageText,
        @MessageSender,
        CAST(EncryptByKey(Key_GUID('CLSTestKey'), @SenderIPAddress) AS VARBINARY(256))
    );
END
GO

CREATE PROCEDURE [dbo].[MessageLog_GetMessages]
  @MessageSender VARCHAR(20)
WITH EXECUTE AS OWNER AS
BEGIN
    SELECT
        ml.MessageText,
        ml.MessageSender,
        ml.SenderIPAddress
    FROM [dbo].[MessageLog] ml
    WHERE
        MessageSender = @MessageSender;
END
GO


CREATE PROCEDURE [dbo].[MessageLog_GetDecryptedMessages]
  @MessageSender VARCHAR(20)
WITH EXECUTE AS OWNER AS
BEGIN
    SELECT
        ml.MessageText,
        ml.MessageSender,
        CONVERT(NVARCHAR(50), DecryptByKey(ml.SenderIPAddress)) AS SenderIPAddress
    FROM [dbo].[MessageLog] ml
    WHERE
        MessageSender = @MessageSender;
END
GO
