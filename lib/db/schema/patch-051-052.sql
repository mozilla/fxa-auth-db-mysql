CREATE PROCEDURE `accountEmails_3` (
    IN `inUid` BINARY(16)
)
BEGIN
    SELECT * FROM emails WHERE uid = inUid ORDER BY isPrimary=true DESC;
END;

UPDATE dbMetadata SET value = '52' WHERE name = 'schema-patch-level';
