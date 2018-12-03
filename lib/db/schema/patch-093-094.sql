SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('93');

-- This migration replaces our current notion of a "device record" with a more
-- generation "client instance record", which is suitable for representing both
-- sessionToken-using sync devices and new OAuth-style clients.  To do so, we
-- allow a client instance record to be associated with either a sessionToken
-- or a refreshToken, and to track various client-replated data (such as uaOS,
-- uaFormFactor, etc) that was previously tracked directly on the sessionToken.
--
-- In an ideal world, we would rename the "devices" table to "clientInstances"
-- and add extra columns onto that table to accommodate.  We can't rename tables
-- without breaking existing stored procedures, and we can't currently add columns
-- because of a bug in our db schema migration tool.
--
-- So instead, we're going to create a brand new `clientInstances` table and mirror
-- writes into both this and the existing `devices` table.  Reads will similarly return
-- the union of data from both tables.
--
-- At some point in the future, we can complete the migration to the new table names
-- by deploying some additional migrations to:
--
--    * Copy existing data from `devices` into `clientInstances`.
--    * Make new stored procedures that stop accessing the now-unnecessary `devices` table.
--    * Drop the `devices` table entirely.
--
-- The downside of this strategy is an increase in DB read and write load, because
-- we're duplicating some data on disk.  Our theory is that it's better to eat this
-- additional load in the short term than to make a mess of the DB schema in the
-- long term.
--
-- XXX TODO: should we also do the same for `deviceCommandIdentifiers` and `deviceCommands`
-- tables?  We don't need to do any schema changes there, but we could try to rename them
-- for completeness.

CREATE TABLE IF NOT EXISTS `clientInstances` (
  `uid` BINARY(16) NOT NULL,
  `clientInstanceId` BINARY(16) NOT NULL,
  `sessionTokenId` BINARY(32) NULL,
  `refreshTokenId` BINARY(32) NULL,
  `clientId` BINARY(8) NULL,
  `createdAt` BIGINT UNSIGNED NULL,
  `lastChangedAt` BIGINT UNSIGNED NULL,
  `name` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `type` VARCHAR(16) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `pushURL` VARCHAR(255) NULL CHARACTER SET ascii COLLATE ascii_bin,
  `pushPublicKey` CHAR(88) NULL CHARACTER SET ascii COLLATE ascii_bin,
  `pushAuthKey` CHAR(24) NULL CHARACTER SET ascii COLLATE ascii_bin,
  `pushEndpointExpired` BOOLEAN NOT NULL DEFAULT FALSE,
  `uaBrowser` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `uaBrowserVersion` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `uaOS` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `uaOSVersion` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `uaDeviceType` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `uaFormFactor` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  PRIMARY KEY (`uid`,`clientInstanceId`),
  UNIQUE KEY `UQ_clientInstances_sessionTokenId` (`uid`,`sessionTokenId`),
  UNIQUE KEY `UQ_clientInstances_refreshTokenId` (`uid`,`refreshTokenId`)
) ENGINE=InnoDB;


-- This first version of `clientInstances_X` treats the `devices` table
-- as the canonical list of client instances, since it will hold all the
-- existing records and will receive a mirror copy of all new records.
--
-- Once we've copied over all existing records we can make a new version
-- that only reads from the `clientInstances` table.

