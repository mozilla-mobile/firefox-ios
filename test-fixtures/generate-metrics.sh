#! /usr/bin/env bash
# set -x # For debug
set -e

BUILD_LOG_FILE="$1"
TYPE_LOG_FILE="$2"
<<<<<<< HEAD
THRESHOLD_UNIT_TEST=77
THRESHOLD_XCUITEST=77
=======
THRESHOLD_UNIT_TEST=47
THRESHOLD_XCUITEST=47
>>>>>>> c8a7c7d1a (Add FXIOS-7991 [v122] Add custom targeting attribute for review checker being enabled for user (#17824))

WARNING_COUNT=$(grep -E -v "SourcePackages/checkouts" "$BUILD_LOG_FILE" | grep -E "(^|:)[0-9]+:[0-9]+:|warning:|ld: warning:|<unknown>:0: warning:|fatal|===" | uniq | wc -l)

if  [ $2 == "unit-test" ]; then
    if [ $WARNING_COUNT -ge $THRESHOLD_UNIT_TEST ]; then
        echo "Number of warnings is: $WARNING_COUNT. This is greater than unit-test threshold: $THRESHOLD_UNIT_TEST"
    else
        echo "Number of warnings is: $WARNING_COUNT. This is lower than unit-test threshold: $THRESHOLD_UNIT_TEST"
    fi
else
    if [ $WARNING_COUNT -ge $THRESHOLD_XCUITEST ]; then
        echo "Number of warnings is: $WARNING_COUNT. This is greater than build threshold: $THRESHOLD_XCUITEST"
    else
        echo "Number of warnings is: $WARNING_COUNT. This is lower than build threshold: $THRESHOLD_XCUITEST"
    fi
fi
