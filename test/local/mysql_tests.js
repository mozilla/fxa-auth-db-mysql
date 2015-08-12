/* Any copyright is dedicated to the Public Domain.
 * http://creativecommons.org/publicdomain/zero/1.0/ */

require('ass')
var dbServer = require('../../fxa-auth-db-server')
var log = { trace: console.log, error: console.log, stat: console.log, info: console.log }
var DB = require('../../lib/db/mysql')(log, dbServer.errors)
var config = require('../../config')
var test = require('../ptaptest')
var P = require('../../lib/promise')
var crypto = require('crypto')

var zeroBuffer16 = Buffer('00000000000000000000000000000000', 'hex')
var zeroBuffer32 = Buffer('0000000000000000000000000000000000000000000000000000000000000000', 'hex')

DB.connect(config)
  .then(
    function (db) {

      test(
        'ping',
        function (t) {
          t.plan(1)
          return db.ping()
          .then(function(account) {
            t.pass('Got the ping ok')
          }, function(err) {
            t.fail('Should not have arrived here')
          })
        }
      )

      test(
        'a select on an unknown table should result in an error',
        function (t) {
          var query = 'SELECT mumble as id FROM mumble.mumble WHERE mumble = ?'
          var param = 'mumble'
          db.read(query, param)
            .then(
              function(result) {
                t.plan(1)
                t.fail('Should not have arrived here for an invalid select')
              },
              function(err) {
                t.plan(5)
                t.ok(err, 'we have an error')
                t.equal(err.code, 500)
                t.equal(err.errno, 1146)
                t.equal(err.error, 'Internal Server Error')
                t.equal(err.message, 'ER_NO_SUCH_TABLE')
              }
            )
        }
      )

      test(
        'an update to an unknown table should result in an error',
        function (t) {
          var query = 'UPDATE mumble.mumble SET mumble = ?'
          var param = 'mumble'

          db.write(query, param)
            .then(
              function(result) {
                t.plan(1)
                t.fail('Should not have arrived here for an invalid update')
              },
              function(err) {
                t.plan(5)
                t.ok(err, 'we have an error')
                t.equal(err.code, 500)
                t.equal(err.errno, 1146)
                t.equal(err.error, 'Internal Server Error')
                t.equal(err.message, 'ER_NO_SUCH_TABLE')
              }
            )
        }
      )

      test(
        'an transaction to update an unknown table should result in an error',
        function (t) {
          var sql = 'UPDATE mumble.mumble SET mumble = ?'
          var param = 'mumble'

          function query(connection, sql, params) {
            var d = P.defer()
            connection.query(
              sql,
              params || [],
              function (err, results) {
                if (err) { return d.reject(err) }
                d.resolve(results)
              }
            )
            return d.promise
          }

          db.transaction(
            function (connection) {
              return query(connection, sql, param)
            })
            .then(
              function(result) {
                t.plan(1)
                t.fail('Should not have arrived here for an invalid update')
              },
              function(err) {
                t.plan(5)
                t.ok(err, 'we have an error')
                t.equal(err.code, 500)
                t.equal(err.errno, 1146)
                t.equal(err.error, 'Internal Server Error')
                t.equal(err.message, 'ER_NO_SUCH_TABLE')
              }
            )
        }
      )

      test(
        'retryable does retry when the errno is matched',
        function (t) {
          var query = 'UPDATE mumble.mumble SET mumble = ?'
          var param = 'mumble'

          var callCount = 0

          var writer = function() {
            ++callCount
            return db.write(query, param)
              .then(
                function(result) {
                  t.fail('this query should never succeed!')
                },
                function(err) {
                  t.ok(true, 'we got an error')
                  t.equal(err.code, 500)
                  t.equal(err.errno, 1146)
                  t.equal(err.error, 'Internal Server Error')
                  t.equal(err.message, 'ER_NO_SUCH_TABLE')
                  throw err
                }
              )
          }

          db.retryable_(writer, [ 1146 ])
            .then(
              function(result) {
                t.fail('This should never happen, even with a retry ' + callCount)
                t.end()
              },
              function(err) {
                t.equal(callCount, 2, 'the function was retried')
                t.end()
              }
            )
        }
      )

      test(
        'check that an error in a stored procedure (with transaction) is propagated back',
        function (t) {
          // let's add a stored procedure which will cause an error
          var dropProcedure = 'DROP PROCEDURE IF EXISTS `testStoredProcedure`;'
          var ensureProcedure = [
            'CREATE PROCEDURE `testStoredProcedure` ()',
            'BEGIN',
            '    DECLARE EXIT HANDLER FOR SQLEXCEPTION',
            '    BEGIN',
            '        -- ERROR',
            '        ROLLBACK;',
            '        RESIGNAL;',
            '    END;',
            '    START TRANSACTION;',
            '    INSERT INTO accounts(uid) VALUES(null);',
            '    COMMIT;',
            'END;',
          ].join('\n')

          t.plan(5)

          db.write(dropProcedure, [])
            .then(function() {
              t.pass('Drop procedure was successful')
              return db.write(ensureProcedure, [])
            })
            .then(
              function(result) {
                t.pass('The stored procedure creation was successful')
              },
              function(err) {
                t.fail('Error when creating a stored procedure' + err)
              }
            )
            .then(function() {
              // monkey patch the DB so that we're doing what the other writes to stored procedures are doing
              db.testStoredProcedure = function() {
                var callProcedure = 'CALL testStoredProcedure()'
                return this.write(callProcedure)
              }
              return db.testStoredProcedure()
            })
            .then(function() {
              t.fail('The call to the stored prodcedure should have failed')
              t.end()
            }, function(err) {
              t.pass('The call to the stored procedure failed as expected')
              t.equal(err.code, 500, 'error code is correct')
              var possibleErrors = [
                { msg: 'ER_BAD_NULL_ERROR', errno: 1048 },
                { msg: 'ER_NO_DEFAULT_FOR_FIELD', errno: 1364 }
              ]
              var matchedError = false
              possibleErrors.forEach(function(possibleErr) {
                if (err.message === possibleErr.msg) {
                  if (err.errno === possibleErr.errno ) {
                    matchedError = true
                  }
                }
              })
              t.ok(matchedError, 'error message and errno are correct')
              t.end()
            })
        }
      )

      test(
        'metrics',
        function (t) {
          var lastResults
          var uid
          var times = [
            Date.now()
          ]
          t.plan(26)
          P.all([
            db.countAccountsCreatedBefore(times[0]),
            db.countVerifiedAccountsCreatedBefore(times[0]),
            db.countAccountsWithTwoOrMoreDevices(),
            db.countAccountsWithThreeOrMoreDevices(),
            db.countAccountsWithMobileDevice()
          ]).then(function (results) {
            results.forEach(function (result, index) {
              t.ok(result.count >= 0, 'returned non-negative count [' + index + ']')
            })
            lastResults = results
            uid = crypto.randomBytes(16)
            times[1] = Date.now()
            return createAccount(uid, times[1], false)
          }).then(function () {
            return P.all([
              db.countAccountsCreatedBefore(times[1] + 1),
              db.countVerifiedAccountsCreatedBefore(times[1] + 1),
              db.countAccountsWithTwoOrMoreDevices(),
              db.countAccountsWithThreeOrMoreDevices(),
              db.countAccountsWithMobileDevice()
            ])
          }).then(function (results) {
            t.ok(results[0].count === lastResults[0].count + 1, 'account count was incremented by one')
            t.ok(results[1].count === lastResults[1].count, 'verified account count was not incremented')
            t.ok(results[2].count === lastResults[2].count, '2+ device account count was not incremented')
            t.ok(results[3].count === lastResults[3].count, '3+ device account count was not incremented')
            t.ok(results[4].count === lastResults[4].count, 'mobile device account count was not incremented')
            lastResults = results
            return deleteAccount(uid)
          }).then(function () {
            times[2] = Date.now()
            return createAccount(uid, times[2], true)
          }).then(function () {
            return P.all([
              db.countAccountsCreatedBefore(times[2] + 1),
              db.countVerifiedAccountsCreatedBefore(times[2] + 1),
              db.countAccountsWithTwoOrMoreDevices(),
              db.countAccountsWithThreeOrMoreDevices(),
              db.countAccountsWithMobileDevice()
            ])
          }).then(function (results) {
            t.ok(results[0].count === lastResults[0].count, 'account count was not incremented')
            t.ok(results[1].count === lastResults[1].count + 1, 'verified account count was incremented by one')
            t.ok(results[2].count === lastResults[2].count, '2+ device account count was not incremented')
            t.ok(results[3].count === lastResults[3].count, '3+ device account count was not incremented')
            t.ok(results[4].count === lastResults[4].count, 'mobile device account count was not incremented')
            lastResults = results
            return P.all([
              createSessionToken(uid),
              createSessionToken(uid)
            ])
          }).then(function () {
            return P.all([
              db.countAccountsCreatedBefore(times[2] + 1),
              db.countVerifiedAccountsCreatedBefore(times[2] + 1),
              db.countAccountsWithTwoOrMoreDevices(),
              db.countAccountsWithThreeOrMoreDevices(),
              db.countAccountsWithMobileDevice()
            ])
          }).then(function (results) {
            t.ok(results[0].count === lastResults[0].count, 'account count was not incremented')
            t.ok(results[1].count === lastResults[1].count, 'verified account count was not incremented')
            t.ok(results[2].count === lastResults[2].count + 1, '2+ device account count was incremented by one')
            t.ok(results[3].count === lastResults[3].count, '3+ device account count was not incremented')
            t.ok(results[4].count === lastResults[4].count, 'mobile device account count was not incremented')
            lastResults = results
            return createSessionToken(uid)
          }).then(function () {
            return P.all([
              db.countAccountsWithTwoOrMoreDevices(),
              db.countAccountsWithThreeOrMoreDevices(),
              db.countAccountsWithMobileDevice()
            ])
          }).then(function (results) {
            t.ok(results[0].count === lastResults[2].count, '2+ device account count was not incremented')
            t.ok(results[1].count === lastResults[3].count + 1, '3+ device account count was incremented by one')
            t.ok(results[2].count === lastResults[4].count, 'mobile device account count was not incremented')
            lastResults = results
            return createSessionToken(uid, 'mobile')
          }).then(function () {
            return P.all([
              db.countAccountsWithTwoOrMoreDevices(),
              db.countAccountsWithThreeOrMoreDevices(),
              db.countAccountsWithMobileDevice()
            ])
          }).then(function (results) {
            t.ok(results[0].count === lastResults[0].count, '2+ device account count was not incremented')
            t.ok(results[1].count === lastResults[1].count, '3+ device account count was not incremented')
            t.ok(results[2].count === lastResults[2].count + 1, 'mobile device account count was incremented by one')
            return deleteAccount(uid)
          }).then(function () {
            t.end()
          }, function (err) {
            t.fail('no errors should have occurred')
            t.end()
          })
        }
      )

      test(
        'teardown',
        function (t) {
          return db.close()
        }
      )

      function createAccount (uid, time, emailVerified) {
        var email = ('' + Math.random()).substr(2) + '@foo.com'
        return db.createAccount(uid, {
          email: email,
          normalizedEmail: email.toLowerCase(),
          emailCode: zeroBuffer16,
          emailVerified: emailVerified,
          verifierVersion: 1,
          verifyHash: zeroBuffer32,
          authSalt: zeroBuffer32,
          kA: zeroBuffer32,
          wrapWrapKb: zeroBuffer32,
          verifierSetAt: time,
          createdAt: time,
          locale: 'en_US'
        })
      }

      function deleteAccount(uid) {
        return db.deleteAccount(uid)
      }

      function createSessionToken (uid, uaDeviceType) {
        return db.createSessionToken(hex(32), {
          data: hex(32),
          uid: uid,
          createdAt: Date.now(),
          uaBrowser: 'foo',
          uaBrowserVersion: 'bar',
          uaOS: 'baz',
          uaOSVersion: 'qux',
          uaDeviceType: uaDeviceType
        })
      }

      function hex (length) {
        return Buffer(crypto.randomBytes(length).toString('hex'), 'hex')
      }
    }
  )
