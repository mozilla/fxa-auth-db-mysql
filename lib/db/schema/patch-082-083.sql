SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CREATE PROCEDURE `deleteRecoveryKey_2` (
  IN `uidArg` BINARY(16)
)
BEGIN

  DELETE FROM recoveryKeys WHERE uid = uidArg;

END;

CREATE PROCEDURE `getRecoveryKey_2` (
  IN `uidArg` BINARY(16)
)
BEGIN

  SELECT recoveryKeyId, recoveryData FROM recoveryKeys WHERE uid = uidArg;

END;

UPDATE dbMetadata SET value = '83' WHERE name = 'schema-patch-level';

