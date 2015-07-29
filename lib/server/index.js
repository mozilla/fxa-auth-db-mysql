/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var restify = require('restify')
var bufferize = require('./bufferize')
var version = require('../../package.json').version
var errors = require('./error')

function createServer(db) {

  function reply(fn) {
    return function (req, res, next) {
      fn.call(db, req.params.id, req.body)
        .then(
          function (result) {
            api.emit(
              'success',
              {
                code: 200,
                route: req.route.name,
                method: req.method,
                path: req.url,
                t: Date.now() - req.time()
              }
            )
            if (Array.isArray(result)) {
              res.send(result.map(bufferize.unbuffer))
            }
            else {
              res.send(bufferize.unbuffer(result || {}))
            }
          },
          handleError.bind(null, req, res)
        )
        .done(next, next)
    }
  }

  function handleError (req, res, err) {
    if (typeof err !== 'object') {
      err = { message: err || 'none' }
    }

    var statusCode = err.code || 500

    api.emit(
      'failure',
      {
        code: statusCode,
        route: req.route ? req.route.name : 'unknown',
        method: req.method,
        path: req.url,
        err: err,
        t: Date.now() - req.time(),
      }
    )

    res.send(statusCode, {
      message: err.message,
      errno: err.errno,
      error: err.error,
      code: err.code
    })
  }

  var api = restify.createServer()
  api.use(restify.bodyParser())
  api.use(bufferize.bufferizeRequest)

  api.get('/account/:id', reply(db.account))
  api.del('/account/:id', reply(db.deleteAccount))
  api.put('/account/:id', reply(db.createAccount))
  api.get('/account/:id/devices', reply(db.accountDevices))
  api.post('/account/:id/checkPassword', reply(db.checkPassword))
  api.post('/account/:id/reset', reply(db.resetAccount))
  api.post('/account/:id/verifyEmail', reply(db.verifyEmail))
  api.post('/account/:id/locale', reply(db.updateLocale))
  api.post('/account/:id/lock', reply(db.lockAccount))
  api.post('/account/:id/unlock', reply(db.unlockAccount))
  api.get('/account/:id/unlockCode', reply(db.unlockCode))

  api.get('/sessionToken/:id', reply(db.sessionToken))
  api.del('/sessionToken/:id', reply(db.deleteSessionToken))
  api.put('/sessionToken/:id', reply(db.createSessionToken))

  api.get('/keyFetchToken/:id', reply(db.keyFetchToken))
  api.del('/keyFetchToken/:id', reply(db.deleteKeyFetchToken))
  api.put('/keyFetchToken/:id', reply(db.createKeyFetchToken))

  api.get('/accountResetToken/:id', reply(db.accountResetToken))
  api.del('/accountResetToken/:id', reply(db.deleteAccountResetToken))
  api.put('/accountResetToken/:id', reply(db.createAccountResetToken))

  api.get('/passwordChangeToken/:id', reply(db.passwordChangeToken))
  api.del('/passwordChangeToken/:id', reply(db.deletePasswordChangeToken))
  api.put('/passwordChangeToken/:id', reply(db.createPasswordChangeToken))

  api.get('/passwordForgotToken/:id', reply(db.passwordForgotToken))
  api.del('/passwordForgotToken/:id', reply(db.deletePasswordForgotToken))
  api.put('/passwordForgotToken/:id', reply(db.createPasswordForgotToken))
  api.post('/passwordForgotToken/:id/update', reply(db.updatePasswordForgotToken))
  api.post('/passwordForgotToken/:id/verified', reply(db.forgotPasswordVerified))

  api.get('/emailRecord/:id', reply(db.emailRecord))
  api.head('/emailRecord/:id', reply(db.accountExists))

  api.get('/__heartbeat__', reply(db.ping))

  api.get(
    '/',
    function (req, res, next) {
      res.send({ version: version })
      next()
    }
  )

  var memInterval = setInterval(function() {
    api.emit('mem', process.memoryUsage())
  }, 15000)
  memInterval.unref()

  api.on('NotFound', function (req, res) {
    handleError(req, res, errors.notFound())
  })

  return api
}

module.exports = {
  createServer: createServer,
  errors: errors
}
