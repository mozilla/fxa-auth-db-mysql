INSERT INTO emails(
SELECT
    normalizedEmail,
    email,
    uid,
    emailCode,
    emailVerified,
    true,
    createdAt
FROM accounts a
WHERE
    a.uid
NOT IN
    (SELECT uid FROM emails);

UPDATE dbMetadata SET value = '50' WHERE name = 'schema-patch-level';
