--
-- Some palaver here about our schema and how it works.
-- And why we have all these stored procedures.

CREATE TABLE dbMetadata (
  name VARCHAR(255) NOT NULL PRIMARY KEY,
  value VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

INSERT INTO dbMetadata SET name = 'schema-patch-level', value = '1';

-- XXX TODO: which columns are utf8mb4 and which are not?
SET NAMES utf8mb4 COLLATE utf8mb4_bin;
ALTER DATABASE fxa CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

CREATE PROCEDURE `dbMetadata_1` (
    IN `inName` VARCHAR(255)
)
BEGIN
    SELECT value FROM dbMetadata WHERE name = inName;
END;


-- The main "accounts" table, and a secondary "emails" table.
CREATE TABLE IF NOT EXISTS accounts (
  uid BINARY(16) PRIMARY KEY,
  normalizedEmail VARCHAR(255) NOT NULL UNIQUE KEY,
  email VARCHAR(255) NOT NULL,
  emailCode BINARY(16) NOT NULL,
  emailVerified BOOLEAN NOT NULL DEFAULT FALSE,
  kA BINARY(32) NOT NULL,
  wrapWrapKb BINARY(32) NOT NULL,
  authSalt BINARY(32) NOT NULL,
  verifyHash BINARY(32) NOT NULL,
  verifierVersion TINYINT UNSIGNED NOT NULL,
  verifierSetAt BIGINT UNSIGNED NOT NULL,
  createdAt BIGINT UNSIGNED NOT NULL,
  locale VARCHAR(255),
  lockedAt BIGINT UNSIGNED DEFAULT NULL;
) ENGINE=InnoDB;


CREATE PROCEDURE `accountExists_2` (
    IN `inEmail` VARCHAR(255)
)
BEGIN
    SELECT uid FROM emails WHERE normalizedEmail = LOWER(inEmail) AND isPrimary = true;
END;



CREATE PROCEDURE `emailRecord_4` (
    IN `inEmail` VARCHAR(255)
)
BEGIN
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.lockedAt,
        a.createdAt
    FROM
        accounts a
    WHERE
        a.normalizedEmail = LOWER(inEmail)
    ;
END;

CREATE PROCEDURE `account_3` (
    IN `inUid` BINARY(16)
)
BEGIN
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.createdAt,
        a.locale,
        a.lockedAt
    FROM
        accounts a
    WHERE
        a.uid = LOWER(inUid)
    ;
END;


CREATE PROCEDURE `checkPassword_1` (
    IN `inUid` BINARY(16),
    IN `inVerifyHash` BINARY(32)
)
BEGIN
    SELECT uid FROM accounts WHERE uid = inUid AND verifyHash = inVerifyHash;
END;

CREATE PROCEDURE `updateLocale_1` (
    IN `inLocale` VARCHAR(255),
    IN `inUid` BINARY(16)
)
BEGIN
    UPDATE accounts SET locale = inLocale WHERE uid = inUid;
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
        true,
        inCreatedAt
    );

    COMMIT;
END;


