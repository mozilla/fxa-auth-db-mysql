/* Any copyright is dedicated to the Public Domain.
 * http://creativecommons.org/publicdomain/zero/1.0/ */

require('ass')
var dbServer = require('../../lib/server')
var dbTests = require('../server').dbTests
var log = { trace: console.log, error: console.log, stat: console.log, info: console.log }
var DB = require('../../lib/db/mysql')(log, dbServer.errors)
var config = require('../../config')

dbTests(config, DB)
