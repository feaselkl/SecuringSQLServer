--Row Level Security
--3 - Additional Row Level Security Testing
--The purpose of this script is to use the database we created
--in script 1 and 

USE [RLSTest]
GO

--So what happens when Alice looks for Bob's messages?
EXECUTE AS USER = 'Alice';

SELECT
	ml.*
FROM dbo.MessageLog ml
WHERE
	ml.MessageText LIKE '%Diane%';

REVERT
GO

--What happens when Alice tries to update one of Bob's messages?
EXECUTE AS USER = 'Alice';

UPDATE ml
SET
	MessageText = 'CHANGED MESSAGE'
FROM dbo.MessageLog ml
WHERE
	ml.MessageText LIKE '%Diane%';

REVERT
GO

--What happens if Alice tries to delete one of Bob's messages?
EXECUTE AS USER = 'Alice';

DELETE ml
FROM dbo.MessageLog ml
WHERE
	ml.MessageText LIKE '%Diane%';

REVERT
GO

--What happens if Alice tries to insert one of Bob's messages?
EXECUTE AS USER = 'Alice';

INSERT INTO dbo.MessageLog
(
	MessageText,
	MessageSender
)
VALUES
(
	'This is a bad message.',
	'Bob'
);

REVERT
GO

--Bob can see the message Alice created.
EXECUTE AS USER = 'Bob';

SELECT
	ml.*
FROM dbo.MessageLog ml;

REVERT
GO

--Special note:  even sysadmins can't see this data!
SELECT
	ml.*
FROM dbo.MessageLog ml;

--So let's allow them to...


--Now let's create a function limiting users to see just their own messages.
DROP SECURITY POLICY RLSTestPolicy
GO
ALTER FUNCTION dbo.RLSTestPredicate (@UserName as sysname)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS rowLevelPredicateResult
WHERE @UserName = USER_NAME()
OR IS_ROLEMEMBER(N'dbo') = 1;
GO
CREATE SECURITY POLICY RLSTestPolicy
ADD FILTER PREDICATE dbo.RLSTestPredicate(MessageSender)
ON dbo.MessageLog
WITH (STATE = ON); 

SELECT
	ml.*
FROM dbo.MessageLog ml;
GO
