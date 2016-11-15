/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var HEX_REGEX = /([0-9]|[a-f])/gim

function isHex (input) {
  return typeof input === 'string' && (input.match(HEX_REGEX) || []).length === input.length
}

function unbuffer(object) {
  var keys = Object.keys(object)
  for (var i = 0; i < keys.length; i++) {
    var x = object[keys[i]]
    if (Buffer.isBuffer(x)) {
      object[keys[i]] = x.toString('hex')
    }
  }
  return object
}

function bufferize(object, onlyTheseKeys) {
  var keys = Object.keys(object)
  if (onlyTheseKeys) {
    keys = keys.filter(key => onlyTheseKeys.has(key))
  }
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i]
    var value = object[key]
    if (value) {
      if (! isHex(value)) {
        throw new Error(key + ' must be a hex value.')
      }
      // make sure value is not null before calling new Buffer
      object[key] = new Buffer(value, 'hex')
    }
  }
  return object
}

function bufferizeRequest(keys, req, res, next) {
  if (req.body) { req.body = bufferize(req.body, keys) }
  if (req.params) { req.params = bufferize(req.params, keys) }
  next()
}

module.exports = {
  unbuffer: unbuffer,
  bufferize: bufferize,
  bufferizeRequest: bufferizeRequest
}
