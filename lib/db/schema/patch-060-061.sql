ALTER TABLE unblockCodes ADD COLUMN attemptsLeft TINYINT UNSIGNED NOT NULL, ALGORITHM = INPLACE, LOCK = NONE;

CREATE PROCEDURE `tryUnblockCode_1` (
    inUid BINARY(16),
    inCodeHash BINARY(32)
)

BEGIN
    DECLARE timestamp BIGINT;
    DECLARE triesLeft TINYINT;

    SELECT createdAt, attemptsLeft
    INTO timestamp, triesLeft FROM unblockCodes
    WHERE
        uid = inUid
    AND
        unblockCodeHash = inCodeHash;

    IF (triesLeft > 1) THEN
        UPDATE unblockCodes SET attemptsLeft = attemptsLeft - 1
        WHERE
            uid = inUid
        AND
            unblockCodeHash = inCodeHash;
    ELSE
        DELETE FROM unblockCodes
        WHERE
            uid = inUid
        AND
            unblockCodeHash = inCodeHash;
    END IF;

    SELECT timestamp AS createdAt;
END;

CREATE PROCEDURE `createUnblockCode_2` (
    IN inUid BINARY(16),
    IN inCodeHash BINARY(32),
    IN inCreatedAt BIGINT SIGNED,
    IN inAttemptsLeft TINYINT UNSIGNED
)
BEGIN
    INSERT INTO unblockCodes(
        uid,
        unblockCodeHash,
        createdAt,
        attemptsLeft
    )
    VALUES(
        inUid,
        inCodeHash,
        inCreatedAt,
        inAttemptsLeft
    );
END;

UPDATE dbMetadata SET value = '61' WHERE name = 'schema-patch-level';