CREATE PROCEDURE `clientInstances_1` (
  IN `uidArg` BINARY(16)
)
BEGIN
  -- First find everything that has an explicit clientInstance record,
  -- joining the `devices`, `clientInstances` and `sessionTokens` tables in
  -- order to ensure we get all the relevant metadata even for legacy devices.
  SELECT
    d.uid,
    d.id AS clientInstanceId,
    d.sessionTokenId,
    ci.refreshTokenId,
    ci.clientId,
    d.createdAt,
    ci.lastChangedAt,
    MAX(ci.lastChangedAt, t.lastAccessTime, d.createdAt) AS lastAccessTime,
    d.nameUtf8 AS name,
    d.type,
    d.callbackURL AS pushURL,
    d.callbackAuthKey AS pushAuthKey,
    d.callbackPublicKey AS pushPublicKey,
    d.callbackIsExpired AS pushEndpointExpired,
    COALESCE(ci.uaBrowser, t.uaBrowser),
    COALESCE(ci.uaBrowserVersion, t.uaBrowserVersion),
    COALESCE(ci.uaOS, t.uaOS),
    COALESCE(ci.uaOSVersion, t.uaOSVersion),
    COALESCE(ci.uaDeviceType, t.uaDeviceType),
    COALESCE(ci.uaFormFactor, t.uaFormFactor),
    cmdInfo.commandName,
    cmdData.commandData
  FROM devices AS d
  LEFT JOIN clientInstances AS ci
    ON d.uid = ci.uid AND d.id = ci.clientInstanceId
  LEFT JOIN sessionTokens AS t
    ON d.uid = t.uid AND d.sessionTokenId = t.tokenId
  LEFT JOIN (
    deviceCommands AS cmdData FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS cmdInfo FORCE INDEX (PRIMARY)
      ON cmdInfo.commandId = cmdData.commandId
  ) ON (cmdData.uid = d.uid AND cmdData.deviceId = d.id)
  WHERE d.uid = uidArg
  ORDER BY 1

  -- Also include any sessionTokens that do *not* have a corresponding.
  -- `clientInstance` record.  This lets us have a single query that slurps
  -- in a list of "everything connected to the user's account".
  UNION
  SELECT
    t.uid,
    NULL AS clientInstanceId,
    t.tokenId AS sessionTokenId,
    NULL AS refreshTokenId,
    NULL AS clientId,
    t.createdAt,
    MAX(t.createdAt, t.verifiedAt, t.authAt) AS lastChangedAt,
    t.lastAccessTime,
    NULL AS name,
    NULL As type,
    NULL AS pushURL,
    NULL AS pushAuthKey,
    NULL AS pushPublicKey,
    FALSE AS pushEndpointExpired,
    t.uaBrowser,
    t.uaBrowserVersion,
    t.uaOS,
    t.uaOSVersion,
    t.uaDeviceType,
    t.uaFormFactor,
    NULL AS commandName,
    NULL AS commandData
  FROM sessionTokens AS t
  LEFT JOIN devices AS d
    ON d.uid = t.uid AND d.sessionTokenId = t.tokenId
  WHERE t.uid = uidArg
    AND d.id IS NULL;
END;


-- This first version of `clientInstance_X` treats the `devices` table
-- as the canonical list of client instances, since it will hold all the
-- existing records and will receive a mirror copy of all new records.
--
-- Once we've copied over all existing records we can make a new version
-- that only reads from the `clientInstances` table.

CREATE PROCEDURE `clientInstance_1` (
  IN `uidArg` BINARY(16),
  IN `clientInstanceIdArg` BINARY(16)
)
BEGIN
  SELECT
    d.uid,
    d.id AS clientInstanceId,
    d.sessionTokenId,
    ci.refreshTokenId,
    ci.clientId,
    d.createdAt,
    ci.lastChangedAt,
    MAX(ci.lastChangedAt, t.lastAccessTime, d.createdAt) AS lastAccessTime,
    d.nameUtf8 AS name,
    d.type,
    d.callbackURL AS pushURL,
    d.callbackAuthKey AS pushAuthKey,
    d.callbackPublicKey AS pushPublicKey,
    d.callbackIsExpired AS pushEndpointExpired,
    COALESCE(ci.uaBrowser, t.uaBrowser),
    COALESCE(ci.uaBrowserVersion, t.uaBrowserVersion),
    COALESCE(ci.uaOS, t.uaOS),
    COALESCE(ci.uaOSVersion, t.uaOSVersion),
    COALESCE(ci.uaDeviceType, t.uaDeviceType),
    COALESCE(ci.uaFormFactor, t.uaFormFactor),
    cmdInfo.commandName,
    cmdData.commandData
  FROM devices AS d
  LEFT JOIN clientInstances AS ci
    ON d.uid = ci.uid AND d.id = ci.clientInstanceId
  LEFT JOIN sessionTokens AS t
    ON d.uid = t.uid AND d.sessionTokenId = t.tokenId
  LEFT JOIN (
    deviceCommands AS cmdData FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS cmdInfo FORCE INDEX (PRIMARY)
      ON cmdInfo.commandId = cmdData.commandId
  ) ON (cmdData.uid = d.uid AND cmdData.deviceId = d.id)
  WHERE d.uid = uidArg
    AND d.id = clientInstanceIdArg
