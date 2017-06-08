CREATE PROCEDURE `prune_3` (IN `olderThan` BIGINT UNSIGNED)
BEGIN
  SELECT @lockAcquired := GET_LOCK('fxa-auth-server.prune-lock', 3);

  IF @lockAcquired THEN
    DELETE FROM accountResetTokens WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;
    DELETE FROM passwordForgotTokens WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;
    DELETE FROM passwordChangeTokens WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;
    DELETE FROM unblockCodes WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;
    DELETE FROM signinCodes WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;

    SELECT RELEASE_LOCK('fxa-auth-server.prune-lock');
  END IF;
END;

DROP PROCEDURE `expireSigninCodes_1`;

CREATE PROCEDURE `consumeSigninCode_2` (
  IN `hashArg` BINARY(32),
  IN `newerThan` BIGINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT email
  FROM accounts
  WHERE uid = (
    SELECT uid
    FROM signinCodes
    WHERE hash = hashArg
	AND createdAt > newerThan
  );

  DELETE FROM signinCodes
  WHERE hash = hashArg
  AND createdAt > newerThan;

  COMMIT;
END;

CREATE PROCEDURE `forgotPasswordVerified_6` (
    IN `inPasswordForgotTokenId` BINARY(32),
    IN `inAccountResetTokenId` BINARY(32),
    IN `inTokenData` BINARY(32),
    IN `inUid` BINARY(16),
    IN `inCreatedAt` BIGINT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- ERROR
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Since we only ever want one accountResetToken per uid, then we
    -- do a replace - generally due to a collision on the unique uid field.
    REPLACE INTO accountResetTokens(
        tokenId,
        tokenData,
        uid,
        createdAt
    )
    VALUES(
        inAccountResetTokenId,
        inTokenData,
        inUid,
        inCreatedAt
    );

    DELETE FROM passwordForgotTokens WHERE tokenId = inPasswordForgotTokenId;

    UPDATE accounts SET emailVerified = true WHERE uid = inUid;
    UPDATE emails SET isVerified = true WHERE email = (SELECT email FROM accounts WHERE uid = inUid);

    COMMIT;
END;

CREATE PROCEDURE `verifyEmail_5`(
    IN `inUid` BINARY(16),
    IN `inEmailCode` BINARY(16)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE accounts SET emailVerified = true WHERE uid = inUid AND emailCode = inEmailCode;
    UPDATE emails SET isVerified = true WHERE uid = inUid AND emailCode = inEmailCode;

    COMMIT;
END;

UPDATE dbMetadata SET value = '49' WHERE name = 'schema-patch-level';
