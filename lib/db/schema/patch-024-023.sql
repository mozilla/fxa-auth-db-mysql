-- -- Restore new column and modified column type
-- ALTER TABLE devices
-- MODIFY COLUMN callbackPublicKey CHAR(88),
-- ADD COLUMN callbackAuthKey CHAR(24);

-- -- Decrement the schema version
-- UPDATE dbMetadata SET value = '23' WHERE name = 'schema-patch-level';
