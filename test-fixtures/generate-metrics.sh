#! /usr/bin/env bash
# set -x # For debug
set -e

BUILD_LOG_FILE="$1"
METRICS_FILE="${2}/metrics.txt"
TYPE_LOG_FILE="$3"
THREESHOLD_UNIT_TEST=310
THREESHOLD_XCUITEST=850

# Remove if found
rm -rf "$METRICS_FILE"

# Count warnings
echo Counting warnings
WARNING_COUNT=`egrep '^(\/.+:[0-9+:[0-9]+:.|warning:|ld: warning:|<unknown>:0: warning:|fatal|===)' "$BUILD_LOG_FILE" | uniq | wc -l`
echo "warnings" $WARNING_COUNT >> "$METRICS_FILE"

if  [ $3 == "unit-test" ]; then
    if [ $WARNING_COUNT \> $THREESHOLD_UNIT_TEST ]; then
    echo "Error due to the increase number of warnings in unit test build"
    exit 1
    fi
else
    if [ $WARNING_COUNT \> $THREESHOLD_XCUITEST ]; then
    echo "Error due to the increase number of warnings in build"
    exit 1
    fi
fi

# Count errors
echo Counting errors
ERROR_COUNT=`egrep '^(/.+:[0-9+:[0-9]+:.(error):|fatal|===)' "$BUILD_LOG_FILE" | uniq | wc -l`
echo "errors" $ERROR_COUNT >> "$METRICS_FILE"

# Print results
cat "$METRICS_FILE"
