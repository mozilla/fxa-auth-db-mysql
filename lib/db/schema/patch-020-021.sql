CREATE PROCEDURE `sessionDevice_1` (
  IN `inTokenId` BINARY(32)
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
    d.callbackPublicKey
  FROM
    devices d
  WHERE
    d.sessionTokenId = inTokenId;
END;

UPDATE dbMetadata SET value = '21' WHERE name = 'schema-patch-level';