END;


CREATE PROCEDURE `clientInstanceFromTokenVerificationId_1` (
    IN uidArg BINARY(16),
    IN tokenVerificationIdArg BINARY(16)
)
BEGIN
  SELECT
    d.uid,
    d.id AS clientInstanceId,
    d.sessionTokenId,
    ci.refreshTokenId,
    ci.clientId,
    d.createdAt,
    ci.lastChangedAt,
    MAX(ci.lastChangedAt, t.lastAccessTime, d.createdAt) AS lastAccessTime,
    d.nameUtf8 AS name,
    d.type,
    d.callbackURL AS pushURL,
    d.callbackAuthKey AS pushAuthKey,
    d.callbackPublicKey AS pushPublicKey,
    d.callbackIsExpired AS pushEndpointExpired,
    COALESCE(ci.uaBrowser, t.uaBrowser),
    COALESCE(ci.uaBrowserVersion, t.uaBrowserVersion),
    COALESCE(ci.uaOS, t.uaOS),
    COALESCE(ci.uaOSVersion, t.uaOSVersion),
    COALESCE(ci.uaDeviceType, t.uaDeviceType),
    COALESCE(ci.uaFormFactor, t.uaFormFactor),
    cmdInfo.commandName,
    cmdData.commandData
  FROM unverifiedTokens AS u
  INNER JOIN devices AS d
    ON (u.tokenId = i.sessionTokenId AND u.uid = i.uid)
  LEFT JOIN clientInstances AS ci
    ON d.uid = ci.uid AND d.id = ci.clientInstanceId
  LEFT JOIN sessionTokens AS t
    ON d.uid = t.uid AND d.sessionTokenId = t.tokenId
  LEFT JOIN (
    deviceCommands AS cmdData FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS cmdInfo FORCE INDEX (PRIMARY)
      ON cmdInfo.commandId = cmdData.commandId
  ) ON (cmdData.uid = d.uid AND cmdData.deviceId = d.id)
  WHERE u.uid = uidArg AND u.tokenVerificationId = tokenVerificationIdArg;
END;


-- This first version of the client-instance-writing procedures write into
-- both the `devices` table and the `clientInstances` table.
--
-- In a future migration we will copy any existing records from `devices` into
-- `clientInstances` and then we can stop writing to the `devices` table.

