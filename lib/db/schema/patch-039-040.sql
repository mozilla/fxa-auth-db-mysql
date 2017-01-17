CREATE PROCEDURE `accountWebSessions_1` (
  IN `inUid` BINARY(16)
)
BEGIN
  SELECT
    s.lastAccessTime,
    s.tokenId,
    s.uaBrowser,
    s.uaBrowserVersion,
    s.uaDeviceType,
    s.uaOS,
    s.uaOSVersion
  FROM
    sessionTokens s LEFT JOIN devices d
  ON
    s.tokenId = d.sessionTokenId
  WHERE
    s.uid = inUid AND d.sessionTokenId is NULL;
END;

UPDATE dbMetadata SET value = '40' WHERE name = 'schema-patch-level';
