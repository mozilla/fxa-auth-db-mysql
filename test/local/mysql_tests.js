/* Any copyright is dedicated to the Public Domain.
 * http://creativecommons.org/publicdomain/zero/1.0/ */

'use strict'

const assert = require('insist')
const dbServer = require('../../fxa-auth-db-server')
const log = require('../lib/log')
const DB = require('../../lib/db/mysql')(log, dbServer.errors)
const config = require('../../config')
const P = require('../../lib/promise')
const crypto = require('crypto')

const zeroBuffer16 = Buffer.from('00000000000000000000000000000000', 'hex')
const zeroBuffer32 = Buffer.from('0000000000000000000000000000000000000000000000000000000000000000', 'hex')
const now = Date.now()

describe('MySQL', () => {

  let db
  before(() => {
    return DB.connect(config).then(db_ => {
      db = db_
      return db.ping()
    })
  })

  it(
    'a select on an unknown table should result in an error',
    () => {
      var query = 'SELECT mumble as id FROM mumble.mumble WHERE mumble = ?'
      var param = 'mumble'
      return db.read(query, param)
        .then(
          function(result) {
            assert(false, 'Should not have arrived here for an invalid select')
          },
          function(err) {
            assert(err, 'we have an error')
            assert.equal(err.code, 500)
            assert.equal(err.errno, 1146)
            assert.equal(err.error, 'Internal Server Error')
            assert.equal(err.message, 'ER_NO_SUCH_TABLE')
          }
        )
    }
  )

  it(
    'an update to an unknown table should result in an error',
    () => {
      var query = 'UPDATE mumble.mumble SET mumble = ?'
      var param = 'mumble'

      db.write(query, param)
        .then(
          function(result) {
            assert(false, 'Should not have arrived here for an invalid update')
          },
          function(err) {
            assert(err, 'we have an error')
            assert.equal(err.code, 500)
            assert.equal(err.errno, 1146)
            assert.equal(err.error, 'Internal Server Error')
            assert.equal(err.message, 'ER_NO_SUCH_TABLE')
          }
        )
    }
  )

  it(
    'an transaction to update an unknown table should result in an error',
    () => {
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

      return db.transaction(
        function (connection) {
          return query(connection, sql, param)
        })
        .then(
          function(result) {
            assert(false, 'Should not have arrived here for an invalid update')
          },
          function(err) {
            assert(err, 'we have an error')
            assert.equal(err.code, 500)
            assert.equal(err.errno, 1146)
            assert.equal(err.error, 'Internal Server Error')
            assert.equal(err.message, 'ER_NO_SUCH_TABLE')
          }
        )
    }
  )

  it(
    'retryable does retry when the errno is matched',
    () => {
      var query = 'UPDATE mumble.mumble SET mumble = ?'
      var param = 'mumble'

      var callCount = 0

      var writer = function() {
        ++callCount
        return db.write(query, param)
          .then(
            function(result) {
              assert(false, 'this query should never succeed!')
            },
            function(err) {
              assert.equal(err.code, 500)
              assert.equal(err.errno, 1146)
              assert.equal(err.error, 'Internal Server Error')
              assert.equal(err.message, 'ER_NO_SUCH_TABLE')
              throw err
            }
          )
      }

      return db.retryable_(writer, [ 1146 ])
        .then(
          function(result) {
            assert(false, 'This should never happen, even with a retry ' + callCount)
          },
          function(err) {
            assert.equal(callCount, 2, 'the function was retried')
          }
        )
    }
  )

  it(
    'check that an error in a stored procedure (with transaction) is propagated back',
    () => {
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

      return db.write(dropProcedure, [])
        .then(function() {
          return db.write(ensureProcedure, [])
        })
        .then(function() {
          // monkey patch the DB so that we're doing what the other writes to stored procedures are doing
          db.testStoredProcedure = function() {
            var callProcedure = 'CALL testStoredProcedure()'
            return this.write(callProcedure)
          }
          return db.testStoredProcedure()
        })
        .then(function() {
          assert(false, 'The call to the stored prodcedure should have failed')
        }, function(err) {
          assert.equal(err.code, 500, 'error code is correct')
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
          assert(matchedError, 'error message and errno are correct')
        })
    }
  )

  it(
    'readMultiple with valid queries',
    () => {
      return db.readMultiple([
        {
          sql: 'SELECT * FROM accounts LIMIT ?',
          params: 1
        },
        {
          sql: 'SELECT COUNT(*) AS count FROM accounts WHERE createdAt < ? AND normalizedEmail LIKE ?',
          params: [ Date.now(), '%@mozilla.com' ]
        }
      ])
      .then(
        function(results) {
          assert(Array.isArray(results), 'results array was returned')
          assert.equal(results.length, 2, 'results array contained two items')
          assert(Array.isArray(results[0]), 'first result was an array')
          assert(results[0].length <= 1, 'first result contained zero or one items')
          assert(Array.isArray(results[1]), 'second result was an array')
          assert.equal(results[1].length, 1, 'second result contained one item')
          assert.equal(typeof results[1][0], 'object', 'second result item was object')
          assert.equal(Object.keys(results[1][0]).length, 1, 'second result item had one property')
          assert(results[1][0].count >= 0, 'count property was non-negative number')
        }
      )
    }
  )

  it(
    'readMultiple with final query',
    () => {
      return db.readMultiple([
        { sql: 'SELECT * FROM accounts LIMIT 1' },
        { sql: 'SELECT * FROM accounts LIMIT 1' }
      ], { sql: 'SELECT * FROM accounts LIMIT 1' })
      .then(
        function(results) {
          assert.equal(results.length, 2, 'results array contained two items')
        }
      )
    }
  )

  it(
    'readMultiple with error in query',
    () => {
      return db.readMultiple([
        { sql: 'SELECT nonsense FROM gibberish' },
        { sql: 'SELECT * FROM accounts LIMIT 1' }
      ], { sql: 'SELECT * FROM accounts LIMIT 1' })
      .then(
        function(results) {
          assert(false, 'should have failed')
        },
        function(err) {
        }
      )
    }
  )

  it(
    'readMultiple with error in final query',
    () => {
      return db.readMultiple([
        { sql: 'SELECT * FROM accounts LIMIT 1' },
        { sql: 'SELECT * FROM accounts LIMIT 1' }
      ], { sql: 'SELECT nonsense FROM gibberish' })
      .then(
        () => {
          assert(false, 'should have failed')
        },
        function(err) {
        }
      )
    }
  )

  it(
    '_connectionConfig returns a plausible config object',
    () => {
      return db._connectionConfig('MASTER')
        .then(
          function(config) {
            assert.equal(typeof config, 'object')
            // slightly opinionated
            assert.equal(config.protocol41, true, 'protocol41 is true')
            assert.equal(config.charsetNumber, 33, 'charsetNumber should be 33 (utf8)')
            assert.equal(config.multipleStatements, false, 'multipleStatements should normally be false')
          }
        )
    }
  )

  it(
    '_showVariables returns a plausible set of values',
    () => {
      return db._showVariables('MASTER')
        .then(
          function(vars) {
            assert.equal(typeof vars, 'object')
            // Not doing a hardcore enumeration (yet) (or utfmb4)
            assert.equal(vars['character_set_client'], 'utf8', 'character_set_connection is utf8')
            assert.equal(vars['character_set_connection'], 'utf8', 'character_set_client is utf8')
          }
        )
    }
  )

  it(
    'create account and read email record',
    () => {
      var uid = crypto.randomBytes(16)
      var account = {
        uid: uid,
        email: ('' + Math.random()).substr(2) + '@bar.com',
        emailCode: zeroBuffer16,
        emailVerified: false,
        verifierVersion: 1,
        verifyHash: zeroBuffer32,
        authSalt: zeroBuffer32,
        kA: zeroBuffer32,
        wrapWrapKb: zeroBuffer32,
        verifierSetAt: now,
        createdAt: now,
        locale : 'en_US',
      }
      account.normalizedEmail = account.email.toLowerCase()

      return db.createAccount(uid, account)
        .then(
          function(result) {
            assert.deepEqual(result, {}, 'Returned an empty object on account creation')
            return db.emailRecord(account.email)
          }
        )
        .then(
          function(result) {
            assert.equal(result.createdAt, account.createdAt, 'createdAt set')
            assert.equal(result.email, account.email, 'email set')
            assert.equal(result.emailVerified, 0, 'emailVerified set')
            assert.equal(result.normalizedEmail, account.normalizedEmail, 'normalizedEmail set')
            assert.equal(result.verifierSetAt, account.verifierSetAt, 'verifierSetAt set')
            assert.equal(result.verifierVersion, account.verifierVersion, 'verifierVersion set')
          }
        )
    }
  )

  after(() => db.close())

})
