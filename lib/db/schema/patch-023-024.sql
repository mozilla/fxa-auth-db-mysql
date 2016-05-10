--
-- This patch reverts the table changes from previous patch #23,
-- which turned out to be difficult to deploy to production.
--
-- It's here as a separate patch to ensure a smooth update path
-- for dev servers that already had patch #23 applied,
-- but should *not* be deployed to production.
--

-- Drop new column and restore callbackPublicKey column type
ALTER TABLE devices
DROP COLUMN callbackAuthKey,
MODIFY COLUMN callbackPublicKey BINARY(32);

-- -- Decrement the schema version
UPDATE dbMetadata SET value = '24' WHERE name = 'schema-patch-level';
