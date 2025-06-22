--Column Level Security
--3 - Test Procedures
--The purpose of this script is to test the stored procedures we created in the CLSTest database.

EXEC dbo.MessageLog_InsertMessage
    @MessageText = 'Greetings to Alice',
    @MessageSender = 'Bob',
    @SenderIPAddress = '192.168.1.15';
GO
EXEC dbo.MessageLog_InsertMessage
    @MessageText = 'Salutations to Bob',
    @MessageSender = 'Alice',
    @SenderIPAddress = '192.168.1.204';
GO
EXEC dbo.MessageLog_InsertMessage
    @MessageText = 'I do not see Charlie',
    @MessageSender = 'Alice',
    @SenderIPAddress = '192.168.1.204';
GO
EXEC dbo.MessageLog_InsertMessage
    @MessageText = 'He is in a different security demo with Diane',
    @MessageSender = 'Bob',
    @SenderIPAddress = '192.168.1.15';
GO

-- Verify that the messages were inserted correctly
-- Note that the SenderIPAddress is encrypted.
SELECT * FROM dbo.MessageLog;

EXEC dbo.MessageLog_GetMessages
    @MessageSender = 'Alice';
GO

EXEC dbo.MessageLog_GetDecryptedMessages
    @MessageSender = 'Alice';
GO
