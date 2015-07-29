/* Any copyright is dedicated to the Public Domain.
 * http://creativecommons.org/publicdomain/zero/1.0/ */

require('ass')
var dbServer = require('../../lib/server')
var serverTests = require('../server')
var config = require('../../config')
var noop = function () {}
var log = { trace: noop, error: noop, stat: noop, info: noop }
var DB = require('../../lib/db/mysql')(log, dbServer.errors)
var P = require('bluebird')

var server

// defer to allow ass code coverage results to complete processing
if (process.env.ASS_CODE_COVERAGE) {
  process.on('SIGINT', function() {
    process.nextTick(process.exit)
  })
}

var db

DB.connect(config)
  .then(function (newDb) {
    db = newDb
    server = dbServer.createServer(db)
    var d = P.defer()
    server.listen(config.port, config.hostname, function() {
      d.resolve(server)
    })
    return d.promise
  })
  .then(function(server) {
    return serverTests.remote(config, server)
  })
  .then(function() {
    server.close()
    db.close()
  })
