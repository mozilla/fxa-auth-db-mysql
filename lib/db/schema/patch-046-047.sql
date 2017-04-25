-- Add ability to get a specific email on the emails table
-- Differs from `emailRecord` that returns a filtered account object

CREATE PROCEDURE `getSecondaryEmail_1` (
    IN `email` VARCHAR(255)
)
BEGIN
    SELECT * FROM emails WHERE normalizedEmail = LOWER(email);
END;

UPDATE dbMetadata SET value = '47' WHERE name = 'schema-patch-level';