CREATE PROCEDURE `resetAccount_8` (
  IN `uidArg` BINARY(16),
  IN `verifyHashArg` BINARY(32),
  IN `authSaltArg` BINARY(32),
  IN `wrapWrapKbArg` BINARY(32),
  IN `verifierSetAtArg` BIGINT UNSIGNED,
  IN `VerifierVersionArg` TINYINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DELETE FROM sessionTokens WHERE uid = uidArg;
  DELETE FROM keyFetchTokens WHERE uid = uidArg;
  DELETE FROM accountResetTokens WHERE uid = uidArg;
  DELETE FROM passwordChangeTokens WHERE uid = uidArg;
  DELETE FROM passwordForgotTokens WHERE uid = uidArg;
  DELETE FROM devices WHERE uid = uidArg;
  DELETE FROM unverifiedTokens WHERE uid = uidArg;

  UPDATE accounts
  SET
    verifyHash = verifyHashArg,
    authSalt = authSaltArg,
    wrapWrapKb = wrapWrapKbArg,
    verifierSetAt = verifierSetAtArg,
    verifierVersion = verifierVersionArg
  WHERE uid = uidArg;

  COMMIT;
END;


CREATE PROCEDURE `resetAccountTokens_1` (
  IN `uidArg` BINARY(16)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DELETE FROM accountResetTokens WHERE uid = uidArg;
  DELETE FROM passwordChangeTokens WHERE uid = uidArg;
  DELETE FROM passwordForgotTokens WHERE uid = uidArg;

  COMMIT;
END;

CREATE PROCEDURE `deleteAccount_14` (
  IN `uidArg` BINARY(16)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DELETE FROM sessionTokens WHERE uid = uidArg;
  DELETE FROM keyFetchTokens WHERE uid = uidArg;
  DELETE FROM accountResetTokens WHERE uid = uidArg;
  DELETE FROM passwordChangeTokens WHERE uid = uidArg;
  DELETE FROM passwordForgotTokens WHERE uid = uidArg;
  DELETE FROM accounts WHERE uid = uidArg;
  DELETE FROM devices WHERE uid = uidArg;
  DELETE FROM unverifiedTokens WHERE uid = uidArg;
  DELETE FROM unblockCodes WHERE uid = uidArg;
  DELETE FROM emails WHERE uid = uidArg;
  DELETE FROM signinCodes WHERE uid = uidArg;
  DELETE FROM totp WHERE uid = uidArg;

  COMMIT;
END;


-- Emails.

CREATE TABLE IF NOT EXISTS emails (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  normalizedEmail VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  uid BINARY(16) NOT NULL,
  emailCode BINARY(16) NOT NULL,
  isVerified BOOLEAN NOT NULL DEFAULT FALSE,
  isPrimary BOOLEAN NOT NULL DEFAULT FALSE,
  verifiedAt BIGINT UNSIGNED,
  createdAt BIGINT UNSIGNED NOT NULL,
  UNIQUE KEY (`normalizedEmail`),
  INDEX `emails_uid` (`uid`)
) ENGINE=InnoDB;



CREATE PROCEDURE `createEmail_2` (
    IN `normalizedEmail` VARCHAR(255),
    IN `email` VARCHAR(255),
    IN `uid` BINARY(16) ,
    IN `emailCode` BINARY(16),
    IN `isVerified` TINYINT(1),
    IN `verifiedAt` BIGINT UNSIGNED,
    IN `createdAt` BIGINT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

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
    VALUES(
        LOWER(normalizedEmail),
        email,
        uid,
        emailCode,
        isVerified,
        false,
        verifiedAt,
        createdAt
    );

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


-- Differs from `emailRecord` that returns a filtered account object
CREATE PROCEDURE `getSecondaryEmail_1` (
    IN `emailArg` VARCHAR(255)
)
BEGIN
    SELECT * FROM emails WHERE normalizedEmail = LOWER(emailArg);
END;

CREATE PROCEDURE `accountEmails_4` (
    IN `inUid` BINARY(16)
)
BEGIN
    SELECT * FROM emails WHERE uid = inUid ORDER BY isPrimary=true DESC;
END;


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
     UPDATE emails SET isPrimary = false WHERE uid = inUid AND isPrimary = true;
     UPDATE emails SET isPrimary = true WHERE uid = inUid AND isPrimary = false AND normalizedEmail = inNormalizedEmail;

     SELECT ROW_COUNT() INTO @updateCount;
     IF @updateCount = 0 THEN
        SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1062, MESSAGE_TEXT = 'Can not change email. Could not find email.';
     END IF;
  COMMIT;
END;

CREATE PROCEDURE `accountRecord_2` (
  IN `inEmail` VARCHAR(255)
)
BEGIN
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.createdAt,
        a.locale,
        a.lockedAt,
        e.normalizedEmail AS primaryEmail
    FROM
        accounts a,
        emails e
    WHERE
        a.uid = (SELECT uid FROM emails WHERE normalizedEmail = LOWER(inEmail))
    AND
        a.uid = e.uid
    AND
        e.isPrimary = true;
END;

CREATE PROCEDURE `deleteEmail_2` (
    IN `inUid` BINARY(16),
    IN `inNormalizedEmail` VARCHAR(255)
)
BEGIN
    SET @primaryEmailCount = 0;

    -- Don't delete primary email addresses
    SELECT COUNT(*) INTO @primaryEmailCount FROM emails WHERE normalizedEmail = inNormalizedEmail AND uid = inUid AND isPrimary = true;
    IF @primaryEmailCount = 1 THEN
        SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 2100, MESSAGE_TEXT = 'Can not delete a primary email address.';
    END IF;

    DELETE FROM emails WHERE normalizedEmail = inNormalizedEmail AND uid = inUid AND isPrimary = false;
END;


-- Various kinds of security-related tokens.

-- Session Tokens.

CREATE TABLE IF NOT EXISTS sessionTokens (
  tokenId BINARY(32) PRIMARY KEY,
  tokenData BINARY(32) NOT NULL,
  uid BINARY(16) NOT NULL,
  createdAt BIGINT UNSIGNED NOT NULL,
  INDEX session_uid (uid),
  uaBrowser VARCHAR(255),
  uaBrowserVersion VARCHAR(255),
  uaOS VARCHAR(255),
  uaOSVersion VARCHAR(255),
  uaDeviceType VARCHAR(255),
  lastAccessTime BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `uaFormFactor` VARCHAR(255),
  `authAt` BIGINT UNSIGNED DEFAULT NULL,
  INDEX `sessionTokens_createdAt` (`createdAt`)
) ENGINE=InnoDB;

CREATE TABLE unverifiedTokens (
  tokenId BINARY(32) NOT NULL PRIMARY KEY,
  tokenVerificationId BINARY(16) NOT NULL,
  uid BINARY(16) NOT NULL,
  mustVerify BOOLEAN NOT NULL DEFAULT TRUE,
  `tokenVerificationCodeHash` BINARY(32) DEFAULT NULL,
  `tokenVerificationCodeExpiresAt` BIGINT UNSIGNED DEFAULT NULL,
  INDEX unverifiedToken_uid_tokenVerificationId (uid, tokenVerificationId),
  UNIQUE INDEX `unverifiedTokens_tokenVerificationCodeHash_uid` (`tokenVerificationCodeHash`, `uid`)
) ENGINE=InnoDB;

CREATE PROCEDURE `verifyToken_3` (
  IN `tokenVerificationIdArg` BINARY(16),
  IN `uidArg` BINARY(16)
)
BEGIN
  UPDATE securityEvents
  SET verified = true
  WHERE tokenVerificationId = tokenVerificationIdArg
  AND uid = uidArg;

  DELETE FROM unverifiedTokens
  WHERE tokenVerificationId = tokenVerificationIdArg
  AND uid = uidArg;
END;

CREATE PROCEDURE `verifyTokenCode_1` (
  IN `tokenVerificationCodeHashArg` BINARY(32),
  IN `uidArg` BINARY(16)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET @tokenVerificationId = NULL;
  SELECT tokenVerificationId INTO @tokenVerificationId FROM unverifiedTokens
    WHERE uid = uidArg
    AND tokenVerificationCodeHash = tokenVerificationCodeHashArg
    AND tokenVerificationCodeExpiresAt >= (UNIX_TIMESTAMP(NOW(3)) * 1000);

  IF @tokenVerificationId IS NULL THEN
    SET @expiredCount = 0;
    SELECT COUNT(*) INTO @expiredCount FROM unverifiedTokens
      WHERE uid = uidArg
      AND tokenVerificationCodeHash = tokenVerificationCodeHashArg
      AND tokenVerificationCodeExpiresAt < (UNIX_TIMESTAMP(NOW(3)) * 1000);

    IF @expiredCount > 0 THEN
      SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 2101, MESSAGE_TEXT = 'Expired token verification code.';
    END IF;
  END IF;

  START TRANSACTION;
    UPDATE securityEvents
    SET verified = true
    WHERE tokenVerificationId = @tokenVerificationId
    AND uid = uidArg;

    DELETE FROM unverifiedTokens
    WHERE tokenVerificationId = @tokenVerificationId
    AND uid = uidArg;

    SET @updateCount = (SELECT ROW_COUNT());
  COMMIT;

  SELECT @updateCount;
END;

CREATE PROCEDURE `createSessionToken_8` (
  IN `tokenId` BINARY(32),
  IN `tokenData` BINARY(32),
  IN `uid` BINARY(16),
  IN `createdAt` BIGINT UNSIGNED,
  IN `uaBrowser` VARCHAR(255),
  IN `uaBrowserVersion` VARCHAR(255),
  IN `uaOS` VARCHAR(255),
  IN `uaOSVersion` VARCHAR(255),
  IN `uaDeviceType` VARCHAR(255),
  IN `uaFormFactor` VARCHAR(255),
  IN `tokenVerificationId` BINARY(16),
  IN `mustVerify` BOOLEAN,
  IN `tokenVerificationCodeHash` BINARY(32),
  IN `tokenVerificationCodeExpiresAt` BIGINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  INSERT INTO sessionTokens(
    tokenId,
    tokenData,
    uid,
    createdAt,
    uaBrowser,
    uaBrowserVersion,
    uaOS,
    uaOSVersion,
    uaDeviceType,
    uaFormFactor,
    lastAccessTime
  )
  VALUES(
    tokenId,
    tokenData,
    uid,
    createdAt,
    uaBrowser,
    uaBrowserVersion,
    uaOS,
    uaOSVersion,
    uaDeviceType,
    uaFormFactor,
    createdAt
  );

  IF tokenVerificationId IS NOT NULL THEN
    INSERT INTO unverifiedTokens(
      tokenId,
      tokenVerificationId,
      uid,
      mustVerify,
      tokenVerificationCodeHash,
      tokenVerificationCodeExpiresAt
    )
    VALUES(
      tokenId,
      tokenVerificationId,
      uid,
      mustVerify,
      tokenVerificationCodeHash,
      tokenVerificationCodeExpiresAt
    );
  END IF;

  COMMIT;
END;

CREATE PROCEDURE `sessionToken_8` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.tokenData,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    e.isVerified AS emailVerified,
    e.email,
    e.emailCode,
    a.verifierSetAt,
    a.locale,
    a.createdAt AS accountCreatedAt
  FROM sessionTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
    AND e.isPrimary = true
  WHERE t.tokenId = tokenIdArg;
END;

CREATE PROCEDURE `sessionWithDevice_11` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.tokenData,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    e.isVerified AS emailVerified,
    e.email,
    e.emailCode,
    a.verifierSetAt,
    a.locale,
    a.createdAt AS accountCreatedAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    ut.tokenVerificationId,
    ut.mustVerify
  FROM sessionTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
    AND e.isPrimary = true
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  LEFT JOIN unverifiedTokens AS ut
    ON t.tokenId = ut.tokenId
  WHERE t.tokenId = tokenIdArg;
END;


CREATE PROCEDURE `sessions_8` (
  IN `uidArg` BINARY(16)
)
BEGIN
  SELECT
    t.tokenId,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired
  FROM sessionTokens AS t
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  WHERE t.uid = uidArg;
END;


CREATE PROCEDURE `updateSessionToken_2` (
    IN tokenIdArg BINARY(32),
    IN uaBrowserArg VARCHAR(255),
    IN uaBrowserVersionArg VARCHAR(255),
    IN uaOSArg VARCHAR(255),
    IN uaOSVersionArg VARCHAR(255),
    IN uaDeviceTypeArg VARCHAR(255),
    IN uaFormFactorArg VARCHAR(255),
    IN lastAccessTimeArg BIGINT UNSIGNED,
    IN authAtArg BIGINT UNSIGNED,
    IN mustVerifyArg BOOLEAN
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  UPDATE sessionTokens
    SET uaBrowser = COALESCE(uaBrowserArg, uaBrowser),
      uaBrowserVersion = COALESCE(uaBrowserVersionArg, uaBrowserVersion),
      uaOS = COALESCE(uaOSArg, uaOS),
      uaOSVersion = COALESCE(uaOSVersionArg, uaOSVersion),
      uaDeviceType = COALESCE(uaDeviceTypeArg, uaDeviceType),
      uaFormFactor = COALESCE(uaFormFactorArg, uaFormFactor),
      lastAccessTime = COALESCE(lastAccessTimeArg, lastAccessTime),
      authAt = COALESCE(authAtArg, authAt, createdAt)
    WHERE tokenId = tokenIdArg;

  -- Allow updating mustVerify from FALSE to TRUE,
  -- but not the other way around.
  IF mustVerifyArg THEN
    UPDATE unverifiedTokens
      SET mustVerify = TRUE
      WHERE tokenId = tokenIdArg;
  END IF;

  COMMIT;
END;


CREATE PROCEDURE `deleteSessionToken_3` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  -- The 'devices' table has an index on (uid, sessionTokenId),
  -- so we have to look up the uid in order to do this efficiently.
  DELETE FROM devices
    WHERE sessionTokenId = tokenIdArg
    AND uid = (SELECT uid FROM sessionTokens WHERE tokenId = tokenIdArg);
  DELETE FROM sessionTokens WHERE tokenId = tokenIdArg;
  DELETE FROM unverifiedTokens WHERE tokenId = tokenIdArg;

  COMMIT;
END;

-- Key-fetch tokens.

CREATE TABLE IF NOT EXISTS keyFetchTokens (
  tokenId BINARY(32) PRIMARY KEY,
  authKey BINARY(32) NOT NULL,
  uid BINARY(16) NOT NULL,
  keyBundle BINARY(96) NOT NULL,
  createdAt BIGINT UNSIGNED NOT NULL,
  INDEX key_uid (uid)
) ENGINE=InnoDB;


CREATE PROCEDURE `keyFetchToken_1` (
    IN `inTokenId` BINARY(32)
)
BEGIN
    SELECT
        t.authKey,
        t.uid,
        t.keyBundle,
        t.createdAt,
        a.emailVerified,
        a.verifierSetAt
    FROM
        keyFetchTokens t,
        accounts a
    WHERE
        t.tokenId = inTokenId
    AND
        t.uid = a.uid
    ;
END;



CREATE PROCEDURE `createKeyFetchToken_2` (
  IN `tokenId` BINARY(32),
  IN `authKey` BINARY(32),
  IN `uid` BINARY(16),
  IN `keyBundle` BINARY(96),
  IN `createdAt` BIGINT UNSIGNED,
  IN `tokenVerificationId` BINARY(16)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  INSERT INTO keyFetchTokens(
    tokenId,
    authKey,
    uid,
    keyBundle,
    createdAt
  )
  VALUES(
    tokenId,
    authKey,
    uid,
    keyBundle,
    createdAt
  );

  IF tokenVerificationId IS NOT NULL THEN
    INSERT INTO unverifiedTokens(
      tokenId,
      tokenVerificationId,
      uid
    )
    VALUES(
      tokenId,
      tokenVerificationId,
      uid
    );
  END IF;

  COMMIT;
END;

CREATE PROCEDURE `deleteKeyFetchToken_2` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DELETE FROM keyFetchTokens WHERE tokenId = tokenIdArg;
  DELETE FROM unverifiedTokens WHERE tokenId = tokenIdArg;

  COMMIT;
END;


CREATE PROCEDURE `keyFetchTokenWithVerificationStatus_2` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.authKey,
    t.uid,
    t.keyBundle,
    t.createdAt,
    e.isVerified AS emailVerified,
    a.verifierSetAt,
    ut.tokenVerificationId
  FROM keyFetchTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
  LEFT JOIN unverifiedTokens AS ut
    ON t.tokenId = ut.tokenId
  WHERE t.tokenId = tokenIdArg
  AND e.isPrimary = true;
END;

-- Account reset tokens.

CREATE TABLE IF NOT EXISTS accountResetTokens (
  tokenId BINARY(32) PRIMARY KEY,
  tokenData BINARY(32) NOT NULL,
  uid BINARY(16) NOT NULL UNIQUE KEY,
  createdAt BIGINT UNSIGNED NOT NULL,
  INDEX createdAt (createdAt),
) ENGINE=InnoDB;

CREATE PROCEDURE `createAccountResetToken_2` (
    IN tokenId BINARY(32),
    IN tokenData BINARY(32),
    IN uid BINARY(16),
    IN createdAt BIGINT UNSIGNED
)
BEGIN
    -- Since we only ever want one accountResetToken per uid, then we
    -- do a replace - generally due to a collision on the unique uid field.
    REPLACE INTO accountResetTokens(
        tokenId,
        tokenData,
        uid,
        createdAt
    )
    VALUES(
        tokenId,
        tokenData,
        uid,
        createdAt
    );
END;

CREATE PROCEDURE `accountResetToken_1` (
    IN `inTokenId` BINARY(32)
)
BEGIN
    SELECT
        t.uid,
        t.tokenData,
        t.createdAt,
        a.verifierSetAt
    FROM
        accountResetTokens t,
        accounts a
    WHERE
        t.tokenId = inTokenId
    AND
        t.uid = a.uid
    ;
END;


CREATE PROCEDURE `deleteAccountResetToken_1` (
    IN `inTokenId` BINARY(32)
)
BEGIN
    DELETE FROM accountResetTokens WHERE tokenId = inTokenId;
END;


-- Password forgot tokens.

CREATE TABLE IF NOT EXISTS passwordForgotTokens (
  tokenId BINARY(32) PRIMARY KEY,
  tokenData BINARY(32) NOT NULL,
  uid BINARY(16) NOT NULL UNIQUE KEY,
  passCode BINARY(16) NOT NULL,
  createdAt BIGINT UNSIGNED NOT NULL,
  tries SMALLINT UNSIGNED NOT NULL,
  INDEX createdAt (createdAt)
) ENGINE=InnoDB;

CREATE PROCEDURE `createPasswordForgotToken_2` (
    IN tokenId BINARY(32),
    IN tokenData BINARY(32),
    IN uid BINARY(16),
    IN passCode BINARY(16),
    IN createdAt BIGINT UNSIGNED,
    IN tries SMALLINT
)
BEGIN
    -- Since we only ever want one passwordForgotToken per uid, then we
    -- do a replace - generally due to a collision on the unique uid field.
    REPLACE INTO passwordForgotTokens(
        tokenId,
        tokenData,
        uid,
        passCode,
        createdAt,
        tries
    )
    VALUES(
        tokenId,
        tokenData,
        uid,
        passCode,
        createdAt,
        tries
    );
END;

CREATE PROCEDURE `passwordForgotToken_2` (
    IN `inTokenId` BINARY(32)
)
BEGIN
    SELECT
        t.uid,
        t.tokenData,
        t.createdAt,
        t.passCode,
        t.tries,
        e.email,
        a.verifierSetAt
    FROM
        passwordForgotTokens t,
        accounts a,
        emails e
    WHERE
        t.tokenId = inTokenId
    AND
        t.uid = a.uid
    AND
        t.uid = e.uid
    AND
        e.isPrimary = true
    ;
END;



CREATE PROCEDURE `updatePasswordForgotToken_1` (
    IN `inTries` SMALLINT UNSIGNED,
    IN `inTokenId` BINARY(32)
)
BEGIN
    UPDATE passwordForgotTokens SET tries = inTries WHERE tokenId = inTokenId;
END;

CREATE PROCEDURE `forgotPasswordVerified_7` (
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
    UPDATE emails SET isVerified = true WHERE isPrimary = true AND uid = inUid;

    COMMIT;
END;


CREATE PROCEDURE `deletePasswordForgotToken_1` (
    IN `inTokenId` BINARY(32)
)
BEGIN
    DELETE FROM passwordForgotTokens WHERE tokenId = inTokenId;
END;


-- Password change tokens.

CREATE TABLE IF NOT EXISTS passwordChangeTokens (
  tokenId BINARY(32) PRIMARY KEY,
  tokenData BINARY(32) NOT NULL,
  uid BINARY(16) NOT NULL,
  createdAt BIGINT UNSIGNED NOT NULL,
  INDEX session_uid (uid), // XXX TODO: why is this named `session_uid`?
  INDEX createdAt (createdAt),
  UNIQUE INDEX `uid` (uid);
) ENGINE=InnoDB;

CREATE PROCEDURE `createPasswordChangeToken_2` (
    IN tokenId BINARY(32),
    IN tokenData BINARY(32),
    IN uid BINARY(16),
    IN createdAt BIGINT UNSIGNED
)
BEGIN
    -- Since we only ever want one passwordChangeToken per uid, then we
    -- do a replace - generally due to a collision on the unique uid field.
    REPLACE INTO passwordChangeTokens(
        tokenId,
        tokenData,
        uid,
        createdAt
    )
    VALUES(
        tokenId,
        tokenData,
        uid,
        createdAt
    );
END;


CREATE PROCEDURE `passwordChangeToken_3` (
    IN `inTokenId` BINARY(32)
)
BEGIN
    SELECT
        t.uid,
        t.tokenData,
        t.createdAt,
        a.verifierSetAt
    FROM
        passwordChangeTokens t,
        accounts a,
        emails e
    WHERE
        t.tokenId = inTokenId
    AND
        t.uid = a.uid
    AND
        t.uid = e.uid;
END;



CREATE PROCEDURE `deletePasswordChangeToken_1` (
    IN `inTokenId` BINARY(32)
)
BEGIN
    DELETE FROM passwordChangeTokens WHERE tokenId = inTokenId;
END;


-- Unblock codes.

CREATE TABLE IF NOT EXISTS unblockCodes (
  uid BINARY(16) NOT NULL,
  unblockCodeHash BINARY(32) NOT NULL,
  createdAt BIGINT SIGNED NOT NULL,
  PRIMARY KEY(uid, unblockCodeHash),
  INDEX unblockCodes_createdAt (createdAt)
) ENGINE=InnoDB;

CREATE PROCEDURE `createUnblockCode_1` (
    IN inUid BINARY(16),
    IN inCodeHash BINARY(32),
    IN inCreatedAt BIGINT SIGNED
)
BEGIN
    INSERT INTO unblockCodes(
        uid,
        unblockCodeHash,
        createdAt
    )
    VALUES(
        inUid,
        inCodeHash,
        inCreatedAt
    );
END;

CREATE PROCEDURE `consumeUnblockCode_1` (
    inUid BINARY(16),
    inCodeHash BINARY(32)
)
BEGIN
    DECLARE timestamp BIGINT;
    SET @timestamp = (
        SELECT createdAt FROM unblockCodes
        WHERE
            uid = inUid
        AND
            unblockCodeHash = inCodeHash
    );

    DELETE FROM unblockCodes
    WHERE
        uid = inUid
    AND
        unblockCodeHash = inCodeHash;

    SELECT @timestamp AS createdAt;
END;


-- Signin codes

CREATE TABLE IF NOT EXISTS `signinCodes` (
  hash BINARY(32) NOT NULL PRIMARY KEY,
  uid BINARY(16) NOT NULL,
  createdAt BIGINT UNSIGNED NOT NULL,
  `flowId` BINARY(32),
  INDEX signinCodes_createdAt (createdAt)
) ENGINE=InnoDB;

CREATE PROCEDURE `createSigninCode_2` (
  IN `hashArg` BINARY(32),
  IN `uidArg` BINARY(16),
  IN `createdAtArg` BIGINT UNSIGNED,
  IN `flowIdArg` BINARY(32)
)
BEGIN
  INSERT INTO signinCodes(hash, uid, createdAt, flowId)
  VALUES(hashArg, uidArg, createdAtArg, flowIdArg);
END;


CREATE PROCEDURE `consumeSigninCode_4` (
  IN `hashArg` BINARY(32),
  IN `newerThanArg` BIGINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT sc.flowId, e.email
  FROM signinCodes AS sc
  INNER JOIN emails AS e
  ON sc.hash = hashArg
  AND sc.createdAt > newerThanArg
  AND sc.uid = e.uid
  AND e.isPrimary = true;

  DELETE FROM signinCodes
  WHERE hash = hashArg
  AND createdAt > newerThanArg;

  COMMIT;
END;

-- Token pruning.

INSERT INTO dbMetadata SET name = 'prune-last-ran', value = '0';

-- Used to prevent session token pruning from doing a full table scan
-- as it proceeds further and further through the (very long) backlog
-- of pruning candidates.
INSERT INTO dbMetadata (name, value)
VALUES ('sessionTokensPrunedUntil', 0);

CREATE PROCEDURE `prune_7` (IN `olderThanArg` BIGINT UNSIGNED)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT @lockAcquired := GET_LOCK('fxa-auth-server.prune-lock', 3);

  IF @lockAcquired THEN
    DELETE FROM accountResetTokens WHERE createdAt < olderThanArg ORDER BY createdAt LIMIT 10000;
    DELETE FROM passwordForgotTokens WHERE createdAt < olderThanArg ORDER BY createdAt LIMIT 10000;
    DELETE FROM passwordChangeTokens WHERE createdAt < olderThanArg ORDER BY createdAt LIMIT 10000;
    DELETE FROM unblockCodes WHERE createdAt < olderThanArg ORDER BY createdAt LIMIT 10000;
    DELETE FROM signinCodes WHERE createdAt < olderThanArg ORDER BY createdAt LIMIT 10000;

    -- Pruning session tokens is complicated because:
    --   * we can't prune them if there is an associated device record, and
    --   * we have to delete from both sessionTokens and unverifiedTokens tables, and
    --   * MySQL won't allow `LIMIT` to be used in a multi-table delete.
    -- To achieve all this in an efficient manner, we prune tokens within a specific
    -- time window rather than using a `LIMIT` clause.  At the end of each run we
    -- record the new lower-bound on creation time for tokens that might have expired.
    START TRANSACTION;

    -- Step 1: Find out how far we got on previous iterations.
    SELECT @pruneFrom := value FROM dbMetadata WHERE name = 'sessionTokensPrunedUntil';

    -- Step 2: Calculate what timestamp we will reach on this iteration
    -- if we purge a sensibly-sized batch of tokens.
    -- N.B. We deliberately do not filter on whether the token has
    -- a device here.  We want to limit the number of tokens that we
    -- *examine*, regardless of whether it actually delete them.
    SELECT @pruneUntil := MAX(createdAt) FROM (
      SELECT createdAt FROM sessionTokens
      WHERE createdAt >= @pruneFrom AND createdAt < olderThanArg
      ORDER BY createdAt
      LIMIT 10000
    ) AS candidatesForPruning;

    -- This will be NULL if there are no expired tokens,
    -- in which case we have nothing to do.
    IF @pruneUntil IS NOT NULL THEN

      -- Step 3: Prune sessionTokens and unverifiedTokens tables.
      -- Here we *do* filter on whether a device record exists.
      -- We might not actually delete any tokens, but we will definitely
      -- be able to increase 'sessionTokensPrunedUntil' for the next run.
      DELETE st, ut
      FROM sessionTokens AS st
      LEFT JOIN unverifiedTokens AS ut
      ON st.tokenId = ut.tokenId
      WHERE st.createdAt > @pruneFrom
      AND st.createdAt <= @pruneUntil
      AND NOT EXISTS (
        SELECT sessionTokenId FROM devices
        WHERE uid = st.uid AND sessionTokenId = st.tokenId
      );

      -- Step 4: Tell following iterations how far we got.
      UPDATE dbMetadata
      SET value = @pruneUntil
      WHERE name = 'sessionTokensPrunedUntil';

    END IF;

    COMMIT;

    SELECT RELEASE_LOCK('fxa-auth-server.prune-lock');
  END IF;
END;

-- Devices

CREATE TABLE devices (
  uid BINARY(16) NOT NULL,
  id BINARY(16) NOT NULL,
  sessionTokenId BINARY(32),
  name VARCHAR(255),
  nameUtf8 VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  type VARCHAR(16),
  createdAt BIGINT UNSIGNED,
  callbackURL VARCHAR(255),
  PRIMARY KEY (uid, id),
  callbackPublicKey CHAR(88),
  callbackAuthKey CHAR(24),
  callbackIsExpired BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE KEY UQ_devices_sessionTokenId (uid, sessionTokenId)
) ENGINE=InnoDB;

CREATE PROCEDURE `createDevice_4` (
  IN `inUid` BINARY(16),
  IN `inId` BINARY(16),
  IN `inSessionTokenId` BINARY(32),
  IN `inNameUtf8` VARCHAR(255),
  IN `inType` VARCHAR(16),
  IN `inCreatedAt` BIGINT UNSIGNED,
  IN `inCallbackURL` VARCHAR(255),
  IN `inCallbackPublicKey` CHAR(88),
  IN `inCallbackAuthKey` CHAR(24)
)
BEGIN
  INSERT INTO devices(
    uid,
    id,
    sessionTokenId,
    nameUtf8,
    type,
    createdAt,
    callbackURL,
    callbackPublicKey,
    callbackAuthKey
  )
  VALUES (
    inUid,
    inId,
    inSessionTokenId,
    inNameUtf8,
    inType,
    inCreatedAt,
    inCallbackURL,
    inCallbackPublicKey,
    inCallbackAuthKey
  );
END;

CREATE PROCEDURE `updateDevice_5` (
  IN `inUid` BINARY(16),
  IN `inId` BINARY(16),
  IN `inSessionTokenId` BINARY(32),
  IN `inNameUtf8` VARCHAR(255),
  IN `inType` VARCHAR(16),
  IN `inCallbackURL` VARCHAR(255),
  IN `inCallbackPublicKey` CHAR(88),
  IN `inCallbackAuthKey` CHAR(24),
  IN `inCallbackIsExpired` BOOLEAN
)
BEGIN
  UPDATE devices
  SET sessionTokenId = COALESCE(inSessionTokenId, sessionTokenId),
    nameUtf8 = COALESCE(inNameUtf8, nameUtf8),
    type = COALESCE(inType, type),
    callbackURL = COALESCE(inCallbackURL, callbackURL),
    callbackPublicKey = COALESCE(inCallbackPublicKey, callbackPublicKey),
    callbackAuthKey = COALESCE(inCallbackAuthKey, callbackAuthKey),
    callbackIsExpired = COALESCE(inCallbackIsExpired, callbackIsExpired)
  WHERE uid = inUid AND id = inId;
END;


CREATE PROCEDURE `accountDevices_12` (
  IN `uidArg` BINARY(16)
)
BEGIN
  SELECT
    d.uid,
    d.id,
    d.sessionTokenId,
    d.nameUtf8 AS name,
    d.type,
    d.createdAt,
    d.callbackURL,
    d.callbackPublicKey,
    d.callbackAuthKey,
    d.callbackIsExpired,
    s.uaBrowser,
    s.uaBrowserVersion,
    s.uaOS,
    s.uaOSVersion,
    s.uaDeviceType,
    s.uaFormFactor,
    s.lastAccessTime,
    e.email
  FROM devices AS d
  INNER JOIN sessionTokens AS s
    ON d.sessionTokenId = s.tokenId
  INNER JOIN emails AS e
    ON d.uid = e.uid
    AND e.isPrimary = true
  WHERE d.uid = uidArg;
END;


CREATE PROCEDURE `deviceFromTokenVerificationId_3` (
    IN inUid BINARY(16),
    IN inTokenVerificationId BINARY(16)
)
BEGIN
    SELECT
        d.id,
        d.nameUtf8 AS name,
        d.type,
        d.createdAt,
        d.callbackURL,
        d.callbackPublicKey,
        d.callbackAuthKey,
        d.callbackIsExpired
    FROM unverifiedTokens AS u
    INNER JOIN devices AS d
        ON (u.tokenId = d.sessionTokenId AND u.uid = d.uid)
    WHERE u.uid = inUid AND u.tokenVerificationId = inTokenVerificationId;
END;


CREATE PROCEDURE `deleteDevice_3` (
  IN `uidArg` BINARY(16),
  IN `idArg` BINARY(16)
)
BEGIN
  SELECT devices.sessionTokenId FROM devices
  WHERE devices.uid = uidArg AND devices.id = idArg;

  DELETE devices, sessionTokens, unverifiedTokens
  FROM devices
  LEFT JOIN sessionTokens
    ON devices.sessionTokenId = sessionTokens.tokenId
  LEFT JOIN unverifiedTokens
    ON sessionTokens.tokenId = unverifiedTokens.tokenId
  WHERE devices.uid = uidArg
    AND devices.id = idArg;
END;


-- TOTP tokens


CREATE TABLE IF NOT EXISTS totp (
  uid BINARY(16) NOT NULL,
  sharedSecret VARCHAR(80) NOT NULL,
  epoch BIGINT NOT NULL,
  createdAt BIGINT UNSIGNED NOT NULL,
  UNIQUE KEY (`uid`)
) ENGINE=InnoDB;

CREATE PROCEDURE `createTotpToken_1` (
  IN `uidArg` BINARY(16),
  IN `sharedSecretArg` VARCHAR(80),
  IN `epochArg` BIGINT UNSIGNED,
  IN `createdAtArg` BIGINT UNSIGNED
)
BEGIN

  INSERT INTO totp(
    uid,
    sharedSecret,
    epoch,
    createdAt
  )
  VALUES(
    uidArg,
    sharedSecretArg,
    epochArg,
    createdAtArg
  );

END;

CREATE PROCEDURE `totpToken_1` (
  IN `uidArg` BINARY(16)
)
BEGIN

  SELECT sharedSecret, epoch FROM totp WHERE uid = uidArg;

END;

CREATE PROCEDURE `deleteTotpToken_1` (
  IN `uidArg` BINARY(16)
)
BEGIN

  DELETE FROM totp WHERE uid = uidArg;

END;

-- Security events

CREATE TABLE IF NOT EXISTS securityEventNames (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  UNIQUE INDEX securityEventNamesUnique(name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS securityEvents (
  uid BINARY(16) NOT NULL,
  nameId INT NOT NULL,
  FOREIGN KEY (nameId) REFERENCES securityEventNames(id) ON DELETE CASCADE,
  verified BOOLEAN,
  ipAddrHmac BINARY(32) NOT NULL,
  createdAt BIGINT SIGNED NOT NULL,
  tokenVerificationId BINARY(16),
  INDEX securityEvents_uid_tokenVerificationId (uid, tokenVerificationId),
  INDEX securityEvents_uid_ipAddrHmac_createdAt (uid, ipAddrHmac, createdAt)
) ENGINE=InnoDB;


INSERT INTO
    securityEventNames (name)
VALUES
    ("account.create"),
    ("account.login"),
    ("account.reset");


CREATE PROCEDURE `createSecurityEvent_3` (
    IN inUid BINARY(16),
    IN inToken BINARY(32),
    IN inName INT,
    IN inIpAddr BINARY(32),
    IN inCreatedAt BIGINT SIGNED
)
BEGIN
    DECLARE inTokenVerificationId BINARY(16);
    SET inTokenVerificationId = (
      SELECT tokenVerificationId
      FROM unverifiedTokens u
      WHERE u.uid = inUid AND u.tokenId = inToken
    );
    INSERT INTO securityEvents(
        uid,
        tokenVerificationId,
        verified,
        nameId,
        ipAddrHmac,
        createdAt
    )
    VALUES(
        inUid,
        inTokenVerificationId,
        inTokenVerificationId IS NULL,
        inName,
        inIpAddr,
        inCreatedAt
    );
END;

CREATE PROCEDURE `fetchSecurityEvents_1` (
    IN inUid BINARY(16),
    IN inIpAddr BINARY(32)
)
BEGIN
    SELECT
        n.name,
        e.verified,
        e.createdAt
    FROM
        securityEvents e
    LEFT JOIN securityEventNames n
        ON e.nameId = n.id
    WHERE
        e.uid = inUid
    AND
        e.ipAddrHmac = inIpAddr
    ORDER BY e.createdAt DESC
    LIMIT 50;
END;


-- Email Bounces.


CREATE TABLE IF NOT EXISTS emailBounces (
  email VARCHAR(255) NOT NULL,
  bounceType TINYINT UNSIGNED NOT NULL,
  bounceSubType TINYINT UNSIGNED NOT NULL,
  createdAt BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(email, createdAt)
) ENGINE=InnoDB;

CREATE PROCEDURE `createEmailBounce_1` (
  IN inEmail VARCHAR(255),
  IN inBounceType TINYINT UNSIGNED,
  IN inBounceSubType TINYINT UNSIGNED,
  IN inCreatedAt BIGINT UNSIGNED
)
BEGIN
  INSERT INTO emailBounces(
    email,
    bounceType,
    bounceSubType,
    createdAt
  )
  VALUES(
    inEmail,
    inBounceType,
    inBounceSubType,
    inCreatedAt
  );
END;

CREATE PROCEDURE `fetchEmailBounces_1` (
  IN `inEmail` VARCHAR(255)
)
BEGIN
  SELECT
      email,
      bounceType,
      bounceSubType,
      createdAt
  FROM emailBounces
  WHERE email = inEmail
  ORDER BY createdAt DESC
  LIMIT 20;
END;

-- Verification reminders.
-- Pretty sure these are no longer used...


CREATE TABLE verificationReminders (
  uid BINARY(16) NOT NULL,
  type VARCHAR(255) NOT NULL,
  createdAt BIGINT SIGNED NOT NULL,
  PRIMARY KEY(uid, type),
  INDEX reminder_createdAt (createdAt)
) ENGINE=InnoDB;


CREATE PROCEDURE `createVerificationReminder_2` (
    IN uid BINARY(16),
    IN type VARCHAR(255),
    IN createdAt BIGINT SIGNED
)
BEGIN
    INSERT INTO verificationReminders(
        uid,
        type,
        createdAt
    )
    VALUES(
        uid,
        type,
        createdAt
    );
END;


CREATE PROCEDURE `fetchVerificationReminders_2` (
    IN currentTimeArg BIGINT SIGNED,
    IN reminderTypeArg VARCHAR(255),
    IN reminderTimeArg BIGINT SIGNED,
    IN reminderTimeOutdatedArg BIGINT SIGNED,
    IN reminderLimitArg INTEGER
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    DO RELEASE_LOCK('fxa-auth-server.verification-reminders-lock');
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DO @lockAcquired:=GET_LOCK('fxa-auth-server.verification-reminders-lock', 1);

  IF @lockAcquired THEN
    DROP TEMPORARY TABLE IF EXISTS reminderResults;

    -- Select these straight into the temporary table
    -- and avoid using a cursor. Use ORDER BY to
    -- ensure the query is deterministic.
    CREATE TEMPORARY TABLE reminderResults AS
      SELECT uid, type
      FROM verificationReminders
      -- Since we want to order by `createdAt`, we have to rearrange
      -- the `WHERE` clauses so `createdAt` is positive rather than negated.
      WHERE  createdAt < currentTimeArg - reminderTimeArg
      AND createdAt > currentTimeArg - reminderTimeOutdatedArg
      AND type = reminderTypeArg
      ORDER BY createdAt, uid, type
      LIMIT reminderLimitArg;

    -- Because the query is deterministic we can delete
    -- all the selected items at once, rather than calling
    -- deleteVerificationReminder()
    DELETE FROM verificationReminders
      WHERE  createdAt < currentTimeArg - reminderTimeArg
      AND createdAt > currentTimeArg - reminderTimeOutdatedArg
      AND type = reminderTypeArg
      ORDER BY createdAt, uid, type
      LIMIT reminderLimitArg;

    -- Clean up outdated reminders.
    DELETE FROM
      verificationReminders
    WHERE
      createdAt < currentTimeArg - reminderTimeOutdatedArg
    AND
      type = reminderTypeArg;

    -- Return the result
    SELECT * FROM reminderResults;

    DO RELEASE_LOCK('fxa-auth-server.verification-reminders-lock');

  END IF;
  COMMIT;
END;


CREATE PROCEDURE `deleteVerificationReminder_1` (
    IN reminderUid BINARY(16),
    IN reminderType VARCHAR(255)
)
BEGIN
    DELETE FROM verificationReminders WHERE uid = reminderUid AND type = reminderType;
END;


----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------
----------------------------------

-- Add columns `verified` and `enabled` to help manage TOTP token state
ALTER TABLE `totp`
ADD COLUMN `verified` BOOLEAN DEFAULT FALSE,
ADD COLUMN `enabled` BOOLEAN DEFAULT TRUE,
ALGORITHM = INPLACE, LOCK = NONE;

-- Add verification details to session token table
ALTER TABLE `sessionTokens`
ADD COLUMN `verificationMethod` INT DEFAULT NULL,
ADD COLUMN `verifiedAt` BIGINT DEFAULT NULL,
ADD COLUMN `mustVerify` BOOLEAN DEFAULT TRUE,
ALGORITHM = INPLACE, LOCK = NONE;

CREATE PROCEDURE `totpToken_2` (
  IN `uidArg` BINARY(16)
)
BEGIN

  SELECT sharedSecret, epoch, verified, enabled FROM `totp` WHERE uid = uidArg;

END;

CREATE PROCEDURE `updateTotpToken_1` (
  IN `uidArg` BINARY(16),
  IN `verifiedArg` BOOLEAN,
  IN `enabledArg` BOOLEAN
)
BEGIN

  UPDATE `totp` SET verified = verifiedArg, enabled = enabledArg WHERE uid = uidArg;

END;

CREATE PROCEDURE `verifyTokensWithMethod_1` (
  IN `tokenIdArg` BINARY(32),
  IN `verificationMethodArg` INT,
  IN `verifiedAtArg` BIGINT(1)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
    -- Update session verification methods
    UPDATE `sessionTokens` SET verificationMethod = verificationMethodArg, verifiedAt = verifiedAtArg
    WHERE tokenId = tokenIdArg;

    -- Get the tokenVerificationId and uid for session
    SET @tokenVerificationId = NULL;
    SET @uid = NULL;
    SELECT tokenVerificationId, uid INTO @tokenVerificationId, @uid FROM `unverifiedTokens`
    WHERE tokenId = tokenIdArg;

    -- Verify tokens with tokenVerificationId
    CALL verifyToken_3(@tokenVerificationId, @uid);

    SET @updateCount = (SELECT ROW_COUNT());
  COMMIT;

  SELECT @updateCount;
END;

CREATE PROCEDURE `sessionWithDevice_12` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.tokenData,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    t.verificationMethod,
    t.verifiedAt,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    e.isVerified AS emailVerified,
    e.email,
    e.emailCode,
    a.verifierSetAt,
    a.locale,
    a.createdAt AS accountCreatedAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    ut.tokenVerificationId,
    COALESCE(t.mustVerify, ut.mustVerify) AS mustVerify
  FROM sessionTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
    AND e.isPrimary = true
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  LEFT JOIN unverifiedTokens AS ut
    ON t.tokenId = ut.tokenId
  WHERE t.tokenId = tokenIdArg;
END;

CREATE PROCEDURE `createSessionToken_9` (
  IN `tokenId` BINARY(32),
  IN `tokenData` BINARY(32),
  IN `uid` BINARY(16),
  IN `createdAt` BIGINT UNSIGNED,
  IN `uaBrowser` VARCHAR(255),
  IN `uaBrowserVersion` VARCHAR(255),
  IN `uaOS` VARCHAR(255),
  IN `uaOSVersion` VARCHAR(255),
  IN `uaDeviceType` VARCHAR(255),
  IN `uaFormFactor` VARCHAR(255),
  IN `tokenVerificationId` BINARY(16),
  IN `mustVerify` BOOLEAN,
  IN `tokenVerificationCodeHash` BINARY(32),
  IN `tokenVerificationCodeExpiresAt` BIGINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  INSERT INTO sessionTokens(
    tokenId,
    tokenData,
    uid,
    createdAt,
    uaBrowser,
    uaBrowserVersion,
    uaOS,
    uaOSVersion,
    uaDeviceType,
    uaFormFactor,
    lastAccessTime,
    mustVerify
  )
  VALUES(
    tokenId,
    tokenData,
    uid,
    createdAt,
    uaBrowser,
    uaBrowserVersion,
    uaOS,
    uaOSVersion,
    uaDeviceType,
    uaFormFactor,
    createdAt,
    mustVerify
  );

  IF tokenVerificationId IS NOT NULL THEN
    INSERT INTO unverifiedTokens(
      tokenId,
      tokenVerificationId,
      uid,
      mustVerify,
      tokenVerificationCodeHash,
      tokenVerificationCodeExpiresAt
    )
    VALUES(
      tokenId,
      tokenVerificationId,
      uid,
      mustVerify,
      tokenVerificationCodeHash,
      tokenVerificationCodeExpiresAt
    );
  END IF;

  COMMIT;
END;

CREATE PROCEDURE `updateSessionToken_3` (
    IN tokenIdArg BINARY(32),
    IN uaBrowserArg VARCHAR(255),
    IN uaBrowserVersionArg VARCHAR(255),
    IN uaOSArg VARCHAR(255),
    IN uaOSVersionArg VARCHAR(255),
    IN uaDeviceTypeArg VARCHAR(255),
    IN uaFormFactorArg VARCHAR(255),
    IN lastAccessTimeArg BIGINT UNSIGNED,
    IN authAtArg BIGINT UNSIGNED,
    IN mustVerifyArg BOOLEAN
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  UPDATE sessionTokens
    SET uaBrowser = COALESCE(uaBrowserArg, uaBrowser),
      uaBrowserVersion = COALESCE(uaBrowserVersionArg, uaBrowserVersion),
      uaOS = COALESCE(uaOSArg, uaOS),
      uaOSVersion = COALESCE(uaOSVersionArg, uaOSVersion),
      uaDeviceType = COALESCE(uaDeviceTypeArg, uaDeviceType),
      uaFormFactor = COALESCE(uaFormFactorArg, uaFormFactor),
      lastAccessTime = COALESCE(lastAccessTimeArg, lastAccessTime),
      authAt = COALESCE(authAtArg, authAt, createdAt)
    WHERE tokenId = tokenIdArg;

  -- Allow updating mustVerify from FALSE to TRUE,
  -- but not the other way around.
  IF mustVerifyArg THEN
    UPDATE unverifiedTokens
      SET mustVerify = TRUE
      WHERE tokenId = tokenIdArg;

    UPDATE sessionTokens
      SET mustVerify = TRUE
      WHERE tokenId = tokenIdArg;
  END IF;

  COMMIT;
END;

UPDATE dbMetadata SET value = '73' WHERE name = 'schema-patch-level';

-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- ALTER TABLE `totp`
-- DROP COLUMN `verified`,
-- DROP COLUMN `enabled`
-- ALGORITHM = INPLACE, LOCK = NONE;

-- ALTER TABLE `sessionTokens`
-- DROP COLUMN `verificationMethod`,
-- DROP COLUMN `verifiedAt`,
-- DROP COLUMN `mustVerify`
-- ALGORITHM = INPLACE, LOCK = NONE;

-- DROP PROCEDURE `totpToken_2`;
-- DROP PROCEDURE `updateTotpToken_1`;
-- DROP PROCEDURE `verifyTokensWithMethod_1`;
-- DROP PROCEDURE `sessionWithDevice_12`;
-- DROP PROCEDURE `createSessionToken_9`;
-- DROP PROCEDURE `updateSessionToken_3`;

-- UPDATE dbMetadata SET value = '72' WHERE name = 'schema-patch-level';

SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CREATE TABLE IF NOT EXISTS deviceCapabilities (
  uid BINARY(16) NOT NULL,
  deviceId BINARY(16) NOT NULL,
  capability TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (uid, deviceId, capability),
  FOREIGN KEY (uid, deviceId) REFERENCES devices(uid, id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE PROCEDURE `addCapability_1` (
  IN `inUid` BINARY(16),
  IN `inDeviceId` BINARY(16),
  IN `inCapability` TINYINT UNSIGNED
)
BEGIN
  INSERT INTO deviceCapabilities(
    uid,
    deviceId,
    capability
  )
  VALUES (
    inUid,
    inDeviceId,
    inCapability
  );
END;

CREATE PROCEDURE `purgeCapabilities_1` (
  IN `inUid` BINARY(16),
  IN `inDeviceId` BINARY(16)
)
BEGIN
  DELETE FROM deviceCapabilities WHERE uid = inUid AND deviceId = inDeviceId;
END;

CREATE PROCEDURE `accountDevices_13` (
  IN `uidArg` BINARY(16)
)
BEGIN
  SELECT
    d.uid,
    d.id,
    d.sessionTokenId,
    d.nameUtf8 AS name,
    d.type,
    d.createdAt,
    d.callbackURL,
    d.callbackPublicKey,
    d.callbackAuthKey,
    d.callbackIsExpired,
    (SELECT GROUP_CONCAT(dc.capability)
     FROM deviceCapabilities dc
     WHERE dc.uid = d.uid AND dc.deviceId = d.id) AS capabilities,
    s.uaBrowser,
    s.uaBrowserVersion,
    s.uaOS,
    s.uaOSVersion,
    s.uaDeviceType,
    s.uaFormFactor,
    s.lastAccessTime,
    e.email
  FROM devices AS d
  INNER JOIN sessionTokens AS s
    ON d.sessionTokenId = s.tokenId
  INNER JOIN emails AS e
    ON d.uid = e.uid
    AND e.isPrimary = true
  WHERE d.uid = uidArg;
END;

CREATE PROCEDURE `deviceFromTokenVerificationId_4` (
    IN inUid BINARY(16),
    IN inTokenVerificationId BINARY(16)
)
BEGIN
    SELECT
        d.id,
        d.nameUtf8 AS name,
        d.type,
        d.createdAt,
        d.callbackURL,
        d.callbackPublicKey,
        d.callbackAuthKey,
        d.callbackIsExpired,
        (SELECT GROUP_CONCAT(dc.capability)
         FROM deviceCapabilities dc
         WHERE dc.uid = d.uid AND dc.deviceId = d.id) AS capabilities
    FROM unverifiedTokens AS u
    INNER JOIN devices AS d
        ON (u.tokenId = d.sessionTokenId AND u.uid = d.uid)
    WHERE u.uid = inUid AND u.tokenVerificationId = inTokenVerificationId;
END;


CREATE PROCEDURE `sessionWithDevice_13` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.tokenData,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    t.verificationMethod,
    t.verifiedAt,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    e.isVerified AS emailVerified,
    e.email,
    e.emailCode,
    a.verifierSetAt,
    a.locale,
    a.createdAt AS accountCreatedAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    (SELECT GROUP_CONCAT(dc.capability)
     FROM deviceCapabilities dc
     WHERE dc.uid = d.uid AND dc.deviceId = d.id) AS deviceCapabilities,
    ut.tokenVerificationId,
    COALESCE(t.mustVerify, ut.mustVerify) AS mustVerify
  FROM sessionTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
    AND e.isPrimary = true
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  LEFT JOIN unverifiedTokens AS ut
    ON t.tokenId = ut.tokenId
  WHERE t.tokenId = tokenIdArg;
END;

CREATE PROCEDURE `sessions_9` (
  IN `uidArg` BINARY(16)
)
BEGIN
  SELECT
    t.tokenId,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    (SELECT GROUP_CONCAT(dc.capability)
     FROM deviceCapabilities dc
     WHERE dc.uid = d.uid AND dc.deviceId = d.id) AS deviceCapabilities
  FROM sessionTokens AS t
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  WHERE t.uid = uidArg;
END;

UPDATE dbMetadata SET value = '74' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP TABLE `deviceCapabilities`;

-- DROP PROCEDURE `addCapability_1`;
-- DROP PROCEDURE `purgeCapabilities_1`;
-- DROP PROCEDURE `accountDevices_13`;
-- DROP PROCEDURE `deviceFromTokenVerificationId_4`;
-- DROP PROCEDURE `sessionWithDevice_13`;
-- DROP PROCEDURE `sessions_9`;

-- UPDATE dbMetadata SET value = '73' WHERE name = 'schema-patch-level';

SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CREATE TABLE IF NOT EXISTS recoveryCodes (
  uid BINARY(16) NOT NULL,
  codeHash BINARY(64) NOT NULL,
  createdAt BIGINT UNSIGNED NOT NULL,
  UNIQUE KEY (`uid`, `codeHash`)
) ENGINE=InnoDB;

CREATE PROCEDURE `deleteRecoveryCodes_1` (
  IN `uidArg` BINARY(16)
)
BEGIN

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SET @accountCount = 0;

  -- Signal error if no user found
  SELECT COUNT(*) INTO @accountCount FROM `accounts` WHERE `uid` = `uidArg`;
  IF @accountCount = 0 THEN
    SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1643, MESSAGE_TEXT = 'Can not generate recovery codes for unknown user.';
  END IF;

  -- Delete all current recovery codes
  DELETE FROM `recoveryCodes` WHERE `uid` = `uidArg`;

  COMMIT;
END;

CREATE PROCEDURE `createRecoveryCode_1` (
  IN `uidArg` BINARY(16),
  IN `codeHashArg` BINARY(64)
)
BEGIN

  INSERT INTO recoveryCodes (uid, codeHash, createdAt) VALUES (uidArg, codeHashArg, NOW());

END;

CREATE PROCEDURE `consumeRecoveryCode_1` (
  IN `uidArg` BINARY(16),
  IN `codeHashArg` BINARY(64)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SET @deletedCount = 0;

  DELETE FROM `recoveryCodes` WHERE `uid` = `uidArg` AND `codeHash` = `codeHashArg`;

  SELECT ROW_COUNT() INTO @deletedCount;
  IF @deletedCount = 0 THEN
    SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1643, MESSAGE_TEXT = 'Unknown recovery code.';
  END IF;

  SELECT COUNT(*) AS count FROM `recoveryCodes` WHERE `uid` = `uidArg`;

  COMMIT;
END;

UPDATE dbMetadata SET value = '75' WHERE name = 'schema-patch-level';-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP TABLE recoveryCodes;
-- DROP PROCEDURE deleteRecoveryCodes_1;
-- DROP PROCEDURE createRecoveryCode_1;
-- DROP PROCEDURE consumeRecoveryCode_1;

-- UPDATE dbMetadata SET value = '74' WHERE name = 'schema-patch-level';

SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CREATE PROCEDURE `verifyTokensWithMethod_2` (
  IN `tokenIdArg` BINARY(32),
  IN `verificationMethodArg` INT,
  IN `verifiedAtArg` BIGINT(1)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
    -- Update session verification methods
    UPDATE `sessionTokens` SET verificationMethod = verificationMethodArg, verifiedAt = verifiedAtArg
    WHERE tokenId = tokenIdArg;

    SET @updateCount = (SELECT ROW_COUNT());

    -- Get the tokenVerificationId and uid for session
    SET @tokenVerificationId = NULL;
    SET @uid = NULL;
    SELECT tokenVerificationId, uid INTO @tokenVerificationId, @uid FROM `unverifiedTokens`
    WHERE tokenId = tokenIdArg;

    -- Verify tokens with tokenVerificationId
    CALL verifyToken_3(@tokenVerificationId, @uid);
  COMMIT;

  SELECT @updateCount;
END;

UPDATE dbMetadata SET value = '76' WHERE name = 'schema-patch-level';

-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE verifyTokensWithMethod_2;

-- UPDATE dbMetadata SET value = '75' WHERE name = 'schema-patch-level';

SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CREATE PROCEDURE `consumeUnblockCode_2` (
    inUid BINARY(16),
    inCodeHash BINARY(32)
)
BEGIN
    DECLARE timestamp BIGINT;
    SET @timestamp = (
        SELECT createdAt FROM unblockCodes
        WHERE
            uid = inUid
        AND
            unblockCodeHash = inCodeHash
    );

    DELETE FROM unblockCodes
    WHERE
        uid = inUid;

    SELECT @timestamp AS createdAt;
END;

UPDATE dbMetadata SET value = '77' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE `consumeUnblockCode_2`;

-- UPDATE dbMetadata SET value = '76' WHERE name = 'schema-patch-level';

SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CREATE PROCEDURE `consumeUnblockCode_3` (
    inUid BINARY(16),
    inCodeHash BINARY(32)
)
BEGIN
    DECLARE timestamp BIGINT;

    SET @timestamp = (
        SELECT createdAt FROM unblockCodes
        WHERE
            uid = inUid
        AND
            unblockCodeHash = inCodeHash
    );

    IF @timestamp > 0 THEN
        DELETE FROM unblockCodes
        WHERE
            uid = inUid;
    END IF;

    SELECT @timestamp AS createdAt;
END;

UPDATE dbMetadata SET value = '78' WHERE name = 'schema-patch-level';

-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE `consumeUnblockCode_3`;

-- UPDATE dbMetadata SET value = '77' WHERE name = 'schema-patch-level';

SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- Since we are altering the size of the `codeHash` column
-- we need to make sure that the column is empty before it can be applied
DELETE from recoveryCodes;

ALTER TABLE recoveryCodes MODIFY COLUMN codeHash BINARY(32);

ALTER TABLE recoveryCodes ADD COLUMN salt BINARY(32);

CREATE PROCEDURE `recoveryCodes_1` (
  IN `uidArg` BINARY(16)
)
BEGIN

  SELECT * FROM recoveryCodes WHERE uid = uidArg;

END;

CREATE PROCEDURE `consumeRecoveryCode_2` (
  IN `uidArg` BINARY(16),
  IN `codeHashArg` BINARY(32)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SET @deletedCount = 0;

  DELETE FROM `recoveryCodes` WHERE `uid` = `uidArg` AND `codeHash` = `codeHashArg`;

  SELECT ROW_COUNT() INTO @deletedCount;
  IF @deletedCount = 0 THEN
    SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1643, MESSAGE_TEXT = 'Unknown recovery code.';
  END IF;

  SELECT COUNT(*) AS count FROM `recoveryCodes` WHERE `uid` = `uidArg`;

  COMMIT;
END;

CREATE PROCEDURE `createRecoveryCode_2` (
  IN `uidArg` BINARY(16),
  IN `codeHashArg` BINARY(32),
  IN `saltArg` BINARY(32)
)
BEGIN

  INSERT INTO recoveryCodes (uid, codeHash, salt, createdAt) VALUES (uidArg, codeHashArg, saltArg, NOW());

END;

UPDATE dbMetadata SET value = '79' WHERE name = 'schema-patch-level';

-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- ALTER TABLE recoveryCodes MODIFY COLUMN codeHash BINARY(64),
-- ALGORITHM = COPY, LOCK = SHARED;
-- ALTER TABLE recoveryCodes DROP COLUMN salt BINARY(32),
-- ALGORITHM = COPY, LOCK = SHARED;
-- DROP recoveryCodes_1;
-- DROP consumeRecoveryCode_2;
-- DROP createRecoveryCode_2;

-- UPDATE dbMetadata SET value = '78' WHERE name = 'schema-patch-level';

SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- createdAt value is never returned to the user and not used internally

ALTER TABLE recoveryCodes DROP COLUMN createdAt;

CREATE PROCEDURE `createRecoveryCode_3` (
  IN `uidArg` BINARY(16),
  IN `codeHashArg` BINARY(32),
  IN `saltArg` BINARY(32)
)
BEGIN

  INSERT INTO recoveryCodes (uid, codeHash, salt) VALUES (uidArg, codeHashArg, saltArg);

END;

UPDATE dbMetadata SET value = '80' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE `createRecoveryCode_3`;
-- ALTER TABLE  recoveryCodes ADD createdAt BIGINT UNSIGNED NOT NULL;

-- UPDATE dbMetadata SET value = '79' WHERE name = 'schema-patch-level';
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CREATE TABLE IF NOT EXISTS recoveryKeys (
  uid BINARY(16) NOT NULL PRIMARY KEY,
  recoveryKeyId BINARY(64) NOT NULL,
  recoveryData TEXT
) ENGINE=InnoDB;

CREATE PROCEDURE `createRecoveryKey_1` (
  IN `uidArg` BINARY(16),
  IN `recoveryKeyIdArg` BINARY(64),
  IN `recoveryDataArg` TEXT
)
BEGIN

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SET @accountCount = 0;

  -- Signal error if no user found
  SELECT COUNT(*) INTO @accountCount FROM `accounts` WHERE `uid` = `uidArg`;
  IF @accountCount = 0 THEN
    SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1643, MESSAGE_TEXT = 'Can not create recovery key for unknown user.';
  END IF;

  INSERT INTO recoveryKeys (uid, recoveryKeyId, recoveryData) VALUES (uidArg, recoveryKeyIdArg, recoveryDataArg);

  COMMIT;
END;

CREATE PROCEDURE `getRecoveryKey_1` (
  IN `uidArg` BINARY(16),
  IN `recoveryKeyIdArg` BINARY(64)
)
BEGIN

  SELECT recoveryKeyId, recoveryData FROM recoveryKeys WHERE uid = uidArg AND recoveryKeyId = recoveryKeyIdArg;

END;

CREATE PROCEDURE `deleteRecoveryKey_1` (
  IN `uidArg` BINARY(16),
  IN `recoveryKeyIdArg` BINARY(64)
)
BEGIN

  DELETE FROM recoveryKeys WHERE uid = uidArg AND recoveryKeyId = recoveryKeyIdArg;

END;

UPDATE dbMetadata SET value = '81' WHERE name = 'schema-patch-level';

-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP TABLE `recoveryKeys`;
-- DROP PROCEDURE `createRecoveryKey_1`;
-- DROP PROCEDURE `getRecoveryKey_1`;
-- DROP PROCEDURE `deleteRecoveryKey_1`;

-- UPDATE dbMetadata SET value = '80' WHERE name = 'schema-patch-level';

--
-- This migration lets devices register "available commands",
-- a simple mapping from opaque command names to opaque blobs of
-- associated data.
--

SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- We expect many devices to register support for a relatively
-- small set of common commands, so we map command URIs to integer
-- ids for more efficient storage.

CREATE TABLE IF NOT EXISTS deviceCommandIdentifiers (
  commandId INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  commandName VARCHAR(191) NOT NULL UNIQUE KEY
) ENGINE=InnoDB;

-- The mapping from devices to their set of available commands is
-- a simple one-to-many table with associated data blob.  For now
-- we expect calling code to update this table by deleting all
-- rows for a device and then re-adding them.  In the future we
-- may add support for deleting individual rows, if and when we
-- grow a client-facing API that needs it.

CREATE TABLE IF NOT EXISTS deviceCommands (
  uid BINARY(16) NOT NULL,
  deviceId BINARY(16) NOT NULL,
  commandId INT UNSIGNED NOT NULL,
  commandData VARCHAR(2048),
  PRIMARY KEY (uid, deviceId, commandId),
  FOREIGN KEY (commandId) REFERENCES deviceCommandIdentifiers(commandId) ON DELETE CASCADE,
  FOREIGN KEY (uid, deviceId) REFERENCES devices(uid, id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE PROCEDURE `upsertAvailableCommand_1` (
  IN `inUid` BINARY(16),
  IN `inDeviceId` BINARY(16),
  IN `inCommandURI` VARCHAR(255),
  IN `inCommandData` VARCHAR(2048)
)
BEGIN

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  -- Find or create the corresponding integer ID for this command.
  SET @commandId = NULL;
  SELECT commandId INTO @commandId FROM deviceCommandIdentifiers WHERE commandName = inCommandURI;
  IF @commandId IS NULL THEN
    INSERT INTO deviceCommandIdentifiers (commandName) VALUES (inCommandURI);
    SET @commandId = LAST_INSERT_ID();
  END IF;

  -- Upsert the device's advertizement of that command.
  INSERT INTO deviceCommands(
    uid,
    deviceId,
    commandId,
    commandData
  )
  VALUES (
    inUid,
    inDeviceId,
    @commandId,
    inCommandData
  )
  ON DUPLICATE KEY UPDATE
    commandData = inCommandData
  ;

  COMMIT;
END;

CREATE PROCEDURE `purgeAvailableCommands_1` (
  IN `inUid` BINARY(16),
  IN `inDeviceId` BINARY(16)
)
BEGIN
  DELETE FROM deviceCommands
    WHERE uid = inUid
    AND deviceId = inDeviceId;
END;

-- When listing all devices, or retrieving a single device,
-- we select all rows from the deviceCommands table.
-- Calling code will thus receive multiple rows for each device,
-- one per available command.  Devices with no available commands
-- will contain NULL in those columns.  Like this:
--
--  +-----+---------+-------+-----+--------------+--------------+
--  | uid | device1 | name1 | ... | commandName1 | commandData1 |
--  | uid | device1 | name1 | ... | commandName2 | commandData2 |
--  | uid | device2 | name2 | ... | commandName1 | commandData3 |
--  | uid | device3 | name3 | ... | NULL         | NULL         |
--  +-----+---------+-------+-----+--------------+--------------+
--
-- It will need to flatten the rows into a list of devices with
-- an associated mapping of available commands.
--
-- Newer versions of MySQL have an aggregation function called
-- "JSON_OBJECTAGG" that would allow us to do that flattening
-- as part of the query, like this:
--
--    SELECT uid, id, ..., JSON_OBJECTAGG(commandName, commandData) AS availableCommands
--    FROM ...
--    GROUP BY 1, 2
--
-- But sadly, we're not on newer versions of MySQL in production.

CREATE PROCEDURE `accountDevices_14` (
  IN `uidArg` BINARY(16)
)
BEGIN
  SELECT
    d.uid,
    d.id,
    d.sessionTokenId,
    d.nameUtf8 AS name,
    d.type,
    d.createdAt,
    d.callbackURL,
    d.callbackPublicKey,
    d.callbackAuthKey,
    d.callbackIsExpired,
    s.uaBrowser,
    s.uaBrowserVersion,
    s.uaOS,
    s.uaOSVersion,
    s.uaDeviceType,
    s.uaFormFactor,
    s.lastAccessTime,
    ci.commandName,
    dc.commandData
  FROM devices AS d
  INNER JOIN sessionTokens AS s
    ON d.sessionTokenId = s.tokenId
  LEFT JOIN (
    deviceCommands AS dc
    INNER JOIN deviceCommandIdentifiers AS ci
      ON ci.commandId = dc.commandId
  ) ON dc.deviceId = d.id
  WHERE d.uid = uidArg
  -- For easy flattening, ensure rows are ordered by device id.
  ORDER BY 1, 2;
END;

CREATE PROCEDURE `device_1` (
  IN `uidArg` BINARY(16),
  IN `idArg` BINARY(16)
)
BEGIN
  SELECT
    d.uid,
    d.id,
    d.sessionTokenId,
    d.nameUtf8 AS name,
    d.type,
    d.createdAt,
    d.callbackURL,
    d.callbackPublicKey,
    d.callbackAuthKey,
    d.callbackIsExpired,
    s.uaBrowser,
    s.uaBrowserVersion,
    s.uaOS,
    s.uaOSVersion,
    s.uaDeviceType,
    s.uaFormFactor,
    s.lastAccessTime,
    ci.commandName,
    dc.commandData
  FROM devices AS d
  INNER JOIN sessionTokens AS s
    ON d.sessionTokenId = s.tokenId
  LEFT JOIN (
    deviceCommands AS dc
    INNER JOIN deviceCommandIdentifiers AS ci
      ON ci.commandId = dc.commandId
  ) ON dc.deviceId = d.id
  WHERE d.uid = uidArg
  AND d.id = idArg;
END;

CREATE PROCEDURE `deviceFromTokenVerificationId_5` (
    IN inUid BINARY(16),
    IN inTokenVerificationId BINARY(16)
)
BEGIN
  SELECT
    d.id,
    d.nameUtf8 AS name,
    d.type,
    d.createdAt,
    d.callbackURL,
    d.callbackPublicKey,
    d.callbackAuthKey,
    d.callbackIsExpired,
    ci.commandName,
    dc.commandData
  FROM unverifiedTokens AS u
  INNER JOIN devices AS d
    ON (u.tokenId = d.sessionTokenId AND u.uid = d.uid)
  LEFT JOIN (
    deviceCommands AS dc
    INNER JOIN deviceCommandIdentifiers AS ci
      ON ci.commandId = dc.commandId
  ) ON dc.deviceId = d.id
  WHERE u.uid = inUid AND u.tokenVerificationId = inTokenVerificationId;
END;

CREATE PROCEDURE `sessionWithDevice_14` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.tokenData,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    t.verificationMethod,
    t.verifiedAt,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    e.isVerified AS emailVerified,
    e.email,
    e.emailCode,
    a.verifierSetAt,
    a.locale,
    a.createdAt AS accountCreatedAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    ci.commandName AS deviceCommandName,
    dc.commandData AS deviceCommandData,
    ut.tokenVerificationId,
    COALESCE(t.mustVerify, ut.mustVerify) AS mustVerify
  FROM sessionTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
    AND e.isPrimary = true
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  LEFT JOIN (
    deviceCommands AS dc
    INNER JOIN deviceCommandIdentifiers AS ci
      ON ci.commandId = dc.commandId
  ) ON dc.deviceId = d.id
  LEFT JOIN unverifiedTokens AS ut
    ON t.tokenId = ut.tokenId
  WHERE t.tokenId = tokenIdArg;
END;

CREATE PROCEDURE `sessions_10` (
  IN `uidArg` BINARY(16)
)
BEGIN
  SELECT
    t.tokenId,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    ci.commandName AS deviceCommandName,
    dc.commandData AS deviceCommandData
  FROM sessionTokens AS t
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  LEFT JOIN (
    deviceCommands AS dc
    INNER JOIN deviceCommandIdentifiers AS ci
      ON ci.commandId = dc.commandId
  ) ON dc.deviceId = d.id
  WHERE t.uid = uidArg
  ORDER BY 1;
END;

UPDATE dbMetadata SET value = '82' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP TABLE deviceCommandIdentifiers;
-- DROP TABLE deviceCommands;

-- DROP PROCEDURE upsertAvailableCommand_1;
-- DROP PROCEDURE purgeAvailableCommands_1;
-- DROP PROCEDURE accountDevices_14;
-- DROP PROCEDURE device_1;
-- DROP PROCEDURE deviceFromTokenVerificationId_5;
-- DROP PROCEDURE sessionWithDevice_14;
-- DROP PROCEDURE sessions_10;

-- UPDATE dbMetadata SET value = '81' WHERE name = 'schema-patch-level';
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CREATE PROCEDURE `assertPatchLevel` (
  IN `requiredLevel` TEXT
)
BEGIN
  SELECT @currentPatchLevel := value FROM dbMetadata WHERE name = 'schema-patch-level';
  IF @currentPatchLevel != requiredLevel THEN
    SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1643, MESSAGE_TEXT = 'Missing migration detected';
  END IF;
END;

UPDATE dbMetadata SET value = '83' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE `assertPatchLevel`;

-- UPDATE dbMetadata SET value = '82' WHERE name = 'schema-patch-level';
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('83');

-- Since we are altering the size of the `recoveryKeyId` column
-- we need to make sure that the column is empty before it can be applied.
-- This table is ok to clear at this point because no user facing api
-- has landed to create recovery keys.
DELETE from recoveryKeys;

ALTER TABLE recoveryKeys MODIFY COLUMN recoveryKeyId BINARY(16);

CREATE PROCEDURE `createRecoveryKey_2` (
  IN `uidArg` BINARY(16),
  IN `recoveryKeyIdArg` BINARY(16),
  IN `recoveryDataArg` TEXT
)
BEGIN

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SET @accountCount = 0;

  -- Signal error if no user found
  SELECT COUNT(*) INTO @accountCount FROM `accounts` WHERE `uid` = `uidArg`;
  IF @accountCount = 0 THEN
    SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1643, MESSAGE_TEXT = 'Can not create recovery key for unknown user.';
  END IF;

  INSERT INTO recoveryKeys (uid, recoveryKeyId, recoveryData) VALUES (uidArg, recoveryKeyIdArg, recoveryDataArg);

  COMMIT;
END;

CREATE PROCEDURE `getRecoveryKey_2` (
  IN `uidArg` BINARY(16)
)
BEGIN

  SELECT recoveryKeyId, recoveryData FROM recoveryKeys WHERE uid = uidArg;

END;

CREATE PROCEDURE `deleteRecoveryKey_2` (
  IN `uidArg` BINARY(16)
)
BEGIN

  DELETE FROM recoveryKeys WHERE uid = uidArg;

END;

UPDATE dbMetadata SET value = '84' WHERE name = 'schema-patch-level';-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- ALTER TABLE recoveryKeys MODIFY COLUMN recoveryKeyId BINARY(64),
-- ALGORITHM = COPY, LOCK = SHARED;
-- DROP PROCEDURE createRecoveryKey_2;
-- DROP PROCEDURE getRecoveryKey_2;
-- DROP PROCEDURE deleteRecoveryKey_2;

-- UPDATE dbMetadata SET value = '83' WHERE name = 'schema-patch-level';
--
-- This migration updates the device-commands-related stored procedures
-- to correctly use the (uid, deviceId) index when joining onto the
-- `deviceCommands` table, fixing a performance issue.
--
-- We use MySQL's `FORCE INDEX (PRIMARY)` syntax in order to tell
-- the query planner to avoid a full table scan on `deviceCommands`
-- which it sometimes wants to do when the tables contain very
-- few rows.
--

SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('84');

CREATE PROCEDURE `accountDevices_15` (
  IN `uidArg` BINARY(16)
)
BEGIN
  SELECT
    d.uid,
    d.id,
    d.sessionTokenId,
    d.nameUtf8 AS name,
    d.type,
    d.createdAt,
    d.callbackURL,
    d.callbackPublicKey,
    d.callbackAuthKey,
    d.callbackIsExpired,
    s.uaBrowser,
    s.uaBrowserVersion,
    s.uaOS,
    s.uaOSVersion,
    s.uaDeviceType,
    s.uaFormFactor,
    s.lastAccessTime,
    ci.commandName,
    dc.commandData
  FROM devices AS d
  INNER JOIN sessionTokens AS s
    ON d.sessionTokenId = s.tokenId
  LEFT JOIN (
    deviceCommands AS dc FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS ci FORCE INDEX (PRIMARY)
      ON ci.commandId = dc.commandId
  ) ON (dc.uid = d.uid AND dc.deviceId = d.id)
  WHERE d.uid = uidArg
  -- For easy flattening, ensure rows are ordered by device id.
  ORDER BY 1, 2;
END;

CREATE PROCEDURE `device_2` (
  IN `uidArg` BINARY(16),
  IN `idArg` BINARY(16)
)
BEGIN
  SELECT
    d.uid,
    d.id,
    d.sessionTokenId,
    d.nameUtf8 AS name,
    d.type,
    d.createdAt,
    d.callbackURL,
    d.callbackPublicKey,
    d.callbackAuthKey,
    d.callbackIsExpired,
    s.uaBrowser,
    s.uaBrowserVersion,
    s.uaOS,
    s.uaOSVersion,
    s.uaDeviceType,
    s.uaFormFactor,
    s.lastAccessTime,
    ci.commandName,
    dc.commandData
  FROM devices AS d
  INNER JOIN sessionTokens AS s
    ON d.sessionTokenId = s.tokenId
  LEFT JOIN (
    deviceCommands AS dc FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS ci FORCE INDEX (PRIMARY)
      ON ci.commandId = dc.commandId
  ) ON (dc.uid = d.uid AND dc.deviceId = d.id)
  WHERE d.uid = uidArg
  AND d.id = idArg;
END;

CREATE PROCEDURE `deviceFromTokenVerificationId_6` (
    IN inUid BINARY(16),
    IN inTokenVerificationId BINARY(16)
)
BEGIN
  SELECT
    d.id,
    d.nameUtf8 AS name,
    d.type,
    d.createdAt,
    d.callbackURL,
    d.callbackPublicKey,
    d.callbackAuthKey,
    d.callbackIsExpired,
    ci.commandName,
    dc.commandData
  FROM unverifiedTokens AS u
  INNER JOIN devices AS d
    ON (u.tokenId = d.sessionTokenId AND u.uid = d.uid)
  LEFT JOIN (
    deviceCommands AS dc FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS ci FORCE INDEX (PRIMARY)
      ON ci.commandId = dc.commandId
  ) ON (dc.uid = d.uid AND dc.deviceId = d.id)
  WHERE u.uid = inUid AND u.tokenVerificationId = inTokenVerificationId;
END;

CREATE PROCEDURE `sessionWithDevice_15` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.tokenData,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    t.verificationMethod,
    t.verifiedAt,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    e.isVerified AS emailVerified,
    e.email,
    e.emailCode,
    a.verifierSetAt,
    a.locale,
    a.createdAt AS accountCreatedAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    ci.commandName AS deviceCommandName,
    dc.commandData AS deviceCommandData,
    ut.tokenVerificationId,
    COALESCE(t.mustVerify, ut.mustVerify) AS mustVerify
  FROM sessionTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
    AND e.isPrimary = true
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  LEFT JOIN (
    deviceCommands AS dc FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS ci FORCE INDEX (PRIMARY)
      ON ci.commandId = dc.commandId
  ) ON (dc.uid = d.uid AND dc.deviceId = d.id)
  LEFT JOIN unverifiedTokens AS ut
    ON t.tokenId = ut.tokenId
  WHERE t.tokenId = tokenIdArg;
END;

CREATE PROCEDURE `sessions_11` (
  IN `uidArg` BINARY(16)
)
BEGIN
  SELECT
    t.tokenId,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    ci.commandName AS deviceCommandName,
    dc.commandData AS deviceCommandData
  FROM sessionTokens AS t
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  LEFT JOIN (
    deviceCommands AS dc FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS ci FORCE INDEX (PRIMARY)
      ON ci.commandId = dc.commandId
  ) ON (dc.uid = d.uid AND dc.deviceId = d.id)
  WHERE t.uid = uidArg
  ORDER BY 1;
END;

UPDATE dbMetadata SET value = '85' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE accountDevices_15;
-- DROP PROCEDURE device_2;
-- DROP PROCEDURE deviceFromTokenVerificationId_6;
-- DROP PROCEDURE sessionWithDevice_15;
-- DROP PROCEDURE sessions_11;

-- UPDATE dbMetadata SET value = '84' WHERE name = 'schema-patch-level';
-- This migration updates recoveryKey table to store a hashed value of
-- the `recoveryKeyId` instead of the raw value. As part of this migration,
-- we will remove all existing recoveryKeys. This will help to ensure a consistent
-- migration.
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('85');

DELETE FROM recoveryKeys;

-- We can drop this since we will be using the `recoveryKeyIdHash`
-- column instead.
ALTER TABLE recoveryKeys DROP COLUMN recoveryKeyId,
ALGORITHM = INPLACE, LOCK = NONE;

ALTER TABLE recoveryKeys ADD COLUMN recoveryKeyIdHash BINARY(32) NOT NULL,
ALGORITHM = INPLACE, LOCK = NONE;

-- If we are in the process of a rollout and a user calls `createRecoveryKey_2`
-- then that request will fail. But that is ok since the previous create
-- procedure would have put the raw recoveryKeyId in database, which
-- would not work anyways.
CREATE PROCEDURE `createRecoveryKey_3` (
  IN `uidArg` BINARY(16),
  IN `recoveryKeyIdHashArg` BINARY(32),
  IN `recoveryDataArg` TEXT
)
BEGIN

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SET @accountCount = 0;

  -- Signal error if no user found
  SELECT COUNT(*) INTO @accountCount FROM `accounts` WHERE `uid` = `uidArg`;
  IF @accountCount = 0 THEN
    SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1643, MESSAGE_TEXT = 'Can not create recovery key for unknown user.';
  END IF;

  INSERT INTO recoveryKeys (uid, recoveryKeyIdHash, recoveryData) VALUES (uidArg, recoveryKeyIdHashArg, recoveryDataArg);

  COMMIT;
END;

CREATE PROCEDURE `getRecoveryKey_3` (
  IN `uidArg` BINARY(16)
)
BEGIN

  SELECT recoveryKeyIdHash, recoveryData FROM recoveryKeys WHERE uid = uidArg;

END;

UPDATE dbMetadata SET value = '86' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- ALTER TABLE `recoveryKeys`
-- ADD COLUMN recoveryKeyId
-- ALGORITHM = INPLACE, LOCK = NONE;

-- ALTER TABLE `recoveryKeys`
-- DROP COLUMN recoveryKeyIdHash
-- ALGORITHM = INPLACE, LOCK = NONE;

-- DROP PROCEDURE createRecoveryKey_3;
-- DROP PROCEDURE getRecoveryKey_3;

-- UPDATE dbMetadata SET value = '85' WHERE name = 'schema-patch-level';
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('86');

-- Add the `profileChangedAt` column to the accounts table.
-- Default NULL implies that the account profile hasn't changed since it
-- was created.
ALTER TABLE accounts ADD COLUMN profileChangedAt BIGINT UNSIGNED DEFAULT NULL,
ALGORITHM = INPLACE, LOCK = NONE;

-- Update `profileChangedAt` when emails are changed, verified or deleted
CREATE PROCEDURE `setPrimaryEmail_2` (
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
     UPDATE emails SET isPrimary = false WHERE uid = inUid AND isPrimary = true;
     UPDATE emails SET isPrimary = true WHERE uid = inUid AND isPrimary = false AND normalizedEmail = inNormalizedEmail;

     SELECT ROW_COUNT() INTO @updateCount;
     IF @updateCount = 0 THEN
        SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1062, MESSAGE_TEXT = 'Can not change email. Could not find email.';
     END IF;

     UPDATE accounts SET profileChangedAt = (UNIX_TIMESTAMP(NOW(3)) * 1000) WHERE uid = inUid;
  COMMIT;
END;

CREATE PROCEDURE `verifyEmail_6`(
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

    UPDATE accounts SET profileChangedAt = (UNIX_TIMESTAMP(NOW(3)) * 1000) WHERE uid = inUid;

    COMMIT;
END;

CREATE PROCEDURE `deleteEmail_3` (
    IN `inUid` BINARY(16),
    IN `inNormalizedEmail` VARCHAR(255)
)
BEGIN
    SET @primaryEmailCount = 0;

    -- Don't delete primary email addresses
    SELECT COUNT(*) INTO @primaryEmailCount FROM emails WHERE normalizedEmail = inNormalizedEmail AND uid = inUid AND isPrimary = true;
    IF @primaryEmailCount = 1 THEN
        SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 2100, MESSAGE_TEXT = 'Can not delete a primary email address.';
    END IF;

    DELETE FROM emails WHERE normalizedEmail = inNormalizedEmail AND uid = inUid AND isPrimary = false;

    UPDATE accounts SET profileChangedAt = (UNIX_TIMESTAMP(NOW(3)) * 1000) WHERE uid = inUid;
END;

-- Update `profileChangedAt` when TOTP is only verified or deleted on an account.
-- When a TOTP token is created, it doesn't get "turned on" until after a
-- call to updateTotpToken. An unverified token would not have changed anything on the account.
CREATE PROCEDURE `deleteTotpToken_2` (
  IN `uidArg` BINARY(16)
)
BEGIN
  DELETE FROM totp WHERE uid = uidArg;

  UPDATE accounts SET profileChangedAt = (UNIX_TIMESTAMP(NOW(3)) * 1000) WHERE uid = uidArg;
END;

CREATE PROCEDURE `updateTotpToken_2` (
  IN `uidArg` BINARY(16),
  IN `verifiedArg` BOOLEAN,
  IN `enabledArg` BOOLEAN
)
BEGIN

  UPDATE `totp` SET verified = verifiedArg, enabled = enabledArg WHERE uid = uidArg;

  UPDATE accounts SET profileChangedAt = (UNIX_TIMESTAMP(NOW(3)) * 1000) WHERE uid = uidArg;
END;


CREATE PROCEDURE `resetAccount_9` (
  IN `uidArg` BINARY(16),
  IN `verifyHashArg` BINARY(32),
  IN `authSaltArg` BINARY(32),
  IN `wrapWrapKbArg` BINARY(32),
  IN `verifierSetAtArg` BIGINT UNSIGNED,
  IN `VerifierVersionArg` TINYINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DELETE FROM sessionTokens WHERE uid = uidArg;
  DELETE FROM keyFetchTokens WHERE uid = uidArg;
  DELETE FROM accountResetTokens WHERE uid = uidArg;
  DELETE FROM passwordChangeTokens WHERE uid = uidArg;
  DELETE FROM passwordForgotTokens WHERE uid = uidArg;
  DELETE FROM devices WHERE uid = uidArg;
  DELETE FROM unverifiedTokens WHERE uid = uidArg;

  UPDATE accounts
  SET
    verifyHash = verifyHashArg,
    authSalt = authSaltArg,
    wrapWrapKb = wrapWrapKbArg,
    verifierSetAt = verifierSetAtArg,
    verifierVersion = verifierVersionArg,
    profileChangedAt = verifierSetAtArg
  WHERE uid = uidArg;

  COMMIT;
END;

-- Update get sessionToken to return `profileChangedAt`
CREATE PROCEDURE `sessionWithDevice_16` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.tokenData,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    t.verificationMethod,
    t.verifiedAt,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    e.isVerified AS emailVerified,
    e.email,
    e.emailCode,
    a.verifierSetAt,
    a.locale,
    COALESCE(a.profileChangedAt, a.verifierSetAt, a.createdAt) AS profileChangedAt,
    a.createdAt AS accountCreatedAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    ci.commandName AS deviceCommandName,
    dc.commandData AS deviceCommandData,
    ut.tokenVerificationId,
    COALESCE(t.mustVerify, ut.mustVerify) AS mustVerify
  FROM sessionTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
    AND e.isPrimary = true
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  LEFT JOIN (
    deviceCommands AS dc FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS ci FORCE INDEX (PRIMARY)
      ON ci.commandId = dc.commandId
  ) ON (dc.uid = d.uid AND dc.deviceId = d.id)
  LEFT JOIN unverifiedTokens AS ut
    ON t.tokenId = ut.tokenId
  WHERE t.tokenId = tokenIdArg;
END;

-- Return `profileChangedAt` with account record
CREATE PROCEDURE `accountRecord_3` (
  IN `inEmail` VARCHAR(255)
)
BEGIN
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.createdAt,
        a.locale,
        a.lockedAt,
        COALESCE(a.profileChangedAt, a.verifierSetAt, a.createdAt) AS profileChangedAt,
        e.normalizedEmail AS primaryEmail
    FROM
        accounts a,
        emails e
    WHERE
        a.uid = (SELECT uid FROM emails WHERE normalizedEmail = LOWER(inEmail))
    AND
        a.uid = e.uid
    AND
        e.isPrimary = true;
END;

CREATE PROCEDURE `account_4` (
    IN `inUid` BINARY(16)
)
BEGIN
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.createdAt,
        a.locale,
        a.lockedAt,
        COALESCE(a.profileChangedAt, a.verifierSetAt, a.createdAt) AS profileChangedAt
    FROM
        accounts a
    WHERE
        a.uid = LOWER(inUid)
    ;
END;

UPDATE dbMetadata SET value = '87' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- ALTER TABLE accounts DROP COLUMN profileChangedAt, ALGORITHM = INPLACE, LOCK = NONE;

-- DROP PROCEDURE setPrimaryEmail_2;
-- DROP PROCEDURE verifyEmail_6;
-- DROP PROCEDURE deleteEmail_3;
-- DROP PROCEDURE deleteTotpToken_2;
-- DROP PROCEDURE updateTotpToken_2;
-- DROP PROCEDURE resetAccount_9;

-- DROP PROCEDURE sessionWithDevice_16;
-- DROP PROCEDURE account_4;
-- DROP PROCEDURE accountRecord_3;

-- UPDATE dbMetadata SET value = '86' WHERE name = 'schema-patch-level';
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('87');

CREATE PROCEDURE `deleteAccount_15` (
  IN `uidArg` BINARY(16)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DELETE FROM sessionTokens WHERE uid = uidArg;
  DELETE FROM keyFetchTokens WHERE uid = uidArg;
  DELETE FROM accountResetTokens WHERE uid = uidArg;
  DELETE FROM passwordChangeTokens WHERE uid = uidArg;
  DELETE FROM passwordForgotTokens WHERE uid = uidArg;
  DELETE FROM accounts WHERE uid = uidArg;
  DELETE FROM devices WHERE uid = uidArg;
  DELETE FROM unverifiedTokens WHERE uid = uidArg;
  DELETE FROM unblockCodes WHERE uid = uidArg;
  DELETE FROM emails WHERE uid = uidArg;
  DELETE FROM signinCodes WHERE uid = uidArg;
  DELETE FROM totp WHERE uid = uidArg;
  DELETE FROM recoveryKeys WHERE uid = uidArg;
  DELETE FROM recoveryCodes WHERE uid = uidArg;
  DELETE FROM securityEvents WHERE uid = uidArg;

  COMMIT;
END;

UPDATE dbMetadata SET value = '88' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE deleteAccount_15;

-- UPDATE dbMetadata SET value = '87' WHERE name = 'schema-patch-level';
-- Add an index to walk signinCodes table by uid,
-- which is necessary when deleting an account.
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('88');

CREATE INDEX `signinCodes_uid`
ON `signinCodes` (`uid`)
ALGORITHM = INPLACE LOCK = NONE;

UPDATE dbMetadata SET value = '89' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP INDEX `signinCodes_uid`
-- ON `signinCodes`
-- ALGORITHM=INPLACE, LOCK=NONE;

-- UPDATE dbMetadata SET value = '88' WHERE name = 'schema-patch-level';
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('89');

CREATE PROCEDURE `verifyTokensWithMethod_3` (
  IN `tokenIdArg` BINARY(32),
  IN `verificationMethodArg` INT,
  IN `verifiedAtArg` BIGINT(1)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

    -- Update session verification methods
    UPDATE `sessionTokens` SET verificationMethod = verificationMethodArg, verifiedAt = verifiedAtArg
    WHERE tokenId = tokenIdArg;

END;

CREATE PROCEDURE `verifyTokenCode_2` (
  IN `tokenVerificationCodeHashArg` BINARY(32),
  IN `uidArg` BINARY(16)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET @tokenVerificationId = NULL;
  SELECT tokenVerificationId INTO @tokenVerificationId FROM unverifiedTokens
    WHERE uid = uidArg
    AND tokenVerificationCodeHash = tokenVerificationCodeHashArg
    AND tokenVerificationCodeExpiresAt >= (UNIX_TIMESTAMP(NOW(3)) * 1000);

  IF @tokenVerificationId IS NULL THEN
    SET @expiredCount = 0;
    SELECT COUNT(*) INTO @expiredCount FROM unverifiedTokens
      WHERE uid = uidArg
      AND tokenVerificationCodeHash = tokenVerificationCodeHashArg
      AND tokenVerificationCodeExpiresAt < (UNIX_TIMESTAMP(NOW(3)) * 1000);

    IF @expiredCount > 0 THEN
      SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 2101, MESSAGE_TEXT = 'Expired token verification code.';
    END IF;
  END IF;

  UPDATE securityEvents
  SET verified = true
  WHERE tokenVerificationId = @tokenVerificationId
  AND uid = uidArg;

  DELETE FROM unverifiedTokens
  WHERE tokenVerificationId = @tokenVerificationId
  AND uid = uidArg;
END;

UPDATE dbMetadata SET value = '90' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE verifyTokensWithMethod_3;
-- DROP PROCEDURE verifyTokenCode_2;

-- UPDATE dbMetadata SET value = '89' WHERE name = 'schema-patch-level';
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('90');

-- The `profileChangedAt` column may or may not exist in production env depending
-- on how migration 87 went. If it doesn't exist, then this statement will error because
-- you can not drop non-existent column in MySQL.
ALTER TABLE accounts DROP COLUMN profileChangedAt,
ALGORITHM = INPLACE, LOCK = NONE;

-- Removes the `profileChangedAt` update from setting primary email
CREATE PROCEDURE `setPrimaryEmail_3` (
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
     UPDATE emails SET isPrimary = false WHERE uid = inUid AND isPrimary = true;
     UPDATE emails SET isPrimary = true WHERE uid = inUid AND isPrimary = false AND normalizedEmail = inNormalizedEmail;

     SELECT ROW_COUNT() INTO @updateCount;
     IF @updateCount = 0 THEN
        SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1062, MESSAGE_TEXT = 'Can not change email. Could not find email.';
     END IF;

  COMMIT;
END;

-- Removes the `profileChangedAt` update when verifying new email
CREATE PROCEDURE `verifyEmail_7`(
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

-- Removes the `profileChangedAt` update when deleting email
CREATE PROCEDURE `deleteEmail_4` (
    IN `inUid` BINARY(16),
    IN `inNormalizedEmail` VARCHAR(255)
)
BEGIN
    SET @primaryEmailCount = 0;

    -- Don't delete primary email addresses
    SELECT COUNT(*) INTO @primaryEmailCount FROM emails WHERE normalizedEmail = inNormalizedEmail AND uid = inUid AND isPrimary = true;
    IF @primaryEmailCount = 1 THEN
        SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 2100, MESSAGE_TEXT = 'Can not delete a primary email address.';
    END IF;

    DELETE FROM emails WHERE normalizedEmail = inNormalizedEmail AND uid = inUid AND isPrimary = false;
END;

-- Removes the `profileChangedAt` update when a TOTP token is deleted
CREATE PROCEDURE `deleteTotpToken_3` (
  IN `uidArg` BINARY(16)
)
BEGIN
  DELETE FROM totp WHERE uid = uidArg;
END;

-- Removes the `profileChangedAt` update when a TOTP is updated
CREATE PROCEDURE `updateTotpToken_3` (
  IN `uidArg` BINARY(16),
  IN `verifiedArg` BOOLEAN,
  IN `enabledArg` BOOLEAN
)
BEGIN
  UPDATE `totp` SET verified = verifiedArg, enabled = enabledArg WHERE uid = uidArg;
END;

-- Removes the `profileChangedAt` update when an account is reset
CREATE PROCEDURE `resetAccount_10` (
  IN `uidArg` BINARY(16),
  IN `verifyHashArg` BINARY(32),
  IN `authSaltArg` BINARY(32),
  IN `wrapWrapKbArg` BINARY(32),
  IN `verifierSetAtArg` BIGINT UNSIGNED,
  IN `VerifierVersionArg` TINYINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DELETE FROM sessionTokens WHERE uid = uidArg;
  DELETE FROM keyFetchTokens WHERE uid = uidArg;
  DELETE FROM accountResetTokens WHERE uid = uidArg;
  DELETE FROM passwordChangeTokens WHERE uid = uidArg;
  DELETE FROM passwordForgotTokens WHERE uid = uidArg;
  DELETE FROM devices WHERE uid = uidArg;
  DELETE FROM unverifiedTokens WHERE uid = uidArg;

  UPDATE accounts
  SET
    verifyHash = verifyHashArg,
    authSalt = authSaltArg,
    wrapWrapKb = wrapWrapKbArg,
    verifierSetAt = verifierSetAtArg,
    verifierVersion = verifierVersionArg
  WHERE uid = uidArg;

  COMMIT;
END;

-- Coalesce `profileChangedAt` from verifierSetAt and createdAt
CREATE PROCEDURE `sessionWithDevice_17` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.tokenData,
    t.uid,
    t.createdAt,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    t.lastAccessTime,
    t.verificationMethod,
    t.verifiedAt,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    e.isVerified AS emailVerified,
    e.email,
    e.emailCode,
    a.verifierSetAt,
    a.locale,
    COALESCE(a.verifierSetAt, a.createdAt) AS profileChangedAt,
    a.createdAt AS accountCreatedAt,
    d.id AS deviceId,
    d.nameUtf8 AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL,
    d.callbackPublicKey AS deviceCallbackPublicKey,
    d.callbackAuthKey AS deviceCallbackAuthKey,
    d.callbackIsExpired AS deviceCallbackIsExpired,
    ci.commandName AS deviceCommandName,
    dc.commandData AS deviceCommandData,
    ut.tokenVerificationId,
    COALESCE(t.mustVerify, ut.mustVerify) AS mustVerify
  FROM sessionTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
    AND e.isPrimary = true
  LEFT JOIN devices AS d
    ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  LEFT JOIN (
    deviceCommands AS dc FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS ci FORCE INDEX (PRIMARY)
      ON ci.commandId = dc.commandId
  ) ON (dc.uid = d.uid AND dc.deviceId = d.id)
  LEFT JOIN unverifiedTokens AS ut
    ON t.tokenId = ut.tokenId
  WHERE t.tokenId = tokenIdArg;
END;

-- Coalesce `profileChangedAt` from verifierSetAt and createdAt
CREATE PROCEDURE `accountRecord_4` (
  IN `inEmail` VARCHAR(255)
)
BEGIN
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.createdAt,
        a.locale,
        a.lockedAt,
        COALESCE(a.verifierSetAt, a.createdAt) AS profileChangedAt,
        e.normalizedEmail AS primaryEmail
    FROM
        accounts a,
        emails e
    WHERE
        a.uid = (SELECT uid FROM emails WHERE normalizedEmail = LOWER(inEmail))
    AND
        a.uid = e.uid
    AND
        e.isPrimary = true;
END;

-- Coalesce `profileChangedAt` from verifierSetAt and createdAt
CREATE PROCEDURE `account_5` (
    IN `inUid` BINARY(16)
)
BEGIN
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.createdAt,
        a.locale,
        a.lockedAt,
        COALESCE(a.verifierSetAt, a.createdAt) AS profileChangedAt
    FROM
        accounts a
    WHERE
        a.uid = LOWER(inUid)
    ;
END;

UPDATE dbMetadata SET value = '91' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- ALTER TABLE accounts ADD COLUMN profileChangedAt BIGINT UNSIGNED DEFAULT NULL,
-- ALGORITHM = INPLACE, LOCK = NONE;

-- DROP PROCEDURE setPrimaryEmail_3;
-- DROP PROCEDURE verifyEmail_7;
-- DROP PROCEDURE deleteEmail_4;
-- DROP PROCEDURE deleteTotpToken_3;
-- DROP PROCEDURE updateTotpToken_3;
-- DROP PROCEDURE resetAccount_10;
-- DROP PROCEDURE sessionWithDevice_17;
-- DROP PROCEDURE accountRecord_4;
-- DROP PROCEDURE account_5;

-- UPDATE dbMetadata SET value = '90' WHERE name = 'schema-patch-level';
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('91');

-- Removes the LOWER(inUid) requirement on the WHERE clause
CREATE PROCEDURE `account_6` (
    IN `inUid` BINARY(16)
)
BEGIN
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.createdAt,
        a.locale,
        a.lockedAt,
        COALESCE(a.verifierSetAt, a.createdAt) AS profileChangedAt
    FROM
        accounts a
    WHERE
        a.uid = inUid
    ;
END;

-- Specify the email string encoding for `inEmail`. MySQL fails to use the
-- correct index in subquery if this is not set.
-- Ref: https://github.com/mozilla/fxa-auth-db-mysql/issues/440
CREATE PROCEDURE `accountRecord_5` (
  IN `inEmail` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin
)
BEGIN
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.createdAt,
        a.locale,
        a.lockedAt,
        COALESCE(a.verifierSetAt, a.createdAt) AS profileChangedAt,
        e.normalizedEmail AS primaryEmail
    FROM
        accounts a,
        emails e
    WHERE
        a.uid = (SELECT uid FROM emails WHERE normalizedEmail = LOWER(inEmail))
    AND
        a.uid = e.uid
    AND
        e.isPrimary = true;
END;

UPDATE dbMetadata SET value = '92' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE account_6;
-- DROP PROCEDURE accountRecord_5;

-- UPDATE dbMetadata SET value = '91' WHERE name = 'schema-patch-level';
-- This migration removes the use of `ROW_COUNT()` on the last
-- remaining procedures.
SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('92');

-- Updated to not use `ROW_COUNT()`. The previous procedure used row count to ensure that
-- the uid actually owned the email specified.
CREATE PROCEDURE `setPrimaryEmail_4` (
  IN `inUid` BINARY(16),
  IN `inNormalizedEmail` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
    SELECT normalizedEmail INTO @foundEmail FROM emails WHERE uid = inUid AND normalizedEmail = inNormalizedEmail AND isVerified = false;
    IF @foundEmail IS NOT NULL THEN
     SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1643, MESSAGE_TEXT = 'Can not change email. Email is not verified.';
    END IF;

    SELECT normalizedEmail INTO @foundEmail FROM emails WHERE uid = inUid AND normalizedEmail = inNormalizedEmail AND isVerified;
    IF @foundEmail IS NULL THEN
     SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO = 1062, MESSAGE_TEXT = 'Can not change email. Could not find email.';
    END IF;

    UPDATE emails SET isPrimary = false WHERE uid = inUid AND isPrimary = true;
    UPDATE emails SET isPrimary = true WHERE uid = inUid AND isPrimary = false AND normalizedEmail = inNormalizedEmail;
  COMMIT;
END;

-- Updated to not use `ROW_COUNT()`. The previous procedure used row count to check to see
-- if the given code was actually found. The new procedure moves the responsibility to `db.consumeRecoveryCode`
-- where all recovery codes are retrieved and filtered to only the matching code.
CREATE PROCEDURE `consumeRecoveryCode_3` (
  IN `uidArg` BINARY(16),
  IN `codeHashArg` BINARY(32)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  DELETE FROM `recoveryCodes` WHERE `uid` = `uidArg` AND `codeHash` = `codeHashArg`;

  SELECT COUNT(*) AS count FROM `recoveryCodes` WHERE `uid` = `uidArg`;

  COMMIT;
END;

UPDATE dbMetadata SET value = '93' WHERE name = 'schema-patch-level';
-- SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- DROP PROCEDURE setPrimaryEmail_4;
-- DROP PROCEDURE consumeRecoveryCode_3;

-- UPDATE dbMetadata SET value = '92' WHERE name = 'schema-patch-level';
