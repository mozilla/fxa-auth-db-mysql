-- DROP INDEX `sessionTokens_createdAt`
-- ON `sessionTokens`
-- ALGORITHM=INPLACE
-- LOCK=NONE;

-- DELETE FROM dbMetadata
-- WHERE name = 'sessionTokensPrunedUntil';

-- DROP PROCEDURE `prune_5`;

-- UPDATE dbMetadata SET value = '65' WHERE name = 'schema-patch-level';

