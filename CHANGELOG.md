<a name="1.111.0"></a>
# [1.111.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.110.0...v1.111.0) (2018-05-02)


### Bug Fixes

* **npm:** update shrinkwrap to npm 5.8 (#344) r=@jrgm ([a841d06](https://github.com/mozilla/fxa-auth-db-mysql/commit/a841d06))
* **tests:** increase timeout on recovery code tests (#339), r=@jrgm ([f202197](https://github.com/mozilla/fxa-auth-db-mysql/commit/f202197))

### Features

* **node:** update to node 8 (#341) r=@jrgm ([8bcc7dd](https://github.com/mozilla/fxa-auth-db-mysql/commit/8bcc7dd))

### Refactor

* **db:** Fixes #340 Remove column createdAt on recoveryCode table (#342), r=@vbudhram ([1b59224](https://github.com/mozilla/fxa-auth-db-mysql/commit/1b59224)), closes [#340](https://github.com/mozilla/fxa-auth-db-mysql/issues/340) [(#342](https://github.com/(/issues/342)



<a name="1.110.0"></a>
# [1.110.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.109.0...v1.110.0) (2018-04-18)


### Bug Fixes

* **codes:** remove current recovery codes before applying migration (#337), r=@rfk ([23cbc61](https://github.com/mozilla/fxa-auth-db-mysql/commit/23cbc61))
* **codes:** update recovery code requirements (#333), r=@philbooth ([2ca7d9f](https://github.com/mozilla/fxa-auth-db-mysql/commit/2ca7d9f))
* **devices:** Rename pushbox capability to messages and add messages.sendtab capability (#335) ([5a1535a](https://github.com/mozilla/fxa-auth-db-mysql/commit/5a1535a))



<a name="1.109.0"></a>
# [1.109.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.107.1...v1.109.0) (2018-04-04)


### Bug Fixes

* **codes:** drop all codes when one is consumed (#326) r=@rfk ([f6ab498](https://github.com/mozilla/fxa-auth-db-mysql/commit/f6ab498))
* **node:** Use Node.js v6.14.0 (#332) ([1400a26](https://github.com/mozilla/fxa-auth-db-mysql/commit/1400a26))
* **unblock:** update consume unblock code (#330) r=@vladikoff ([9bdb47b](https://github.com/mozilla/fxa-auth-db-mysql/commit/9bdb47b))
* **verify:** update verifyWithMethod to update a session verification status (#329), r=@philb ([9c433ba](https://github.com/mozilla/fxa-auth-db-mysql/commit/9c433ba))

### Features

* **mysql:** Add config option for REQUIRED_SQL_MODES. (#334) r=@philbooth,@vladikoff ([a229ddc](https://github.com/mozilla/fxa-auth-db-mysql/commit/a229ddc))
* **mysql:** STRICT_ALL_TABLES and NO_ENGINE_SUBSTITUTION required in sql (#327) r=@vladikoff ([c226b07](https://github.com/mozilla/fxa-auth-db-mysql/commit/c226b07))

### Acknowledgements

Thanks to Yusuf Yazir <y.yazir@rocketmail.com> for suggesting a security improvement
in the handling of unblock codes ([Bug 1368827](https://bugzilla.mozilla.org/show_bug.cgi?id=1368827)).



<a name="1.108.0"></a>
# [1.108.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.107.0...v1.108.0) (2018-03-20)


### Bug Fixes

* **buffers:** convert remaining Buffer to Buffer.from r=@vladikoff ([5092779](https://github.com/mozilla/fxa-auth-db-mysql/commit/5092779)), closes [#316](https://github.com/mozilla/fxa-auth-db-mysql/issues/316)
* **db:** remove database configuration option, hardcode 'fxa'  (#314) r=@vladikoff ([c2e21dd](https://github.com/mozilla/fxa-auth-db-mysql/commit/c2e21dd)), closes [#290](https://github.com/mozilla/fxa-auth-db-mysql/issues/290)
* **email:** Use email buffer for DEL ‘/email/:email’ route (#315), r=@vladikoff, @vbudhram ([cc6e08b](https://github.com/mozilla/fxa-auth-db-mysql/commit/cc6e08b))
* **test:** correct promises error handling (#325) r=@eoger ([7effcb3](https://github.com/mozilla/fxa-auth-db-mysql/commit/7effcb3))

### chore

* **api:** remove bufferization from db layer ([818edcf](https://github.com/mozilla/fxa-auth-db-mysql/commit/818edcf))

### Features

* **devices:** Devices capabilities (#320) r=@philbooth ([4808a1c](https://github.com/mozilla/fxa-auth-db-mysql/commit/4808a1c))
* **node:** update to node v6.13.1 r=@jbuck ([7727d88](https://github.com/mozilla/fxa-auth-db-mysql/commit/7727d88))
* **totp:** initial recovery codes (#319), r=@philbooth ([995d52b](https://github.com/mozilla/fxa-auth-db-mysql/commit/995d52b))



<a name="1.108.0"></a>
# [1.108.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.107.0...v1.108.0) (2018-03-20)


### Bug Fixes

* **buffers:** convert remaining Buffer to Buffer.from r=@vladikoff ([5092779](https://github.com/mozilla/fxa-auth-db-mysql/commit/5092779)), closes [#316](https://github.com/mozilla/fxa-auth-db-mysql/issues/316)
* **db:** remove database configuration option, hardcode 'fxa'  (#314) r=@vladikoff ([c2e21dd](https://github.com/mozilla/fxa-auth-db-mysql/commit/c2e21dd)), closes [#290](https://github.com/mozilla/fxa-auth-db-mysql/issues/290)
* **email:** Use email buffer for DEL ‘/email/:email’ route (#315), r=@vladikoff, @vbudhram ([cc6e08b](https://github.com/mozilla/fxa-auth-db-mysql/commit/cc6e08b))
* **test:** correct promises error handling (#325) r=@eoger ([7effcb3](https://github.com/mozilla/fxa-auth-db-mysql/commit/7effcb3))

### chore

* **api:** remove bufferization from db layer ([818edcf](https://github.com/mozilla/fxa-auth-db-mysql/commit/818edcf))

### Features

* **devices:** Devices capabilities (#320) r=@philbooth ([4808a1c](https://github.com/mozilla/fxa-auth-db-mysql/commit/4808a1c))
* **node:** update to node v6.13.1 r=@jbuck ([7727d88](https://github.com/mozilla/fxa-auth-db-mysql/commit/7727d88))
* **totp:** initial recovery codes (#319), r=@philbooth ([995d52b](https://github.com/mozilla/fxa-auth-db-mysql/commit/995d52b))

<a name="1.107.1"></a>
# [1.107.1](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.107.0...v1.107.1) (2018-03-21)


### Bug Fixes
* **emails:** Make all request paths containing an email use hex encoding. (#1); r=philbooth ([6059aca](https://github.com/mozilla/fxa-auth-db-mysql/commit/6059aca))


<a name="1.107.0"></a>
# [1.107.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.106.0...v1.107.0) (2018-03-07)


### chore

* **tests:** cleanup `sessionToken` endpoints and docs, r=@philbooth, @rfk ([da2e9ef](https://github.com/mozilla/fxa-auth-db-mysql/commit/da2e9ef))

### Features

* **totp:** Add initial totp session verification logic (#309), r=@philbooth ([ee19e1b](https://github.com/mozilla/fxa-auth-db-mysql/commit/ee19e1b))
* **totp:** vlad updates for totp (#313) r=@vladikoff ([f6d603c](https://github.com/mozilla/fxa-auth-db-mysql/commit/f6d603c))



<a name="1.106.0"></a>
# [1.106.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.105.0...v1.106.0) (2018-02-21)


### Bug Fixes

* **token:** Fix mem verifyTokenCode (#303), r=@rfk, @philbooth ([6a4fb67](https://github.com/mozilla/fxa-auth-db-mysql/commit/6a4fb67)), closes [(#303](https://github.com/(/issues/303)

### chore

* **deps:** update deps, fix nsp (#308) r=@philbooth ([0d874f9](https://github.com/mozilla/fxa-auth-db-mysql/commit/0d874f9)), closes [(#308](https://github.com/(/issues/308)

### Features

* **sessions:** Add support for reauth on an existing session. (#305); r=philbooth ([fdff3e9](https://github.com/mozilla/fxa-auth-db-mysql/commit/fdff3e9))
* **totp:** Add totp management api (#299), r=@philbooth ([9b8efcb](https://github.com/mozilla/fxa-auth-db-mysql/commit/9b8efcb))



<a name="1.105.0"></a>
# [1.105.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.104.0...v1.105.0) (2018-02-06)


### Features

* **tests:** make tests more independent (#293), r=@philbooth, @rfk ([c7d3638](https://github.com/mozilla/fxa-auth-db-mysql/commit/c7d3638))



<a name="1.104.0"></a>
# [1.104.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.103.0...v1.104.0) (2018-01-23)


### Bug Fixes

* **pruning:** Avoid accidental full-table scans when pruning session tokens. (#295); r=philboo ([5c6622c](https://github.com/mozilla/fxa-auth-db-mysql/commit/5c6622c))
* **scripts:** add SET NAMES to reverse migration boilerplate (#296), r=@vbudhram ([0790b89](https://github.com/mozilla/fxa-auth-db-mysql/commit/0790b89))

### Features

* **devices:** return session token id from deleteDevice ([a2dd244](https://github.com/mozilla/fxa-auth-db-mysql/commit/a2dd244))



<a name="1.103.0"></a>
# [1.103.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.101.0...v1.103.0) (2018-01-09)


### Bug Fixes

* **node:** use node 6.12.3 (#291) r=@vladikoff ([6080c0c](https://github.com/mozilla/fxa-auth-db-mysql/commit/6080c0c))

### Features

* **logs:** add Sentry for errors (#292) r=@vbudhram ([6348a95](https://github.com/mozilla/fxa-auth-db-mysql/commit/6348a95)), closes [#288](https://github.com/mozilla/fxa-auth-db-mysql/issues/288)



<a name="1.101.0"></a>
# [1.101.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.100.0...v1.101.0) (2017-11-29)


### Features

* **codes:** add support for verifying token short code (#287) r=@vladikoff,@rfk ([ac0b814](https://github.com/mozilla/fxa-auth-db-mysql/commit/ac0b814))

### Refactor

* **dbserver:** clean up the db server package (#289) r=@rfk ([c3d8e6e](https://github.com/mozilla/fxa-auth-db-mysql/commit/c3d8e6e))



<a name="1.100.0"></a>
# [1.100.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.98.0...v1.100.0) (2017-11-15)


### Bug Fixes

* **newrelic:** futureproofing comment and up to newrelic@2.3.2 with npm run shrink (#285) r=@vl ([bfc1963](https://github.com/mozilla/fxa-auth-db-mysql/commit/bfc1963))
* **newrelic:** newrelic native requires make, python, gyp, c++; update node 6.12.0 (#286) r=@vl ([4b7e696](https://github.com/mozilla/fxa-auth-db-mysql/commit/4b7e696))
* **travis:** run tests with 6 and current stable (failure not allowed anymore) ([c4e0e98](https://github.com/mozilla/fxa-auth-db-mysql/commit/c4e0e98))



<a name="1.98.0"></a>
# [1.98.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.97.0...v1.98.0) (2017-10-26)


### chore

* **docker:** Update to node v6.11.5 for security fix ([7cc3251](https://github.com/mozilla/fxa-auth-db-mysql/commit/7cc3251))



<a name="1.97.0"></a>
# [1.97.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.96.1...v1.97.0) (2017-10-04)


### Features

* **db:** prune session tokens (again) ([67bd8fb](https://github.com/mozilla/fxa-auth-db-mysql/commit/67bd8fb))



<a name="1.96.1"></a>
## [1.96.1](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.96.0...v1.96.1) (2017-09-20)


### Bug Fixes

* **db:** call latest version of the prune stored procedure (#281) r=vladikoff ([2c34f2e](https://github.com/mozilla/fxa-auth-db-mysql/commit/2c34f2e))



<a name="1.96.0"></a>
# [1.96.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.95.1...v1.96.0) (2017-09-19)


### Bug Fixes

* **tokens:** revert session-token pruning ([ecde71b](https://github.com/mozilla/fxa-auth-db-mysql/commit/ecde71b))



<a name="1.95.1"></a>
## [1.95.1](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.95.0...v1.95.1) (2017-09-12)


### Bug Fixes

* **mysql:** update all device procedures to use utf8mb4 (#276) r=jbuck,rfk ([7d22ad8](https://github.com/mozilla/fxa-auth-db-mysql/commit/7d22ad8))
* **tokens:** prune old session tokens that have no device record ([8fad575](https://github.com/mozilla/fxa-auth-db-mysql/commit/8fad575))



<a name="1.95.0"></a>
# [1.95.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.94.1...v1.95.0) (2017-09-06)


### chore

* **docs:** update node version in docs to 6 ([63fbdf2](https://github.com/mozilla/fxa-auth-db-mysql/commit/63fbdf2))

### Features

* **schema:** add a pushEndpointExpired column to devices ([d8e93c4](https://github.com/mozilla/fxa-auth-db-mysql/commit/d8e93c4))



<a name="1.94.1"></a>
## [1.94.1](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.94.0...v1.94.1) (2017-08-23)


### Features

* **db:** add utf8mb4 support (#267) r=rfk ([549d39f](https://github.com/mozilla/fxa-auth-db-mysql/commit/549d39f))



<a name="1.94.0"></a>
# [1.94.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.93.0...v1.94.0) (2017-08-21)


### chore

* **ci:** remove node4 test targets from travis-ci (#270) r=vladikoff ([9523d02](https://github.com/mozilla/fxa-auth-db-mysql/commit/9523d02))
* **email:** Remove emailRecord depreciation (#269), r=@philbooth ([0a7c2c6](https://github.com/mozilla/fxa-auth-db-mysql/commit/0a7c2c6))

### Features

* **schema:** add a uaFormFactor column to sessionTokens (#271) r=vladikoff ([774b6c1](https://github.com/mozilla/fxa-auth-db-mysql/commit/774b6c1))



<a name="1.93.0"></a>
# [1.93.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.92.0...v1.93.0) (2017-08-09)


### Features

* **docker:** update to node 6 (#266) r=jbuck ([7b13cea](https://github.com/mozilla/fxa-auth-db-mysql/commit/7b13cea))



<a name="1.92.0"></a>
# [1.92.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.91.2...v1.92.0) (2017-07-26)


### chore

* **scripts:** add a script to generate migration boilerplate (#261) r=vladikoff ([45949c5](https://github.com/mozilla/fxa-auth-db-mysql/commit/45949c5))
* **tests:** don't make eslint a prerequisite for the tests (#258), r=@vbudhram ([ddae438](https://github.com/mozilla/fxa-auth-db-mysql/commit/ddae438))



<a name="1.91.2"></a>
## [1.91.2](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.91.1...v1.91.2) (2017-07-17)


### Features

* **schema:** drop the uaFormFactor column from sessionTokens (#262), r=@vbudhram ([f23098a](https://github.com/mozilla/fxa-auth-db-mysql/commit/f23098a))



<a name="1.91.1"></a>
## [1.91.1](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.91.0...v1.91.1) (2017-07-12)


### Bug Fixes

* **nodejs:** upgrade to 4.8.4 for security fixes ([450e931](https://github.com/mozilla/fxa-auth-db-mysql/commit/450e931))



<a name="1.91.0"></a>
# [1.91.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.90.0...v1.91.0) (2017-07-12)


### Features

* **email:** Add change email (#254), r=@philbooth ([7253d09](https://github.com/mozilla/fxa-auth-db-mysql/commit/7253d09))
* **email:** correctly return `createdAt` when using accountRecord (#256), r=@philbooth ([70a1a39](https://github.com/mozilla/fxa-auth-db-mysql/commit/70a1a39))
* **schema:** add a uaFormFactor column to sessionTokens ([e99bc19](https://github.com/mozilla/fxa-auth-db-mysql/commit/e99bc19))



<a name="1.90.0"></a>
# [1.90.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.89.1...v1.90.0) (2017-06-28)


### chore

* **eslint:** update to latest eslint (#252) r=vbudhram ([1157bb2](https://github.com/mozilla/fxa-auth-db-mysql/commit/1157bb2))
* **train:** uplift train 89 (#253), r=@philbooth ([06944e8](https://github.com/mozilla/fxa-auth-db-mysql/commit/06944e8))

### Features

* **db:** store flowIds with signinCodes ([3fac7d7](https://github.com/mozilla/fxa-auth-db-mysql/commit/3fac7d7))
* **email:** Update procedures to use email table (#245), r=@philbooth, @rfk ([b896063](https://github.com/mozilla/fxa-auth-db-mysql/commit/b896063))
* **tokens:** Add ability to reset accounts tokens (#249), r=@philbooth ([92199bc](https://github.com/mozilla/fxa-auth-db-mysql/commit/92199bc))



<a name="1.89.3"></a>
## [1.89.3](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.89.2...v1.89.3) (2017-06-21)


### Features

* **email:** Don't use subquery on email verify update (#251), r=@jbuck ([102dea4](https://github.com/mozilla/fxa-auth-db-mysql/commit/102dea4))



<a name="1.89.2"></a>
## [1.89.2](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.89.1...v1.89.2) (2017-06-21)


### Features

* **email:** Remove temporary table from `accountEmails` query (#250), r=@rfk, @jbuck ([e9d0335](https://github.com/mozilla/fxa-auth-db-mysql/commit/e9d0335))



<a name="1.89.1"></a>
## [1.89.1](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.89.0...v1.89.1) (2017-06-14)


### Features

* **email:** Add email table migration script (#247), r=@rfk, @jbuck ([9ef8cbf](https://github.com/mozilla/fxa-auth-db-mysql/commit/9ef8cbf))



<a name="1.89.0"></a>
# [1.89.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.87.0...v1.89.0) (2017-06-13)


### Features

* **db:** enable signinCode expiry ([2b53553](https://github.com/mozilla/fxa-auth-db-mysql/commit/2b53553))
* **email:** Keep account email and emails table in sync (#241), r=@rfk, @philbooth ([78d5559](https://github.com/mozilla/fxa-auth-db-mysql/commit/78d5559))

### Refactor

* **test:** refactor our tests to use Mocha instead of TAP ([0441ea9](https://github.com/mozilla/fxa-auth-db-mysql/commit/0441ea9))



<a name="1.87.0"></a>
# [1.87.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.85.0...v1.87.0) (2017-05-17)


### Bug Fixes

* **docs:** update authors and node.js version in README ([5610b92](https://github.com/mozilla/fxa-auth-db-mysql/commit/5610b92))
* **email:** Use correct delete account procedure (#231) ([4a16bf3](https://github.com/mozilla/fxa-auth-db-mysql/commit/4a16bf3))

### chore

* **docker:** Use official node image & update to Node.js v4.8.2 (#225) r=vladikoff ([2298e38](https://github.com/mozilla/fxa-auth-db-mysql/commit/2298e38))

### Features

* **docker:** add custom feature branch (#237) r=jrgm ([d21a8df](https://github.com/mozilla/fxa-auth-db-mysql/commit/d21a8df))
* **email:** Add get email endpoint (#227), r=@vladikoff, @rfk ([8f5653c](https://github.com/mozilla/fxa-auth-db-mysql/commit/8f5653c))
* **signinCodes:** migration and endpoints for signinCodes table (#235), r=@vbudhram ([b740793](https://github.com/mozilla/fxa-auth-db-mysql/commit/b740793))
* **tokens:** prune tokens older than 3 months (#224) r=vladikoff ([fdc19c1](https://github.com/mozilla/fxa-auth-db-mysql/commit/fdc19c1)), closes [#219](https://github.com/mozilla/fxa-auth-db-mysql/issues/219)



<a name="1.86.0"></a>
# [1.86.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v1.85.0...v1.86.0) (2017-05-01)


### Bug Fixes

* **docs:** update authors and node.js version in README ([6d89d30](https://github.com/mozilla/fxa-auth-db-mysql/commit/6d89d30))

### chore

* **docker:** Use official node image & update to Node.js v4.8.2 (#225) r=vladikoff ([2298e38](https://github.com/mozilla/fxa-auth-db-mysql/commit/2298e38))

### Features

* **email:** Add get email endpoint (#227), r=@vladikoff, @rfk ([8f5653c](https://github.com/mozilla/fxa-auth-db-mysql/commit/8f5653c))
* **tokens:** prune tokens older than 3 months (#224) r=vladikoff ([fdc19c1](https://github.com/mozilla/fxa-auth-db-mysql/commit/fdc19c1)), closes [#219](https://github.com/mozilla/fxa-auth-db-mysql/issues/219)



<a name="1.85.0"></a>
# [1.85.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.83.0...v1.85.0) (2017-04-18)


### Bug Fixes

* **install:** add formatter to main package.json (#222) ([f4cb995](https://github.com/mozilla/fxa-auth-db-mysql/commit/f4cb995))
* **security:** escape json output (#220) r=vladikoff ([13b9f70](https://github.com/mozilla/fxa-auth-db-mysql/commit/13b9f70))

### chore

* **dependencies:** update all our production dependencies (#217) r=vladikoff ([e008849](https://github.com/mozilla/fxa-auth-db-mysql/commit/e008849))



<a name="0.83.0"></a>
# [0.83.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.82.0...v0.83.0) (2017-03-21)


### Bug Fixes

* **config:** Add environment variable for ipHmacKey ([65f6d78](https://github.com/mozilla/fxa-auth-db-mysql/commit/65f6d78))
* **emailBounces:** receive the email parameter in the url as hex ([e1c078b](https://github.com/mozilla/fxa-auth-db-mysql/commit/e1c078b))
* **security-events:** Correctly handle tokenless security events in mem backend (#215) r=vladikoff,sea ([0f816cb](https://github.com/mozilla/fxa-auth-db-mysql/commit/0f816cb))

### Features

* **email:** Add support for adding additional emails (#211), r=@seanmonstar, @rfk ([1c436c9](https://github.com/mozilla/fxa-auth-db-mysql/commit/1c436c9))



<a name="0.82.0"></a>
# [0.82.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.81.0...v0.82.0) (2017-03-06)


### Features

* **docker:** add docker via Circle CI (#212) r=jbuck,seanmonstar ([8f913be](https://github.com/mozilla/fxa-auth-db-mysql/commit/8f913be)), closes [#208](https://github.com/mozilla/fxa-auth-db-mysql/issues/208)
* **sessions:** update the sessions query to include device information (#203) r=vbudhram  ([70dcc5b](https://github.com/mozilla/fxa-auth-db-mysql/commit/70dcc5b))



<a name="0.81.0"></a>
# [0.81.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.76.0...v0.81.0) (2017-02-23)


### Bug Fixes

* **email:** Return `createdAt` when calling db.emailRecord (#209), r=@rfk ([1a226cc](https://github.com/mozilla/fxa-auth-db-mysql/commit/1a226cc))
* **reminders:** adjust mysql procedures (#200) r=rfk ([4b6a92d](https://github.com/mozilla/fxa-auth-db-mysql/commit/4b6a92d))
* **style:** replace tab char with a space (#207) r=rfk ([44470ad](https://github.com/mozilla/fxa-auth-db-mysql/commit/44470ad))

### Features

* **db:** add emailBounces table ([4fe29fa](https://github.com/mozilla/fxa-auth-db-mysql/commit/4fe29fa))
* **tokens:** add prune token maxAge and update pruning (#206); r=rfk ([699c352](https://github.com/mozilla/fxa-auth-db-mysql/commit/699c352))
* **tokens:** get the device associated with a tokenVerificationId (#204) r=vladikoff ([7f45075](https://github.com/mozilla/fxa-auth-db-mysql/commit/7f45075))



<a name="0.76.0"></a>
# [0.76.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.75.0...v0.76.0) (2016-12-13)


### Bug Fixes

* **schema:** Complete final phase of several previous migrations ([7eddbc9](https://github.com/mozilla/fxa-auth-db-mysql/commit/7eddbc9))

### chore

* **deps:** add new shrinkwrap command (#193) ([b33c750](https://github.com/mozilla/fxa-auth-db-mysql/commit/b33c750)), closes [#189](https://github.com/mozilla/fxa-auth-db-mysql/issues/189)



<a name="0.75.0"></a>
# [0.75.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.74.0...v0.75.0) (2016-11-30)


### Bug Fixes

* **bufferize:** Only bufferize params we explicitly want as buffers. (#182); r=philbooth ([a461769](https://github.com/mozilla/fxa-auth-db-mysql/commit/a461769))
* **bufferize:** Only bufferize params we explicitly want as buffers. (#187) r=vladikoff ([aad12bb](https://github.com/mozilla/fxa-auth-db-mysql/commit/aad12bb))

### Reverts

* **bufferize:** revert the extra bufferize logic ([e913a66](https://github.com/mozilla/fxa-auth-db-mysql/commit/e913a66))



<a name="0.74.0"></a>
# [0.74.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.72.0...v0.74.0) (2016-11-15)


### chore

* **lint:** Include ./bin/*.js in eslint coverage ([6c8eeba](https://github.com/mozilla/fxa-auth-db-mysql/commit/6c8eeba))
* **securityEvents:** Stop writing to the `securityEvents.tokenId` column. ([1e3763d](https://github.com/mozilla/fxa-auth-db-mysql/commit/1e3763d))

### Features

* **eventLog:** Remove the unused "eventLog" feature. ([a138e76](https://github.com/mozilla/fxa-auth-db-mysql/commit/a138e76))



<a name="0.72.0"></a>
# [0.72.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.71.0...v0.72.0) (2016-10-19)


### Bug Fixes

* **securityEvents:** Tweak securityEvents db queries based on @jrgm feedback ([ffa5561](https://github.com/mozilla/fxa-auth-db-mysql/commit/ffa5561))



<a name="0.71.0"></a>
# [0.71.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.70.0...v0.71.0) (2016-10-05)


### Bug Fixes

* **travis:** drop node 0.10 test config ([c1b1841](https://github.com/mozilla/fxa-auth-db-mysql/commit/c1b1841))

### chore

* **travis:** add node 6 explicitly to travis (#175) r=vladikoff ([c1556ab](https://github.com/mozilla/fxa-auth-db-mysql/commit/c1556ab))

### Features

* **unblock:** add unblockCode support ([12fb9df](https://github.com/mozilla/fxa-auth-db-mysql/commit/12fb9df))



<a name="0.70.0"></a>
# [0.70.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.69.0...v0.70.0) (2016-09-24)


### Bug Fixes

* **security:** Fix the endpoints for /securityEvents. ([5dfd5f8](https://github.com/mozilla/fxa-auth-db-mysql/commit/5dfd5f8)), closes [#171](https://github.com/mozilla/fxa-auth-db-mysql/issues/171)

### Features

* **db:** return account.email from accountDevices ([b090367](https://github.com/mozilla/fxa-auth-db-mysql/commit/b090367))
* **security:** add security events ([cc31172](https://github.com/mozilla/fxa-auth-db-mysql/commit/cc31172))



<a name="0.69.0"></a>
# [0.69.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.68.0...v0.69.0) (2016-09-09)


### Bug Fixes

* **db:** don't return zombie devices from accountDevices ([6e5c2db](https://github.com/mozilla/fxa-auth-db-mysql/commit/6e5c2db))
* **db:** Fix the typo ([7bfdf91](https://github.com/mozilla/fxa-auth-db-mysql/commit/7bfdf91))
* **db:** Update resetAccount to not delete from accountUnlockCodes ([616602a](https://github.com/mozilla/fxa-auth-db-mysql/commit/616602a))
* **shrinkwrap:** refresh shrinkwrap ([83d94d4](https://github.com/mozilla/fxa-auth-db-mysql/commit/83d94d4))

### feature

* **newrelic:** add optional newrelic integration ([fca7e2e](https://github.com/mozilla/fxa-auth-db-mysql/commit/fca7e2e))

### Refactor

* **db:** Remove account unlock related code. ([340e299](https://github.com/mozilla/fxa-auth-db-mysql/commit/340e299))



<a name="0.68.0"></a>
# [0.68.0](https://github.com/mozilla/fxa-auth-db-mysql/compare/v0.67.0...v0.68.0) (2016-08-24)


### Bug Fixes

* **db:** ensure that devices get deleted with session tokens ([840dda6](https://github.com/mozilla/fxa-auth-db-mysql/commit/840dda6))
* **db:** use an index when deleting device records by sessionToken id. ([f5bbb60](https://github.com/mozilla/fxa-auth-db-mysql/commit/f5bbb60))
* **scripts:** add process.exit to populate script ([7820fdc](https://github.com/mozilla/fxa-auth-db-mysql/commit/7820fdc))
* **scripts:** ensure changelog is updated sanely ([24376cc](https://github.com/mozilla/fxa-auth-db-mysql/commit/24376cc))

### Features

* **scripts:** add device records to the populate script ([c235696](https://github.com/mozilla/fxa-auth-db-mysql/commit/c235696))



# 0.67.0

  * fix(deps): update dev dependencies #143
  * fix(deps): update prod dependencies #144
  * chore(readme): update travis status badge url
  * fix(tests): switch coverage tool, add coveralls #145
  * chore(deps): update to latest request and sinon #148
  * feat(db): Remove account lockout #147
  * fix(db): remove createAccountResetToken stored procedure and endpoint #154
  * refactor(db): remove openId #153
  * feat(db): Record whether we *must* verify each unverified token #155

# 0.63.0

  * feat(db): implement verification state for key fetch tokens #138
  * chore(travis): drop node 0.12 support #139
  * feat(reminders): add verification reminders #127
  * chore(mozlog): update from mozlog@2.0.3 to 2.0.5 #140
  * chore(scripts): sort scripts alphabetically #140
  * chore(shrinkwrap): add "npm run shrinkwrap" script #140

# 0.62.0

  * feat(mx-stats): Add a script to print stats on popular mail providers #134
  * feat(db): store push keys according to the current implementation #133
  * feat(db): implement new token verification logic #132

# 0.59.0

  * fix(logging): log connection config and charset info at startup #131
  * fix(tests): adjust notifier tests monkeypatching to accept mozlog signature #130
  * fix(logging): adjust logging method calls to use mozlog signature #130
  * fix(tests): enforce mozlog rules in test logger #130

# 0.58.0

  *  fix(db): expunge devices in resetAccount sproc #128

# 0.57.0

  * feat(devices): added sessionWithDevice endpoint
  * chore(dependencies): upgrade mozlog to 2.0.3

# 0.55.0

  * feat(docker): Additional Dockerfile for self-hosting #121
  * docs(contributing): Mention git commit guidelines #122

# train-53

  * chore(deps): Update mysql package dependency to latest version #112
  * fix(tests): Upgrade test runner and fix some test declarations #112

# train-51

  * fix(travis): build and test on 0.10, 0.12 and 4.x, and allow failure on >= 5.x
  * chore(shrinkwrap): update npm-shrinkwrap.json

# train-50.1

  * fix(db): fix memory-store initialisation of device fields to null #117
  * fix(version): print out constructor class name; adds /__version__ alias #118

# train-50

  * chore(nsp): re-added shrinkwrap validation to travis
  * fix(server): fix bad route parameter name
  * feat(db): update devices to match new requirements

# train-49

  * reverted some dependencies to previous versions due to #113

# train-48

  * feat(db): add device registration and management endpoints #110

# train-46

  * feat(db): add endpoint to return a user's sessions #102
  * feat(db): return accountCreatedAt from sessionToken stored procedure #105
  * chore(metadata): Update package metadata for stand-alone server lib. #106

# train-45

  * fix(metrics): measure request count and time in perf tests - #97
  * fix(metrics): append delimiter to metrics output - #94
  * chore(version): generate legacy-format output for ./config/version.json - #101
  * chore(metrics): add script for creating dummy session tokens - #100
  * chore(metrics): report latency in performance tests - #99
  * chore(eslint): change complexity rule - #96
  * chore(metrics): add scripts for perf-testing metrics queries - #88

# train-44

  * There are no longer separate fxa-auth-db-mysql and fxa-auth-db-server repositories - assemble all db repos - #56
  * preliminary support for authenticating with OpenID - #78
  * feat(db): add script for reporting metrics #80
  * feat(db): store user agent and last-access time in sessionTokens - #65
  * refactor(config): Use human-readable duration values in config - #62
  * fix(tests): used a randomized openid url - #92
  * fix(db): default user-agent fields to null in memory backend - #90
  * fix(server): prevent insane bufferization of non-hex parameters - #89
  * chore(configs): eliminate sub-directory dotfiles - #69
  * chore(package): expose scripts for running and testing db-mem - #71
  * chore(project): merge db-server project admin/config stuff to top level - #74
  * chore(docs): update readme and api docs for merged repos - #76
  * reshuffle package.json (use file paths, not file: url) - #77
  * chore(coverage): exclude fxa-auth-db-server/node_modules from coverage checks - #82

# train-42

  * fix(tests): pass server object to backend tests - #63
  * refactor(db): remove verifyHash from responses - #48
  * chore(shrinkwrap): update shrinkwrap for verifyHash removal - #61
  * chore(shrinkwrap): update shrinkwrap, principally to head of fxa-auth-db-server - #63

# train-41

  * feat(api): Return the account email address on passwordChangeToken - #59
  * chore(travis): Tell Travis to use #fxa-bots - #60

# train-40

  * fix(notifications): always return a promise from db.processUnpublishedEvents, fixes #49 - #52
  * fix(npm): Update npm-shrinkwrap to include the last version of fxa-auth-db-server - #50
  * chore(cleanup): Fixed some syntax errors reported by ESLint - #55
  * fix(db): Return 400 on incorrect password - #53
  * refactor(db): Remove old stored procedures that are no longer used - #57

# train-39

  * fix(npm): Update npm-shrinkwrap to include the last version of fxa-auth-db-server - #50
  * Added checkPassword_1 stored procedure - #45
  * Use array for Mysql read() bound parameters - #45
  * chore(license): Update license to be SPDX compliant - #46

# train-37

  * refactor(lib): move most things into lib/
  * build(travis): Test on both io.js v1 and v2
  * chore(shrinkwrap): update shrinkwrap picking up lib changes in fxa-auth-db-server

# train-36

  * refactor(db): Change table access in stored procedures to be consistent - #36
  * fix(db): Fix reverse patches 8->7 and 9->8 - #38
  * fix(package): Remove uuid completely since no longer needed - #37
  * chore(package): Update to mysql-patcher@0.7.0 - #39
  * chore(copyright): Update to grunt-copyright v0.2.0 - #40
  * chore(test): Test on node.js v0.10, v0.12 and the latest io.js - #41

# train-35

  * there was no train-35 for fxa-auth-db-mysql

# train-34

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

# train-33

  * Log account activity events for later publishing to notification service - #20
  * Fix tests to do more reliable error-message detection - #20
  * Correctly pass pool name when getting a connection - #23
  * Use mozlog for logging - #21
  * Log memory-usage stats emitted by fxa-auth-db-server - #24
  * Some documentation and packaging tweaks - #17, #18

# train-32

  * Add ability to mark an account as "locked" for security reasons - #7
  * Add support for docker-based development workflow - #13


# train-31

  * Only fail with a DB patch level less than the one expected
  * (hotfix) regenerated npm-shrinkwrap.json that uses the correct version of fxa-auth-db-server - #15
