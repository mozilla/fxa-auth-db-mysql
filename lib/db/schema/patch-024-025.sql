-- This migration updates stored procedures
-- to avoid referencing the devices.callbackPublicKey column.
--

CREATE PROCEDURE `accountDevices_5` (
  IN `inUid` BINARY(16)
)
BEGIN
  SELECT
    d.uid,
    d.id,
    d.sessionTokenId,
    d.name,
    d.type,
    d.createdAt,
    d.callbackURL,
    s.uaBrowser,
    s.uaBrowserVersion,
    s.uaOS,
    s.uaOSVersion,
    s.uaDeviceType,
    s.lastAccessTime
  FROM
    devices d LEFT JOIN sessionTokens s
  ON
    d.sessionTokenId = s.tokenId
  WHERE
    d.uid = inUid;
END;

CREATE PROCEDURE `createDevice_3` (
  IN `inUid` BINARY(16),
  IN `inId` BINARY(16),
  IN `inSessionTokenId` BINARY(32),
  IN `inName` VARCHAR(255),
  IN `inType` VARCHAR(16),
  IN `inCreatedAt` BIGINT UNSIGNED,
  IN `inCallbackURL` VARCHAR(255)
)
BEGIN
  INSERT INTO devices(
    uid,
    id,
    sessionTokenId,
    name,
    type,
    createdAt,
    callbackURL
  )
  VALUES (
    inUid,
    inId,
    inSessionTokenId,
    inName,
    inType,
    inCreatedAt,
    inCallbackURL
  );
END;

CREATE PROCEDURE `updateDevice_3` (
  IN `inUid` BINARY(16),
  IN `inId` BINARY(16),
  IN `inSessionTokenId` BINARY(32),
  IN `inName` VARCHAR(255),
  IN `inType` VARCHAR(16),
  IN `inCallbackURL` VARCHAR(255)
)
BEGIN
  UPDATE devices
  SET sessionTokenId = COALESCE(inSessionTokenId, sessionTokenId),
    name = COALESCE(inName, name),
    type = COALESCE(inType, type),
    callbackURL = COALESCE(inCallbackURL, callbackURL)
  WHERE uid = inUid AND id = inId;
END;

CREATE PROCEDURE `sessionWithDevice_3` (
  IN `inTokenId` BINARY(32)
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
    t.lastAccessTime,
    a.emailVerified,
    a.email,
    a.emailCode,
    a.verifierSetAt,
    a.locale,
    a.createdAt AS accountCreatedAt,
    d.id AS deviceId,
    d.name AS deviceName,
    d.type AS deviceType,
    d.createdAt AS deviceCreatedAt,
    d.callbackURL AS deviceCallbackURL
  FROM
    sessionTokens t
    LEFT JOIN accounts a ON t.uid = a.uid
    LEFT JOIN devices d ON (t.tokenId = d.sessionTokenId AND t.uid = d.uid)
  WHERE
    t.tokenId = inTokenId;
END;

UPDATE dbMetadata SET value = '25' WHERE name = 'schema-patch-level';

