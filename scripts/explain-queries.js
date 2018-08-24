// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// Output SQL EXPLAIN statements for queries inside stored procedures.
//
// Usage:
//
//   node scripts/explain-queries FILE [PROCEDURE]
//
//   * FILE: Required. Path to the source file to explain in.
//   * PROCEDURE: Optional. Name of the stored procedure to explain in.
//
// Currently it only works on SELECT queries. If we find it adds value
// for those, it should be pretty straightforward to write some logic
// that transforms an INSERT, UPDATE or DELETE into a similar SELECT and
// constructs the EXPLAIN for that instead.
//
// Some assumptions are made about our SQL source:
//
//   * There are never multiple queries on a single line.
//   * `CREATE PROCEDURE` and its matching `END;` always start at column 1.
//   * Arguments to procedures are always named either `inXxx` or `xxxArg`.
//   * SQL comment delimiters never appear inside string literals.
//
// Non-conformance to those assumptions is not fatal. It just means we'll
// either fail to generate an EXPLAIN for the non-conforming queries or
// the generated EXPLAIN will not be valid.

/* eslint-disable indent, no-console */

'use strict'

const fs = require('fs')

const CREATE_PROCEDURE = /^CREATE PROCEDURE `?([A-Z]+_[0-9]+)/i
const END_PROCEDURE = /^END;$/i
const SELECT = /^\s*SELECT/i
const COMMENT = /--.+$/

const { argv } = process

switch (argv.length) {
  case 3:
  case 4:
    generateExplains(argv[2], argv[3]).forEach(explain => console.log(explain))
    break

  default:
    console.error('Usage: node scripts/explain-queries FILE [PROCEDURE]')
    process.exit(1)
}

function generateExplains (path, procedureName) {
  const src = fs.readFileSync(path, { encoding: 'utf8' })
  const selects = extractSelects(src, procedureName)
  return selects.map(select => `EXPLAIN ${replaceArgs(select)}`)
}

function extractSelects (src, procedureName) {
  let isProcedure = false, isSelect = false
  const lines = src.split('\n')
  return lines
    .reduce((selects, line) => {
      line = line.replace(COMMENT, '')
      if (isProcedure) {
        if (END_PROCEDURE.test(line)) {
          isProcedure = isSelect = false
        } else {
          if (isSelect) {
            selects[selects.length - 1] += ` ${line.trim()}`
          } else if (SELECT.test(line)) {
            selects.push(line.trim())
            isSelect = true
          }

          if (line.indexOf(';') !== -1) {
            isSelect = false
          }
        }
      } else if (procedureName) {
        const match = CREATE_PROCEDURE.exec(line)
        if (match && match.length === 2 && match[1] === procedureName) {
          isProcedure = true
        }
      } else {
        isProcedure = CREATE_PROCEDURE.test(line)
      }

      return selects
    }, [])
    .map(select => purgeUnbalancedParentheses(select))
}

function purgeUnbalancedParentheses (select) {
  const openingCount = select.split('(').length
  const closingCount = select.split(')').length

  if (openingCount < closingCount) {
    for (let i = 0; i < closingCount - openingCount; ++i) {
      const index = select.lastIndexOf(')')
      select = select.substr(0, index) + select.substr(index + 1)
    }
  } else if (openingCount > closingCount) {
    for (let i = 0; i < openingCount - closingCount; ++i) {
      const index = select.indexOf('(')
      select = select.substr(0, index) + select.substr(index + 1)
    }
  }

  return select
}

function replaceArgs (select) {
  return select
    .replace(/([ \(]?)`?in((?:[A-Z][A-Za-z]+)+)`?/g, replaceArg)
    .replace(/([ \(]?)`?([a-z]+(?:[A-Z][A-Za-z]+)*Arg)`?/g, replaceArg)
}

function replaceArg (match, delimiter, arg) {
  return `${delimiter}0`
}
