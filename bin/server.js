/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var config = require('../config')
var dbServer = require('../fxa-auth-db-server')
var error = dbServer.errors
var logger = require('../lib/logging')('bin.server')
var DB = require('../lib/db/mysql')(logger, error)
var notifier = require('../lib/notifier.js')(logger, config)

function shutdown() {
  process.nextTick(process.exit)
}

function logCharsetInfo(db, poolName) {
  // Record some information about mysql connection configuration and
  // charset at startup.
  db._showVariables(poolName)
    .then(
      function(variables) {
        logger.info([ 'variables', poolName ].join('.'), variables)
      }
    )
    .then(
      function() { 
        return db._connectionConfig(poolName)
      }
    )
    .then(
      function(config) {
        logger.info([ 'connectionConfig', poolName ].join('.'), config)
      }
    ).catch(
      function(err) {
        logger.error('error', { error: err })
      }
    )
}

DB.connect(config)
  .done(function (db) {
    // Serve the HTTP API.
    var server = dbServer.createServer(db)
    server.listen(config.port, config.hostname, function() {
      logger.info('start', { port : config.port })
    })
    server.on('error', function (err) {
      logger.error('start', { message: err.message })
    })
    server.on('success', function (d) {
      logger.info('summary', d)
    })
    server.on('failure', function (err) {
      if (err.statusCode >= 500) {
        logger.error('summary', err)
      }
      else {
        logger.warn('summary', err)
      }
    })
    server.on('mem', function (stats) {
      logger.info('mem', stats)
    })

    // Log connection config and charset info 
    logCharsetInfo(db, 'MASTER')
    logCharsetInfo(db, 'SLAVE')

    // Publish notifications via simple background loop.
    if (config.notifications.publishUrl) {
      var publish = function () {
        // Randomize sleep time to de-synchronize between webheads.
        var sleepTime = config.notifications.pollIntervalSeconds * 1000
        sleepTime = sleepTime / 2 + Math.floor(Math.random() * sleepTime)
        db.processUnpublishedEvents(function (events) {
          if (events.length > 0) {
            // If there were events, loop again immediately.
            // We only go to sleep there was nothing to publish.
            sleepTime = 0
            return notifier.publish(events)
          }
        }).finally(function () {
          setTimeout(publish, sleepTime).unref()
        })
      }
      publish()
    }
  })
