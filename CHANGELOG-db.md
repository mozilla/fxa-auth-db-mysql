train-42
  * fix(tests): pass server object to backend tests - #63
  * refactor(db): remove verifyHash from responses - #48
  * chore(shrinkwrap): update shrinkwrap for verifyHash removal - #61
  * chore(shrinkwrap): update shrinkwrap, principally to head of fxa-auth-db-server - #63

train-41
  * feat(api): Return the account email address on passwordChangeToken - #59
  * chore(travis): Tell Travis to use #fxa-bots - #60
  
train-40
  * fix(notifications): always return a promise from db.processUnpublishedEvents, fixes #49 - #52
  * fix(npm): Update npm-shrinkwrap to include the last version of fxa-auth-db-server - #50
  * chore(cleanup): Fixed some syntax errors reported by ESLint - #55
  * fix(db): Return 400 on incorrect password - #53
  * refactor(db): Remove old stored procedures that are no longer used - #57
  
train-39
  * fix(npm): Update npm-shrinkwrap to include the last version of fxa-auth-db-server - #50
  * Added checkPassword_1 stored procedure - #45
  * Use array for Mysql read() bound parameters - #45
  * chore(license): Update license to be SPDX compliant - #46

train-37
  * refactor(lib): move most things into lib/
  * build(travis): Test on both io.js v1 and v2
  * chore(shrinkwrap): update shrinkwrap picking up lib changes in fxa-auth-db-server

train-36
  * refactor(db): Change table access in stored procedures to be consistent - #36
  * fix(db): Fix reverse patches 8->7 and 9->8 - #38
  * fix(package): Remove uuid completely since no longer needed - #37
  * chore(package): Update to mysql-patcher@0.7.0 - #39
  * chore(copyright): Update to grunt-copyright v0.2.0 - #40
  * chore(test): Test on node.js v0.10, v0.12 and the latest io.js - #41

train-35
  * there was no train-35 for fxa-auth-db-mysql

train-34
  * feat(events): Publish account events to notification server in a background loop - #25
    * Note: this feature is disabled by default (see 'config.notifications.publishUrl'),
       and will not be enabled in train-34
  * fix(notifier): allow us to use the json secret key from the auth-server directly for the notifier - #29
  * fix(db): do not set createdAt, verifierSetAt or normalizedEmail here - #31
  * fix(logging): load the logger from the new location - #32
  * fix(release): add tasks "grunt version" and "grunt version:patch" to - #34
  * chore(tests): Remove console logging during test run - #25
  * chore(tests): Don't assume log.info message order during tests - #25
  * chore(tests): Remove some apparently-unused files in 'test' directory - #25
  * chore(package.json): add extra fields related to the repo - #30
  * chore(shrinkwrap): update shrinkwrap - #33

train-33
  * Log account activity events for later publishing to notification service - #20
  * Fix tests to do more reliable error-message detection - #20
  * Correctly pass pool name when getting a connection - #23
  * Use mozlog for logging - #21
  * Log memory-usage stats emitted by fxa-auth-db-server - #24
  * Some documentation and packaging tweaks - #17, #18

train-32
  * Add ability to mark an account as "locked" for security reasons - #7
  * Add support for docker-based development workflow - #13


train-31
  * Only fail with a DB patch level less than the one expected
  * (hotfix) regenerated npm-shrinkwrap.json that uses the correct version of fxa-auth-db-server - #15
