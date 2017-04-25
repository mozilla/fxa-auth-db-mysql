-- Add ability to get a specific email

CREATE PROCEDURE `getEmail_1` (
    IN `email` VARCHAR(255)
)
BEGIN
    SELECT * FROM emails WHERE normalizedEmail = LOWER(email);
END;

UPDATE dbMetadata SET value = '47' WHERE name = 'schema-patch-level';