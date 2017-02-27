-- Add emails table and corresponding procedures to
-- create, get and delete them.

CREATE TABLE IF NOT EXISTS emails (
  normalizedEmail VARCHAR(255) NOT NULL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  uid BINARY(16) NOT NULL,
  emailCode BINARY(16) NOT NULL,
  isVerified BOOLEAN NOT NULL DEFAULT FALSE,
  isPrimary BOOLEAN NOT NULL DEFAULT FALSE,
  verifiedAt BIGINT UNSIGNED,
  createdAt BIGINT UNSIGNED NOT NULL
) ENGINE=InnoDB;

DROP procedure IF EXISTS `createEmail_1`;

CREATE PROCEDURE `createEmail_1` (
    IN `normalizedEmail` VARCHAR(255),
    IN `email` VARCHAR(255),
    IN `uid` BINARY(16) ,
    IN `emailCode` BINARY(16),
    IN `isVerified` TINYINT(1),
    IN `isPrimary` TINYINT(1),
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

    -- Currently, can not add an email that is specified in the
    -- accounts table, regardless of verification state.
    SET @emailExists = 0;
    SELECT COUNT(*) INTO @emailExists FROM accounts a WHERE a.normalizedEmail = normalizedEmail;
    IF @emailExists > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email already exists in accounts table.';
    END IF;

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
        isPrimary,
        verifiedAt,
        createdAt
    );

    COMMIT;
END;

CREATE PROCEDURE `accountEmails_1` (
    IN `inUid` BINARY(16)
)
BEGIN
    -- Return all emails that belong to the uid.
    -- Email from the accounts table is considered the primary email.
	(SELECT
        a.normalizedEmail,
        a.email,
        a.uid,
        a.emailCode,
        a.emailVerified AS isVerified,
        TRUE AS isPrimary,
        a.createdAt AS verifiedAt,
        a.createdAt
    FROM
        accounts a
    WHERE
        uid = LOWER(inUid))

    UNION ALL

    (SELECT
        e.normalizedEmail,
        e.email,
        e.uid,
        e.emailCode,
        e.isVerified,
        e.isPrimary,
        e.verifiedAt,
        e.createdAt
    FROM
        emails e
    WHERE
        uid = LOWER(inUid));
END;

CREATE PROCEDURE `deleteEmail_1` (
    IN `inNormalizedEmail` VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Don't delete any email that are considered primary emails
	SET @isPrimary = 0;
    SELECT COUNT(*) INTO @isPrimary FROM accounts WHERE normalizedEmail = inNormalizedEmail;
    IF @isPrimary > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can not delete a primary email address.';
    END IF;

	SELECT COUNT(*) INTO @isPrimary FROM emails WHERE normalizedEmail = inNormalizedEmail AND isPrimary = 1;
    IF @isPrimary > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can not delete a primary email address.';
    END IF;

	DELETE FROM emails WHERE normalizedEmail = inNormalizedEmail;

    COMMIT;
END;

DROP procedure IF EXISTS `deleteAccount_12`;

CREATE PROCEDURE `deleteAccount_12`(
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

  COMMIT;
END;


CREATE PROCEDURE `verifyEmail_4`(
    IN `inUid` BINARY(16),
    IN `inEmailCode` BINARY(16)
)
BEGIN
    SET @updatedCount = 0;

    IF (inEmailCode IS NULL) THEN
        -- To help maintain some backwards compatibility, if the `inEmailCode` is
        -- not specified, fallback to previous functionality which is to verify
        -- the account email.
		UPDATE accounts SET emailVerified = true WHERE uid = inUid;
    ELSE
        UPDATE accounts SET emailVerified = true WHERE uid = inUid AND emailCode = inEmailCode;

		SELECT ROW_COUNT() INTO @updatedCount;

		-- If no rows were updated in the accounts table, this code could
		-- belong to an email in the emails table. Attempt to verify it.
		IF @updatedCount = 0 THEN
			UPDATE emails SET isVerified = true WHERE uid = inUid AND emailCode = inEmailCode;
		END IF;
    END IF;
END

UPDATE dbMetadata SET value = '45' WHERE name = 'schema-patch-level';