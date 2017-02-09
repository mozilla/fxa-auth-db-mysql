CREATE TABLE IF NOT EXISTS accountPreferences (
  uid BINARY(16) PRIMARY KEY NOT NULL,
  signinConfirmation TINYINT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE PROCEDURE `setAccountPreferences_1` (
  IN inUid BINARY(16),
  IN inSigninConfirmation TINYINT
)
BEGIN
  INSERT INTO accountPreferences(
    uid,
    signinConfirmation
  )
  VALUES(
    inUid,
    inSigninConfirmation
  )
  ON DUPLICATE KEY UPDATE
    signinConfirmation = inSigninConfirmation
  ;
END;

CREATE PROCEDURE `getAccountPreferences_1` (
  IN inUid BINARY(16)
)
BEGIN
  INSERT IGNORE INTO accountPreferences (uid) VALUES (inUid);
  SELECT
    signinConfirmation
  FROM accountPreferences
  WHERE uid = inUid
  LIMIT 1;
END;

CREATE PROCEDURE `deleteAccount_12` (
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
  DELETE FROM accountPreferences WHERE uid = uidArg;

  COMMIT;
END;

UPDATE dbMetadata SET value = '42' WHERE name = 'schema-patch-level';
