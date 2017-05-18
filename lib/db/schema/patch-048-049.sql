CREATE PROCEDURE `setPrimaryEmail_1` (
  IN `inUid` BINARY(16),
  IN `inNormalizedEmail` VARCHAR(255)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  -- Check to see where the primary email for the account is located
  SET @primaryOnEmails = 0;
  SELECT COUNT(*) INTO @emailExists FROM emails WHERE uid = inUid AND isPrimary = true;

  IF @primaryOnEmails > 0 THEN
     UPDATE emails SET isPrimary = false WHERE uid = inUid AND isPrimary = true;
     UPDATE emails SET isPrimary = true WHERE uid = inUid AND normalizedEmail = inNormalizedEmail;
  ELSE
     INSERT INTO emails(
        normalizedEmail,
        email,
        uid,
        emailCode,
        isVerified,
        isPrimary,
        verifiedAt,
        createdAt
     )
     SELECT
        normalizedEmail,
        email,
        uid,
        emailCode,
        emailVerified,
        false,
        now,
        now
     FROM accounts WHERE uid = inUid;

     UPDATE emails SET isPrimary = true WHERE uid = inUid AND normalizedEmail = inNormalizedEmail;
  END IF;

  COMMIT;
END;

CREATE PROCEDURE `accountEmails_2` (
    IN `inUid` BINARY(16)
)
BEGIN
    DROP TEMPORARY TABLE IF EXISTS tempUserEmails;
    CREATE TEMPORARY TABLE IF NOT EXISTS tempUserEmails AS
    (SELECT
        normalizedEmail,
        email,
        uid,
        emailCode,
        isVerified,
        isPrimary,
        verifiedAt,
        createdAt
    FROM
        emails
    WHERE
        uid = inUid);

    SET @hasPrimary = 0;
    SELECT COUNT(*) INTO @hasPrimary FROM tempUserEmails WHERE uid = inUid AND isPrimary = true;
    IF @hasPrimary = 0 THEN
        INSERT INTO tempUserEmails
        SELECT
            normalizedEmail,
            email,
            uid,
            emailCode,
            emailVerified AS isVerified,
            TRUE AS isPrimary,
            createdAt AS verifiedAt,
            createdAt
        FROM
            accounts a
        WHERE
            uid = inUid;
    END IF;

    SELECT * FROM tempUserEmails ORDER BY createdAt;
END;

CREATE PROCEDURE `createAccount_7`(
    IN `inUid` BINARY(16) ,
    IN `inNormalizedEmail` VARCHAR(255),
    IN `inEmail` VARCHAR(255),
    IN `inEmailCode` BINARY(16),
    IN `inEmailVerified` TINYINT(1),
    IN `inKA` BINARY(32),
    IN `inWrapWrapKb` BINARY(32),
    IN `inAuthSalt` BINARY(32),
    IN `inVerifierVersion` TINYINT UNSIGNED,
    IN `inVerifyHash` BINARY(32),
    IN `inVerifierSetAt` BIGINT UNSIGNED,
    IN `inCreatedAt` BIGINT UNSIGNED,
    IN `inLocale` VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Check to see if the normalizedEmail exists in the emails table before creating a new user
    -- with this email.
    SET @emailExists = 0;
    SELECT COUNT(*) INTO @emailExists FROM emails WHERE normalizedEmail = inNormalizedEmail;
    IF @emailExists > 0 THEN
        SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1062, MESSAGE_TEXT = 'Unable to create user, email used belongs to another user.';
    END IF;

    INSERT INTO accounts(
        uid,
        normalizedEmail,
        email,
        emailCode,
        emailVerified,
        kA,
        wrapWrapKb,
        authSalt,
        verifierVersion,
        verifyHash,
        verifierSetAt,
        createdAt,
        locale
    )
    VALUES(
        inUid,
        LOWER(inNormalizedEmail),
        inEmail,
        inEmailCode,
        inEmailVerified,
        inKA,
        inWrapWrapKb,
        inAuthSalt,
        inVerifierVersion,
        inVerifyHash,
        inVerifierSetAt,
        inCreatedAt,
        inLocale
    );

    INSERT INTO emails(
        normalizedEmail,
        email,
        uid,
        emailCode,
        isVerified,
        isPrimary,
        createdAt
    )
    VALUES(
        LOWER(inNormalizedEmail),
        inEmail,
        inUid,
        inEmailCode,
        inEmailVerified,
        TRUE,
        inCreatedAt
    );

    COMMIT;
END;

UPDATE dbMetadata SET value = '49' WHERE name = 'schema-patch-level';
