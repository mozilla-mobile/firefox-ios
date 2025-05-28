#!/bin/bash

# Usage: ./find_tests_with_flag.sh defaultEnabledOn tab-tray-ui-experiments

JSON_ARG="$1"
FEATURE_ARG="$2"
ROOT_DIR="./firefox-ios-tests/Tests/XCUITests"
PATTERN="addLaunchArgument(jsonFileName: \\\"$JSON_ARG\\\", featureName: \\\"$FEATURE_ARG\\\")"

grep -rl "$JSON_ARG" "$ROOT_DIR" | while read -r file; do
    className=""
    inFunc=0
    funcName=""
    funcBody=""

    while IFS= read -r line; do
        # Capture class name
        if echo "$line" | grep -qE '^class [A-Za-z0-9_]+:'; then
            className=$(echo "$line" | sed -nE 's/^class ([A-Za-z0-9_]+):.*/\1/p')
        fi

        # Start of a test function
        if echo "$line" | grep -qE '^\s*func test[A-Za-z0-9_]*'; then
            inFunc=1
            funcName=$(echo "$line" | grep -oE 'test[A-Za-z0-9_]*')
            funcBody="$line"
            continue
        fi


        # End of function block
        if [ $inFunc -eq 1 ] && echo "$line" | grep -qE '^\s*\}'; then
            funcBody="$funcBody"$'\n'"$line"
            if echo "$funcBody" | grep -q "$PATTERN"; then
                echo "XCUITests/$className/$funcName"
            fi
            inFunc=0
            funcBody=""
            funcName=""
            continue
        fi

        # Collect body lines
        if [ $inFunc -eq 1 ]; then
            funcBody="$funcBody"$'\n'"$line"
        fi
    done < "$file"
done
