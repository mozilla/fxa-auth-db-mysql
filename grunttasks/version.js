/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//
// A task to stamp a new version.
//
// * version is updated in package.json
// * git tag with version name is created.
// * git commit with updated package.json and CHANGELOG.md created.
//
// NOTE: This task will not push this commit for you.
//

module.exports = function (grunt) {
  'use strict'

  grunt.registerTask('version', [
    'bump-only:minor',
    'conventionalChangelog:release',
    'bump-commit'
  ])

  grunt.registerTask('version:patch', [
    'bump-only:patch',
    'conventionalChangelog:release',
    'bump-commit'
  ])
}
