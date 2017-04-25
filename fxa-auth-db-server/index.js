/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var restify = require('restify')
var safeJsonFormatter = require('restify-safe-json-formatter')
var bufferize = require('./lib/bufferize')
var version = require('./package.json').version
var errors = require('./lib/error')

function createServer(db) {

  var implementation = db.constructor.name || '__anonymousconstructor__'

  function reply(fn) {
    return function (req, res, next) {
      fn(req.params, req.body, req.query)
        .then(
          handleSuccess.bind(null, req, res),
          handleError.bind(null, req, res)
        )
        .then(next, next)
    }
  }

  function withIdAndBody(fn) {
    return reply(function (params, body, query) {
      return fn.call(db, params.id, body)
    })
  }

  function withBodyAndQuery(fn) {
    return reply(function (params, body, query) {
      return fn.call(db, body, query)
    })
  }

  function withParams(fn) {
    return reply(function (params, body, query) {
      return fn.call(db, params)
    })
  }

  var api = restify.createServer({
    formatters: {
      'application/json; q=0.9': safeJsonFormatter
    }
  })
  api.use(restify.bodyParser())
  api.use(restify.queryParser())
  api.use(bufferize.bufferizeRequest.bind(null, new Set([
    // These are all the different params that we handle as binary Buffers,
    // but are passed into the API as hex strings.
    'authKey',
    'authSalt',
    'data',
    'deviceId',
    'emailCode',
    'id',
    'kA',
    'keyBundle',
    'passCode',
    'sessionTokenId',
    'tokenId',
    'tokenVerificationId',
    'uid',
    'verifyHash',
    'wrapWrapKb'
  ])))

  api.get('/account/:id', withIdAndBody(db.account))
  api.del('/account/:id', withIdAndBody(db.deleteAccount))
  api.put('/account/:id', withIdAndBody(db.createAccount))
  api.get('/account/:id/devices', withIdAndBody(db.accountDevices))
  api.post('/account/:id/checkPassword', withIdAndBody(db.checkPassword))
  api.post('/account/:id/reset', withIdAndBody(db.resetAccount))
  api.post('/account/:id/verifyEmail/:emailCode',
    op(function (req) {
      return db.verifyEmail(req.params.id, req.params.emailCode)
    })
  )
  api.post('/account/:id/locale', withIdAndBody(db.updateLocale))
  api.get('/account/:id/sessions', withIdAndBody(db.sessions))

  api.get('/account/:id/emails', withIdAndBody(db.accountEmails))
  api.post('/account/:id/emails', withIdAndBody(db.createEmail))
  api.del('/account/:id/emails/:email',
    op(function (req) {
      return db.deleteEmail(req.params.id, req.params.email)
    })
  )
  api.get('/account/emails/:email',
    op(function (req) {
      return db.getSecondaryEmail(Buffer(req.params.email, 'hex'))
    })
  )

  api.get('/sessionToken/:id', withIdAndBody(db.sessionToken))
  api.del('/sessionToken/:id', withIdAndBody(db.deleteSessionToken))
  api.put('/sessionToken/:id', withIdAndBody(db.createSessionToken))
  api.post('/sessionToken/:id/update', withIdAndBody(db.updateSessionToken))
  api.get('/sessionToken/:id/device', withIdAndBody(db.sessionWithDevice))

  api.get('/keyFetchToken/:id', withIdAndBody(db.keyFetchToken))
  api.del('/keyFetchToken/:id', withIdAndBody(db.deleteKeyFetchToken))
  api.put('/keyFetchToken/:id', withIdAndBody(db.createKeyFetchToken))

  api.get('/sessionToken/:id/verified', withIdAndBody(db.sessionTokenWithVerificationStatus))
  api.get('/keyFetchToken/:id/verified', withIdAndBody(db.keyFetchTokenWithVerificationStatus))
  api.post('/tokens/:id/verify', withIdAndBody(db.verifyTokens))

  api.get('/accountResetToken/:id', withIdAndBody(db.accountResetToken))
  api.del('/accountResetToken/:id', withIdAndBody(db.deleteAccountResetToken))

  api.get('/passwordChangeToken/:id', withIdAndBody(db.passwordChangeToken))
  api.del('/passwordChangeToken/:id', withIdAndBody(db.deletePasswordChangeToken))
  api.put('/passwordChangeToken/:id', withIdAndBody(db.createPasswordChangeToken))

  api.get('/passwordForgotToken/:id', withIdAndBody(db.passwordForgotToken))
  api.del('/passwordForgotToken/:id', withIdAndBody(db.deletePasswordForgotToken))
  api.put('/passwordForgotToken/:id', withIdAndBody(db.createPasswordForgotToken))
  api.post('/passwordForgotToken/:id/update', withIdAndBody(db.updatePasswordForgotToken))
  api.post('/passwordForgotToken/:id/verified', withIdAndBody(db.forgotPasswordVerified))

  api.get('/verificationReminders', withBodyAndQuery(db.fetchReminders))
  api.post('/verificationReminders', withBodyAndQuery(db.createVerificationReminder))
  api.del('/verificationReminders', withBodyAndQuery(db.deleteReminder))

  api.get('/securityEvents/:id/ip/:ipAddr', withParams(db.securityEvents))
  api.post('/securityEvents', withBodyAndQuery(db.createSecurityEvent))

  api.get('/emailBounces/:id', withIdAndBody(db.fetchEmailBounces))
  api.post('/emailBounces', withBodyAndQuery(db.createEmailBounce))

  api.get('/emailRecord/:id', withIdAndBody(db.emailRecord))
  api.head('/emailRecord/:id', withIdAndBody(db.accountExists))

  api.get('/__heartbeat__', withIdAndBody(db.ping))

  function op(fn) {
    return function (req, res, next) {
      fn.call(null, req)
        .then(
          handleSuccess.bind(null, req, res),
          handleError.bind(null, req, res)
        )
        .then(next, next)
    }
  }

  api.put(
    '/account/:uid/device/:deviceId',
    op(function (req) {
      return db.createDevice(req.params.uid, req.params.deviceId, req.body)
    })
  )
  api.post(
    '/account/:uid/device/:deviceId/update',
    op(function (req) {
      return db.updateDevice(req.params.uid, req.params.deviceId, req.body)
    })
  )
  api.del(
    '/account/:uid/device/:deviceId',
    op(function (req) {
      return db.deleteDevice(req.params.uid, req.params.deviceId)
    })
  )


  api.get(
    '/account/:uid/tokens/:tokenVerificationId/device',
    op(function (req) {
      return db.deviceFromTokenVerificationId(req.params.uid, req.params.tokenVerificationId)
    })
  )


  api.put(
    '/account/:uid/unblock/:code',
    op(function (req) {
      return db.createUnblockCode(req.params.uid, req.params.code)
    })
  )

  api.del(
    '/account/:uid/unblock/:code',
    op(function (req) {
      return db.consumeUnblockCode(req.params.uid, req.params.code)
    })
  )

  api.get(
    '/',
    function (req, res, next) {
      res.send({ version: version, implementation: implementation })
      next()
    }
  )

  api.get(
    '/__version__',
    function (req, res, next) {
      res.send({ version: version, implementation: implementation })
      next()
    }
  )

  function handleSuccess(req, res, result) {
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
