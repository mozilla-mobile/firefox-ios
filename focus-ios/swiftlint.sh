#!/bin/bash

command -v swiftlint > /dev/null 2>&1 || { echo >&2 "Swiftlint is not installed"; exit 1; }

FILES=$( git diff --cached --diff-filter=d --name-only | grep ".swift$" )

if [ $? -eq 1 ]; then
	echo "No Staged Files For Linting"
	exit 0
fi

swiftlint autocorrect -- $FILES
swiftlint lint --strict $FILES
RESULT=$?
git add .
exit $RESULT




