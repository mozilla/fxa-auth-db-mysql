SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('91');

CREATE TABLE IF NOT EXISTS `clientsInstances` (
  `uid` BINARY(16) NOT NULL,
  `id` BINARY(16) NOT NULL,
  `clientId` BINARY(8) NOT NULL,
  `name` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `pushEndpoint` VARCHAR(255),
  `pushPublicKey` CHAR(88),
  `pushAuthKey` CHAR(24),
  PRIMARY KEY (`uid`,`id`),
  UNIQUE KEY `UQ_uid_id` (`uid`,`id`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `clientsInstancesCommands` (
  `uid` BINARY(16) NOT NULL,
  `instanceId` BINARY(16) NOT NULL,
  `commandId` INT UNSIGNED NOT NULL,
  `commandData` VARCHAR(2048),
  PRIMARY KEY (`uid`, `instanceId`, `commandId`),
  FOREIGN KEY (`commandId`) REFERENCES deviceCommandIdentifiers(`commandId`) ON DELETE CASCADE,
  FOREIGN KEY (`uid`, `instanceId`) REFERENCES clientsInstances(`uid`, `id`) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE PROCEDURE `deleteClientInstance_1` (
  IN `uidArg` BINARY(16),
  IN `idArg` BINARY(16)
)
BEGIN
  DELETE FROM `clientsInstances` WHERE `uid` = uidArg AND `id` = idArg;
END;

CREATE PROCEDURE `purgeAvailableClientCommands_1` (
  IN `inUid` BINARY(16),
  IN `inInstanceId` BINARY(16)
)
BEGIN
  DELETE FROM `clientsInstancesCommands`
    WHERE `uid` = inUid
    AND `instanceId` = inInstanceId;
END;

CREATE PROCEDURE `upsertAvailableClientCommand_1` (
  IN `inUid` BINARY(16),
  IN `inInstanceId` BINARY(16),
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

  -- Upsert the client instance advertizement of that command.
  INSERT INTO clientsInstancesCommands(
    `uid`,
    `instanceId`,
    `commandId`,
    `commandData`
  )
  VALUES (
    inUid,
    inInstanceId,
    @commandId,
    inCommandData
  )
  ON DUPLICATE KEY UPDATE
    commandData = inCommandData
  ;
  COMMIT;
END;

CREATE PROCEDURE `clientInstance_1` (
  IN `uidArg` BINARY(16),
  IN `idArg` BINARY(16)
)
BEGIN
  SELECT
    i.id,
    i.clientId,
    i.name,
    i.pushEndpoint,
    i.pushAuthKey,
    i.pushPublicKey,
    ci.commandName,
    ic.commandData
  FROM clientsInstances AS i
  LEFT JOIN (
    clientsInstancesCommands AS ic FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS ci FORCE INDEX (PRIMARY)
      ON ci.commandId = ic.commandId
  ) ON (ic.uid = i.uid AND ic.instanceId = i.id)
  WHERE i.uid = uidArg
  AND i.id = idArg;
END;

CREATE PROCEDURE `clientsInstances_1` (
  IN `uidArg` BINARY(16)
)
BEGIN
  SELECT
    i.id,
    i.clientId,
    i.name,
    i.pushEndpoint,
    i.pushAuthKey,
    i.pushPublicKey,
    ci.commandName,
    ic.commandData
  FROM clientsInstances AS i
  LEFT JOIN (
    clientsInstancesCommands AS ic FORCE INDEX (PRIMARY)
    INNER JOIN deviceCommandIdentifiers AS ci FORCE INDEX (PRIMARY)
      ON ci.commandId = ic.commandId
  ) ON (ic.uid = i.uid AND ic.instanceId = i.id)
  WHERE i.uid = uidArg
  -- For easy flattening, ensure rows are ordered by client instances id.
  ORDER BY 1, 2;
END;

CREATE PROCEDURE `upsertclientInstance_1` (
  IN `inUid` BINARY(16),
  IN `inId` BINARY(16),
  IN `inClientId` BINARY(8),
  IN `inName` VARCHAR(255),
  IN `inPushEndpoint` VARCHAR(255),
  IN `inPushPublicKey` CHAR(88),
  IN `inPushAuthKey` CHAR(24)
)
BEGIN
  INSERT INTO clientsInstances
    (`uid`, `id`, `clientId`, `name`, `pushEndpoint`, `pushPublicKey`, `pushAuthKey`)
  VALUES
    (inUid, inId, inClientId, inName, inPushEndpoint, inPushPublicKey, inPushAuthKey)
  ON DUPLICATE KEY UPDATE
    `name` = inName,
    `pushEndpoint` = inPushEndpoint,
    `pushPublicKey` = inPushPublicKey,
    `pushAuthKey` = inPushAuthKey;
END;

UPDATE dbMetadata SET value = '92' WHERE name = 'schema-patch-level';
