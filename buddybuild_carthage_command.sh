#!/bin/bash

# This is needed for Leanplum. Our bootstrap.sh is not run on
# BuddyBuild and the carthage command that BuddyBuild runs is
# not compatible with Leanplum for some reason. (It seems to
# have a problem with the --toolchain argument).

carthage bootstrap --platform ios

