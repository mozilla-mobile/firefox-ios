#!/usr/bin/env sh

if which carthage >/dev/null; then
	carthage checkout --no-use-binaries

	# Checkout Breakpad from Google SVN and apply workaround for private headers/relative paths
	svn --non-interactive checkout http://google-breakpad.googlecode.com/svn/trunk ThirdParty/google-breakpad
	patch -N -p0 -d ThirdParty/google-breakpad <  breakpad_ios_fix.patch
else
	echo "\"carthage\" not found. please install with the following command:"
	echo "\t brew update && brew install carthage"
fi
