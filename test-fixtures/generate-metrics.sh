#! /usr/bin/env bash
# set -x # For debug
set -e

BUILD_LOG_FILE="$1"
METRICS_FILE="${2}/metrics.txt"
TYPE_LOG_FILE="$3"
THREESHOLD_UNIT_TEST=110
THREESHOLD_XCUITEST=850

# Remove if found
rm -rf "$METRICS_FILE"

# Count warnings
#echo Counting warnings
WARNING_COUNT=`egrep '^(\/.+:[0-9+:[0-9]+:.|warning:|ld: warning:|<unknown>:0: warning:|fatal|===)' "$BUILD_LOG_FILE" | uniq | wc -l`
#echo "warnings" $WARNING_COUNT >> "$METRICS_FILE"

if  [ $3 == "unit-test" ]; then
    if [ $WARNING_COUNT -ge $THREESHOLD_UNIT_TEST ]; then
        echo "Number of warnings is $WARNING_COUNT. This is greater than $THREESHOLD_UNIT_TEST"
    else
        echo "Number of warnings is $WARNING_COUNT. This is lower than $THREESHOLD_UNIT_TEST"
    fi
else
    if [ $WARNING_COUNT \> $THREESHOLD_XCUITEST ]; then
        echo "Number of warnings is $WARNING_COUNT. This is greater than $THREESHOLD_XCUITEST"
    else
        echo "Number of warnings is $WARNING_COUNT. This is lower than $THREESHOLD_XCUITEST"
    exit 1
    fi
fi
