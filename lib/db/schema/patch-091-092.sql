SET NAMES utf8mb4 COLLATE utf8mb4_bin;

CALL assertPatchLevel('91');

-- Re-write the `accountRecord` procedure to use a temporary variable
-- rather than a sub-select, since sub-selects seems to cause some
-- trouble for the query planner.
CREATE PROCEDURE `accountRecord_5` (
  IN `inEmail` VARCHAR(255)
)
BEGIN
    SELECT uid INTO @owningUid FROM emails WHERE normalizedEmail = LOWER(inEmail);
    SELECT
        a.uid,
        a.email,
        a.normalizedEmail,
        a.emailVerified,
        a.emailCode,
        a.kA,
        a.wrapWrapKb,
        a.verifierVersion,
        a.authSalt,
        a.verifierSetAt,
        a.createdAt,
        a.locale,
        a.lockedAt,
        COALESCE(a.verifierSetAt, a.createdAt) AS profileChangedAt,
        e.normalizedEmail AS primaryEmail
    FROM
        accounts a,
        emails e
    WHERE
        a.uid = @owningUid
    AND
        e.uid = a.uid
    AND
        e.isPrimary = true;
END;

UPDATE dbMetadata SET value = '92' WHERE name = 'schema-patch-level';
