SET NAMES utf8mb4 COLLATE utf8mb4_bin;

-- Add an index on sessionTokens::createdAt to fix pruning filesort.
CREATE INDEX `sessionTokens_createdAt`
ON `sessionTokens` (`createdAt`)
ALGORITHM=INPLACE
LOCK=NONE;

-- Used to prevent session token pruning from doing a full table scan
-- as it proceeds further and further through the (very long) backlog
-- of pruning candidates.
INSERT INTO dbMetadata (name, value)
VALUES ('sessionTokensPrunedUntil', 0);

-- Update the prune stored procedure with assorted jiggery-pokery to
-- make session token pruning faster.
CREATE PROCEDURE `prune_5` (IN `olderThan` BIGINT UNSIGNED)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT @lockAcquired := GET_LOCK('fxa-auth-server.prune-lock', 3);

  IF @lockAcquired THEN
    DELETE FROM accountResetTokens WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;
    DELETE FROM passwordForgotTokens WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;
    DELETE FROM passwordChangeTokens WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;
    DELETE FROM unblockCodes WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;
    DELETE FROM signinCodes WHERE createdAt < olderThan ORDER BY createdAt LIMIT 10000;

    START TRANSACTION;

    -- Jiggery-pokery #1: Find out how far we got on previous iterations.
    SELECT @pruneFrom := value FROM dbMetadata WHERE name = 'sessionTokensPrunedUntil';

    -- Jiggery-pokery #2: Find out how far we will get on this iteration.
    SELECT @pruneUntil := MAX(createdAt) FROM (
      SELECT createdAt FROM sessionTokens
      WHERE createdAt >= @pruneFrom AND createdAt < olderThan
      AND NOT EXISTS (
        SELECT sessionTokenId FROM devices
        WHERE sessionTokenId = sessionTokens.tokenId
      )
      ORDER BY createdAt
      LIMIT 10000
    ) AS prunees;

    DELETE FROM sessionTokens
    WHERE createdAt > @pruneFrom AND createdAt <= @pruneUntil
    AND NOT EXISTS (
      SELECT sessionTokenId FROM devices
      WHERE sessionTokenId = sessionTokens.tokenId
    );

    DELETE ut
    FROM unverifiedTokens AS ut
    LEFT JOIN sessionTokens AS st
      ON ut.tokenId = st.tokenId
    WHERE st.tokenId IS NULL;

    -- Jiggery-pokery #3: Tell following iterations how far we got.
    UPDATE dbMetadata
    SET value = @pruneUntil
    WHERE name = 'sessionTokensPrunedUntil';

    COMMIT;

    SELECT RELEASE_LOCK('fxa-auth-server.prune-lock');
  END IF;
END;

UPDATE dbMetadata SET value = '66' WHERE name = 'schema-patch-level';

