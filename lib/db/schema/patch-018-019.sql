-- Create table and stored procedures for batched update of sessionTokens

CREATE TABLE batchSessionTokenUpdates(
    tokenId BINARY(32) PRIMARY KEY,
    uaBrowser VARCHAR(255),
    uaBrowserVersion VARCHAR(255),
    uaOS VARCHAR(255),
    uaOSVersion VARCHAR(255),
    uaDeviceType VARCHAR(255),
    lastAccessTime BIGINT UNSIGNED
) ENGINE=MEMORY;

CREATE PROCEDURE `updateSessionToken_2` (
    IN tokenId BINARY(32),
    IN uaBrowser VARCHAR(255),
    IN uaBrowserVersion VARCHAR(255),
    IN uaOS VARCHAR(255),
    IN uaOSVersion VARCHAR(255),
    IN uaDeviceType VARCHAR(255),
    IN lastAccessTime BIGINT UNSIGNED
)
BEGIN
    INSERT INTO batchSessionTokenUpdates(
        tokenId,
        uaBrowser,
        uaBrowserVersion,
        uaOS,
        uaOSVersion,
        uaDeviceType,
        lastAccessTime
    )
    VALUES(
        tokenId,
        uaBrowser,
        uaBrowserVersion,
        uaOS,
        uaOSVersion,
        uaDeviceType,
        lastAccessTime
    )
    ON DUPLICATE KEY
    UPDATE tokenId=tokenId;
END;

CREATE PROCEDURE `batchUpdateSessionTokens_1` (
    IN batchSize INT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT @updateCount:=COUNT(*) FROM batchSessionTokenUpdates FOR UPDATE;

    IF @updateCount >= batchSize THEN
        UPDATE sessionTokens INNER JOIN batchSessionTokenUpdates
        ON sessionTokens.tokenId = batchSessionTokenUpdates.tokenId
        SET
            sessionTokens.uaBrowser = batchSessionTokenUpdates.uaBrowser,
            sessionTokens.uaBrowserVersion = batchSessionTokenUpdates.uaBrowserVersion,
            sessionTokens.uaOS = batchSessionTokenUpdates.uaOS,
            sessionTokens.uaOSVersion = batchSessionTokenUpdates.uaOSVersion,
            sessionTokens.uaDeviceType = batchSessionTokenUpdates.uaDeviceType,
            sessionTokens.lastAccessTime = batchSessionTokenUpdates.lastAccessTime
        ;

        DELETE FROM batchSessionTokenUpdates;
    END IF;

    COMMIT;
END;

UPDATE dbMetadata SET value = '19' WHERE name = 'schema-patch-level';

