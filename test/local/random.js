/* Any copyright is dedicated to the Public Domain.
 * http://creativecommons.org/publicdomain/zero/1.0/ */

'use strict'

const assert = require('insist')

const base32 = require('../../lib/db/random')

describe('random', () => {
  it('should generate random code', () => {
    return base32(10)
      .then(code => {
        assert.equal(code.length, 10)
        assert.equal(code.indexOf('I'), -1, 'should not contain I')
        assert.equal(code.indexOf('L'), -1, 'should not contain L')
        assert.equal(code.indexOf('O'), -1, 'should not contain O')
        assert.equal(code.indexOf('U'), -1, 'should not contain U')
      })
  })
})
