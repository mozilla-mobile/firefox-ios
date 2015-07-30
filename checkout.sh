#!/usr/bin/env sh
carthage checkout --no-use-binaries

# Checkout Breakpad from Google SVN and apply workaround for private headers/relative paths
svn --non-interactive checkout http://google-breakpad.googlecode.com/svn/trunk ThirdParty/google-breakpad
patch -N -p0 -d ThirdParty/google-breakpad <  breakpad_ios_fix.patch
