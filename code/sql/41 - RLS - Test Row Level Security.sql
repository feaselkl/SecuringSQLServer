--Row Level Security
--2 - Test Row Level Security
--The purpose of this script is to use the database we created
--in script 1 and 

USE [RLSTest]
GO

--Alice can see all of her messages and Bob's messages.
EXECUTE AS USER = 'Alice';

SELECT
	ml.*
FROM dbo.MessageLog ml;

REVERT
GO

--Now let's create a function limiting users to see just their own messages.
CREATE FUNCTION dbo.RLSTestPredicate (@UserName as sysname)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS rowLevelPredicateResult
WHERE @UserName = USER_NAME();
GO

--Now we need to apply the predicate to a new security policy on our table.
CREATE SECURITY POLICY RLSTestPolicy
ADD FILTER PREDICATE dbo.RLSTestPredicate(MessageSender)
ON dbo.MessageLog
WITH (STATE = ON); 

--Now Alice can only see her own messages.
EXECUTE AS USER = 'Alice';

SELECT
	ml.*
FROM dbo.MessageLog ml;

REVERT
GO

--And Bob can see his own.
EXECUTE AS USER = 'Bob';

SELECT
	ml.*
FROM dbo.MessageLog ml;

REVERT
GO