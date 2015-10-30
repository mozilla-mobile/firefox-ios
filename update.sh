#!/usr/bin/env sh
if which carthage >/dev/null; then
	carthage update --no-use-binaries --no-build
else
	echo "\"carthage\" not found. please install with the following command:"
	echo "\t brew update && brew install carthage"
fi
