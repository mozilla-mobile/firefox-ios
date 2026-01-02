#! /usr/bin/env bash
# set -x # For debug
set -e

BUILD_LOG_FILE="$1"
TYPE_LOG_FILE="$2"
THRESHOLD_UNIT_TEST=5
THRESHOLD_XCUITEST=5


WARNINGS=$(
  grep -E -v 'SourcePackages/checkouts' "$BUILD_LOG_FILE" \
  | grep -E '^[^ ]+:[0-9]+:[0-9]+: warning:' \
  | uniq
)

WARNING_COUNT=$(printf '%s\n' "$WARNINGS" | wc -l)

if [ $2 == "unit-test" ]; then
    if [ $WARNING_COUNT -gt $THRESHOLD_UNIT_TEST ]; then
        echo "Number of warnings is: $WARNING_COUNT. This is greater than unit-test threshold: $THRESHOLD_UNIT_TEST"
    else
        echo "Number of warnings is: $WARNING_COUNT. This is lower than unit-test threshold: $THRESHOLD_UNIT_TEST"
    fi
else
    if [ $WARNING_COUNT -gt $THRESHOLD_XCUITEST ]; then
        echo "Number of warnings is: $WARNING_COUNT. This is greater than build threshold: $THRESHOLD_XCUITEST"
    else
        echo "Number of warnings is: $WARNING_COUNT. This is lower than build threshold: $THRESHOLD_XCUITEST"
    fi
fi

# Print the actual warnings for debugging
if (( WARNING_COUNT > 0 )); then
  echo -e "\n--- Warnings ---"
  printf '%s\n' "$WARNINGS"
fi
