-- -- Drop new columns, and restore callbackPublicKey column type
-- ALTER TABLE devices
-- DROP COLUMN callbackAuthKey,
-- DROP COLUMN callbackPublicKey;

-- ALTER TABLE devices
-- ADD COLUMN callbackPublicKey BINARY(32);

-- -- Drop new stored procedures
-- DROP PROCEDURE `accountDevices_6`;
-- DROP PROCEDURE `createDevice_4`;
-- DROP PROCEDURE `updateDevice_4`;
-- DROP PROCEDURE `sessionWithDevice_4`;

-- -- Decrement the schema version
-- UPDATE dbMetadata SET value = '25' WHERE name = 'schema-patch-level';