CREATE PROCEDURE `createClientInstance_1` (
  IN `uidArg` BINARY(16) NOT NULL,
  IN `clientInstanceIdArg` BINARY(16) NOT NULL,
  IN `sessionTokenIdArg` BINARY(32) NULL,
  IN `refreshTokenIdArg` BINARY(32) NULL,
  IN `clientIdArg` BINARY(8) NULL,
  IN `createdAtArg` BIGINT UNSIGNED NULL,
  IN `nameArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `typeArg` VARCHAR(16) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `pushURLArg` VARCHAR(255) NULL CHARACTER SET ascii COLLATE ascii_bin,
  IN `pushPublicKeyArg` CHAR(88) NULL CHARACTER SET ascii COLLATE ascii_bin,
  IN `pushAuthKeyArg` CHAR(24) NULL CHARACTER SET ascii COLLATE ascii_bin,
  IN `uaBrowserArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaBrowserVersionArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaOSArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaOSVersionArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaDeviceTypeArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaFormFactorArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

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
      uidArg,
      clientInstanceIdArg,
      sessionTokenIdArg,
      nameArg,
      typeArg,
      createdAtArg,
      pushURLArg,
      pushPublicKey,
      pushAuthKeyArg,
    );

    INSERT INTO clientInstances(
      uid,
      clientInstanceId,
      sessionTokenId,
      refreshTokenId,
      clientId,
      createdAt,
      lastChangedAt,
      name,
      type,
      pushURL,
      pushPublicKey,
      pushAuthKey,
      uaBrowser,
      uaBrowserVersion,
      uaOS,
      uaOSVersion,
      uaDeviceType,
      uaFormFactor
    )
    VALUES (
      uidArg,
      clientInstanceIdArg,
      sessionTokenIdArg,
      refreshTokenIdArg,
      clientIdArg,
      createdAtArg,
      createdAtArg,
      nameArg,
      typeArg,
      pushURLArg,
      pushPublicKeyArg,
      pushAuthKeyArg,
      uaBrowserArg,
      uaBrowserVersionArg,
      uaOSArg,
      uaOSVersionArg,
      uaDeviceTypeArg,
      uaFormFactorArg
    );

  COMMIT;
END;

