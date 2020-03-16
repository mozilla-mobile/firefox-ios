#!/bin/bash
set -eux
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR/..

OLD_VERSION="${1}"
NEW_VERSION="${2}"

echo "--> Clean VersionBump"
cd Utils/VersionBump && swift build
cd $SCRIPT_DIR/..
echo "--> Bumping version to ${OLD_VERSION} ${NEW_VERSION}"
./Utils/VersionBump/.build/debug/VersionBump ${NEW_VERSION}