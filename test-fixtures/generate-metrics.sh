#! /usr/bin/env bash
# set -x # For debug
set -e

BUILD_LOG_FILE="$1"
TYPE_LOG_FILE="$2"
THREESHOLD_UNIT_TEST=250
THREESHOLD_XCUITEST=440


WARNING_COUNT=`egrep '^(\/.+:[0-9+:[0-9]+:.|warning:|ld: warning:|<unknown>:0: warning:|fatal|===)' "$BUILD_LOG_FILE" | uniq | wc -l`

if  [ $2 == "unit-test" ]; then
    if [ $WARNING_COUNT -ge $THREESHOLD_UNIT_TEST ]; then
        echo "Number of warnings is: $WARNING_COUNT. This is greater than unit-test threshold: $THREESHOLD_UNIT_TEST"
    else
        echo "Number of warnings is: $WARNING_COUNT. This is lower than unit-test threshold: $THREESHOLD_UNIT_TEST"
    fi
else
    if [ $WARNING_COUNT -ge $THREESHOLD_XCUITEST ]; then
        echo "Number of warnings is: $WARNING_COUNT. This is greater than build threshold: $THREESHOLD_XCUITEST"
    else
        echo "Number of warnings is: $WARNING_COUNT. This is lower than build threshold: $THREESHOLD_XCUITEST"
    fi
fi