CREATE PROCEDURE `updateClientInstance_1` (
  IN `uidArg` BINARY(16) NOT NULL,
  IN `clientInstanceIdArg` BINARY(16) NOT NULL,
  IN `sessionTokenIdArg` BINARY(32) NULL,
  IN `refreshTokenIdArg` BINARY(32) NULL,
  IN `clientIdArg` BINARY(8) NULL,
  IN `lastChangedAtArg` BIGINT UNSIGNED NULL,
  IN `nameArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `typeArg` VARCHAR(16) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `pushURLArg` VARCHAR(255) NULL CHARACTER SET ascii COLLATE ascii_bin,
  IN `pushPublicKeyArg` CHAR(88) NULL CHARACTER SET ascii COLLATE ascii_bin,
  IN `pushAuthKeyArg` CHAR(24) NULL CHARACTER SET ascii COLLATE ascii_bin,
  IN `pushEndpointExpiredArg` BOOLEAN NULL,
  IN `uaBrowserArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaBrowserVersionArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaOSArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaOSVersionArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaDeviceTypeArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  IN `uaFormFactorArg` VARCHAR(255) NULL CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

    UPDATE devices
    SET
      sessionTokenId = COALESCE(sessionTokenIdArg, sessionTokenId),
      nameUtf8 = COALESCE(nameArg, nameUtf8),
      type = COALESCE(typeArg, type),
      callbackURL = COALESCE(pushUrlArg, callbackURL),
      callbackPublicKey = COALESCE(pushPublicKeyArg, callbackPublicKey),
      callbackAuthKey = COALESCE(pushAuthKeyArg, callbackAuthKey),
      callbackIsExpired = COALESCE(pushEndpointExpiredArg, callbackIsExpired)
    WHERE uid = uidArg AND id = clientInstanceIdArg;

    -- Careful, we may be updating an item that exists in the `devices` table
    -- but not in the new `clientInstances` table.  If so them we need to copy
    -- across exisiting fields from the `devices` table.
    --
    -- Unfortunately we can't use `ON DUPLICATE KEY` here because that could be
    -- triggered by either a primary-key duplicate (in which case it's safe to
    -- update the existing row) or by a sessionTokenId/refreshTokenId conflict
    -- (in which case we want to error out).

    SELECT clientInstanceId INTO @foundClientInstance FROM clientInsances WHERE uid = uidArg AND clientInstanceId = clientInstanceIdArg;
    IF @clientInstance IS NOT NULL THEN

      UPDATE clientInstances
      SET
        sessionTokenId = COALESCE(sessionTokenIdArg, sessionTokenId),
        refreshTokenId = COALESCE(refreshTokenIdArg, refreshTokenId),
        clientId = COALESCE(clientIdArg, clientId),
        lastChangedAt = COALESCE(lastChangedAtArg, lastChangedAt),
        name = COALESCE(nameArg, name),
        type = COALESCE(typeArg, type),
        pushURL = COALESCE(pushURLArg, pushUrl),
        pushPublicKey = COALESCE(pushPublicKeyArg, pushPublicKey),
        pushAuthKey = COALESCE(pushAuthKeyArg, pushAuthAuthKey),
        pushEndpointExpired = COALESCE(pushEndpointExpiredArg, pushEndpointExpired),
        uaBrowser = COALESCE(uaBrowserArg, uaBrowser),
        uaBrowserVersion = COALESCE(uaBrowserVersionArg, uaBrowserVersion),
        uaOS = COALESCE(uaOSArg, uaOS),
        uaOSVersion = COALESCE(uaOSVersionArg, uaOSVersion),
        uaDeviceType = COALESCE(uaDeviceTypeArg, uaDeviceType),
        uaFormFactor = COALESCE(uaFormFactorArg, uaFormFactor)
      WHERE uid = uidArg AND clientInstanceId = clientInstanceIdArg;

    ELSE

      INSERT INTO clientInstances(
        uid,
        clientInstanceId,
        sessionTokenId,
        refreshTokenId,
        clientId,
        createdAt,
        lastChangedAt,
        name,
        type,
        pushURL,
        pushPublicKey,
        pushAuthKey,
        uaBrowser,
        uaBrowserVersion,
        uaOS,
        uaOSVersion,
        uaDeviceType,
        uaFormFactor
      )
      SELECT
        uidArg,
        clientInstanceIdArg,
        COALESCE(sessionTokenIdArg, d.sessionTokenId),
        refreshTokenIdArg,
        clientIdArg,
        d.createdAt,
        COALESCE(lastChangedAtArg, d.createdAt),
        COALESCE(nameArg, d.nameUtf8),
        COALESCE(typeArg, d.type),
        COALESCE(pushURLArg, d.callbackURL),
        COALESCE(pushPublicKeyArg, d.callbackPublicKey),
        COALESCE(pushAuthKeyArg, d.callbackAuthKey),
        COALESCE(pushEndpointExpiredArg, d.callbackIsExpired),
        uaBrowserArg,
        uaBrowserVersionArg,
        uaOSArg,
        uaOSVersionArg,
        uaDeviceTypeArg,
        uaFormFactorArg
      FROM devices AS d
      WHERE d.uid = uidArg AND d.id = clientInstanceIdArg;

    END IF;
  COMMIT;
END;

CREATE PROCEDURE `deleteClientInstance_1` (
  IN `uidArg` BINARY(16),
  IN `clientInstanceIdArg` BINARY(16)
)
BEGIN
  -- Return the token ids that are going to get deleted, if any.
  SELECT
    d.sessionTokenId,
    ci.refreshTokenId
  FROM devices AS d
  LEFT JOIN clientInstances AS ci
    ON ci.uid = d.uid AND ci.clientInstanceId = d.id
  WHERE devices.uid = uidArg AND devices.id = clientInstanceIdArg;

  -- Delete from both `devices` and `clientInstances` tables,
  -- and through to the linked auth tokens.
  --
  -- N.B. refresh tokens are currently in a separate database
  -- so we can't delete them here.
  DELETE devices, clientInstances, sessionTokens, unverifiedTokens
  FROM devices
  LEFT JOIN clientInstances
    ON clientInstances.uid = devices.uid AND clientInstances.clientInstanceId = devices.id
  LEFT JOIN sessionTokens
    ON devices.sessionTokenId = sessionTokens.tokenId
  LEFT JOIN unverifiedTokens
    ON sessionTokens.tokenId = unverifiedTokens.tokenId
  WHERE devices.uid = uidArg
    AND devices.id = idArg;
END;


CREATE PROCEDURE `sessionTokenWithClientInstance_1` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  SELECT
    t.tokenData,
    t.uid,
    t.createdAt,
    COALESCE(t.uaBrowser, ci.uaBrowser),
    COALESCE(t.uaBrowserVersion, ci.uaBrowserVersion),
    COALESCE(t.uaOS, ci.uaBrowserVersion),
    COALESCE(t.uaOSVersion, ci.uaOSVersion),
    COALESCE(t.uaDeviceType, ci.uaDeviceType),
    COALESCE(t.uaFormFactor, ci.uaFormFactor),
    t.lastAccessTime,
    t.verificationMethod,
    t.verifiedAt,
    COALESCE(t.authAt, t.createdAt) AS authAt,
    ut.tokenVerificationId,
    COALESCE(t.mustVerify, ut.mustVerify) AS mustVerify
    e.isVerified AS emailVerified,
    e.email,
    e.emailCode,
    a.verifierSetAt,
    a.locale,
    a.createdAt AS accountCreatedAt,
    d.id AS clientInstanceId,
    ci.clientId,
    COALESCE(ci.name, d.nameUtf8) AS clientInstanceName,
    d.type as clientInstanceType,
    d.createdAt AS clientInstanceCreatedAt,
    d.callbackURL AS clientInstancePushURL,
    d.callbackPublicKey AS clientInstancePushPublicKey,
    d.callbackAuthKey AS clientInstancePushAuthKey,
    d.callbackIsExpired AS clientInstancePushEndpointExpired,
    cmdInfo.commandName AS clientInstanceCommandName,
    cmdData.commandData AS clientInstanceCommandData,
  FROM sessionTokens AS t
  LEFT JOIN accounts AS a
    ON t.uid = a.uid
  LEFT JOIN emails AS e
    ON t.uid = e.uid
    AND e.isPrimary = true
  LEFT JOIN unverifiedTokens AS ut
    ON t.tokenId = ut.tokenId
  LEFT JOIN devices AS d
    ON d.uid = t.uid AND d.sessionTokenId = t.tokenId
  LEFT JOIN clientInstances AS ci
    ON ci.uid = t.uid AND ci.clientInstanceId = d.id
  LEFT JOIN (
    deviceCommands AS cmdData FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS cmdInfo FORCE INDEX (PRIMARY)
      ON cmdInfo.commandId = cmdData.commandId
  ) ON (cmdData.uid = d.uid AND cmdData.deviceId = d.id)
  WHERE t.tokenId = tokenIdArg;
END;

-- Deleting a sessionToken needs to also delete from `clientInstances`.
-- XXX TODO: what if the clientInstance also has a refreshTokenId,
-- should we still delete it, or just mark the sessionTokenId as NULL?

CREATE PROCEDURE `deleteSessionToken_4` (
  IN `tokenIdArg` BINARY(32)
)
BEGIN
  DELETE sessionTokens, unverifiedTokens, devices, clientInstances
  FROM sessionTokens
  LEFT JOIN unverifiedTokens
    ON sessionTokens.tokenId = unverifiedTokens.tokenId
  LEFT JOIN devices
    ON devices.uid = sessionTokens.uid AND devices.sessionTokenId = sessionTokens.tokenId
  LEFT JOIN clientInstances
    ON clientInstances.uid = devices.uid AND clientInstances.clientInstanceId = devices.id
  WHERE sessionTokens.tokenId = tokenIdArg
END;

-- Deleting the account must also delete from `clientInstances`.

CREATE PROCEDURE `deleteAccount_16` (
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
  DELETE FROM clientInstances WHERE uid = uidArg;
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


-- Resetting the account must also delete from `clientInstances`.

CREATE PROCEDURE `resetAccount_11` (
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
  DELETE FROM clientInstances WHERE uid = uidArg;
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


UPDATE dbMetadata SET value = '94' WHERE name = 'schema-patch-level';