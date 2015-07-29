/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

module.exports = function (grunt) {
  'use strict'

  grunt.config('eslint', {
    options: {
      eslintrc: '.eslintrc'
    },
    files: [
      '{,grunttasks/,lib/,lib/db/,lib/server/,scripts/,test/,test/db/,test/local/,test/server/}*.js'
    ]
  })

  // Let's make a sneaky alias for ESLint and call it `jshint`.
  grunt.registerTask('jshint', ['eslint'])
}
