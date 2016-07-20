/* Any copyright is dedicated to the Public Domain.
 * http://creativecommons.org/publicdomain/zero/1.0/ */

var dbServer = require('../../fxa-auth-db-server')
var test = require('tap').test
var P = require('../../lib/promise')
var config = require('../../config')

config.logLevel = 'info'
config.statInterval = 100

var log = require('../../lib/logging')('test.local.log-stats')

// monkeypatch log.info to hook into db/mysql.js:statInterval
var dfd = P.defer()
log.info = function(msg, stats) {
  if (msg !== 'stats') {
    return
  }
  dfd.resolve(stats)
}

var DB = require('../../lib/db/mysql')(log, dbServer.errors)

DB.connect(config)
  .then(
    function (db) {

      test(
        'db/mysql logs stats periodically',
        function (t) {
          t.plan(4)
          return dfd.promise
            .then(
              function(stats) {
                t.type(stats, 'object', 'stats is an object')
                t.equal(stats.stat, 'mysql', 'stats.stat is mysql')
                t.equal(stats.errors, 0, 'have no errors')
                t.equal(stats.connections, 1, 'have one connection')
              },
              function(err) {
                t.fail('this should never happen ' + err)
              }
            )
        }
      )

      test(
        'teardown',
        function () {
          return db.close()
        }
      )
    }
  )
