
const assert = require('insist')
var constants = require('../../lib/constants')
describe('constants', () => {
  it(
    'constants exports DATABASE_NAME fxa',
    () => {
      constants.DATABASE_NAME = 'test'
      assert.equal(constants.DATABASE_NAME, 'fxa')
    })
})
