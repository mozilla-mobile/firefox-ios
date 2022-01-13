#! /usr/bin/env bash
# set -x # For debug
set -e

BUILD_LOG_FILE="$1"
METRICS_FILE="${2}/metrics.txt"

# Remove if found
rm -rf "$METRICS_FILE"

# Count warnings
echo Counting warnings
WARNING_COUNT=`egrep '^(\/.+:[0-9+:[0-9]+:.|warning:|fatal|===)' "$BUILD_LOG_FILE" | uniq | wc -l`
echo "warnings" $WARNING_COUNT >> "$METRICS_FILE"

# Count errors
echo Counting errors
ERROR_COUNT=`egrep '^(/.+:[0-9+:[0-9]+:.(error):|fatal|===)' "$BUILD_LOG_FILE" | uniq | wc -l`
echo "errors" $ERROR_COUNT >> "$METRICS_FILE"

# Print results
cat "$METRICS_FILE"
