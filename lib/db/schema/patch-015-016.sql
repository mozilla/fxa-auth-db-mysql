-- Add queries for metrics reporting

CREATE PROCEDURE `countAccountsCreatedBefore_1` (
    IN createdBefore BIGINT UNSIGNED
)
BEGIN
    SELECT COUNT(*) AS count FROM accounts
    WHERE createdAt < createdBefore;
END;

CREATE PROCEDURE `countVerifiedAccountsCreatedBefore_1` (
    IN createdBefore BIGINT UNSIGNED
)
BEGIN
    SELECT COUNT(*) AS count FROM accounts
    WHERE createdAt < createdBefore
    AND emailVerified = true;
END;

CREATE PROCEDURE `countAccountsWithTwoOrMoreDevices_1` ()
BEGIN
    SELECT COUNT(*) AS count FROM (
        SELECT uid FROM sessionTokens
        GROUP BY uid
        HAVING COUNT(tokenId) > 1
    ) AS s;
END;

CREATE PROCEDURE `countAccountsWithThreeOrMoreDevices_1` ()
BEGIN
    SELECT COUNT(*) AS count FROM (
        SELECT uid FROM sessionTokens
        GROUP BY uid
        HAVING COUNT(tokenId) > 2
    ) AS s;
END;

CREATE PROCEDURE `countAccountsWithMobileDevice_1` ()
BEGIN
    SELECT COUNT(DISTINCT uid) AS count
    FROM sessionTokens
    WHERE uaDeviceType = 'mobile';
END;

UPDATE dbMetadata SET value = '16' WHERE name = 'schema-patch-level';

