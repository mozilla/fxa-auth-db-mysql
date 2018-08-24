#!/bin/sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

echo 'Creating 10,000 dummy accounts, hang tight...'
#node scripts/populate-session-tokens 10000 2>&1 > /dev/null

SRC="lib/db/mysql.js"
ACTIVE_PROCEDURES=`grep 'CALL ' "$SRC" | awk -F 'CALL +' '{print $2}' | cut -d '(' -f 1`

for PROCEDURE in $ACTIVE_PROCEDURES
do
  FILE=`git grep "$PROCEDURE" | grep 'CREATE PROCEDURE' | cut -d ':' -f 1 | sed '/^$/d'`
  EXPLAINS=`node scripts/explain-queries "$FILE" "$PROCEDURE"`

  if [ "$EXPLAINS" = "" ]
  then
    continue
  fi

  echo "$EXPLAINS" | while read -r EXPLAIN
  do
    EXPLAIN_RESULT=`mysql -D fxa -u root -e "$EXPLAIN" 2>/dev/null`
    EXPLAIN_DATA=`echo "$EXPLAIN_RESULT" | grep -v 'id\tselect_type'`

    TYPE=`echo "$EXPLAIN_DATA" | cut -f 5`
    EXTRA=`echo "$EXPLAIN_DATA" | cut -f 12`

    if [ "`echo \"$TYPE\" | grep ALL`" != "" ]
    then
      echo "Warning: full table scan detected in $PROCEDURE!"
      WARNING=1
    fi

    if [ "`echo \"$TYPE\" | grep INDEX`" != "" ]
    then
      echo "Warning: full index scan detected in $PROCEDURE!"
      WARNING=1
    fi

    if [ "`echo \"$EXTRA\" | grep filesort`" != "" ]
    then
      echo "Warning: filesort detected in $PROCEDURE!"
      WARNING=1
    fi

    if [ "`echo \"$EXTRA\" | grep temporary`" != "" ]
    then
      echo "Warning: temporary table detected in $PROCEDURE!"
      WARNING=1
    fi

    if [ "$WARNING" = "1" ]
    then
      echo "$EXPLAIN"
      echo "$EXPLAIN_RESULT"
      echo ""
    fi
  done
done
