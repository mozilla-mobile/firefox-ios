#!/usr/bin/env bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/
#

#
# Verifies the Command Line Tools match the active Xcode, installs or upgrades
# fxios, then bootstraps both Firefox and Focus.
#

set -euo pipefail

major_minor() {
  local major minor
  IFS=. read -r major minor _ <<< "$1"
  echo "${major}.${minor:-0}"
}

if ! XCODE_VERSION=$(xcodebuild -version 2>/dev/null | awk 'NR == 1 { print $2 }') || [[ -z "${XCODE_VERSION}" ]]; then
  echo "error: Unable to determine the active Xcode version. Select one with 'sudo xcode-select -s /Applications/<Xcode>.app'." >&2
  exit 1
fi

CLT_VERSION=$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/^version:/ { print $2 }' || true)
if [[ -z "${CLT_VERSION}" ]]; then
  echo "error: Command Line Tools are not installed. Install the Command Line Tools for Xcode ${XCODE_VERSION} with 'xcode-select --install'." >&2
  exit 1
fi

if [[ "$(major_minor "${CLT_VERSION}")" != "$(major_minor "${XCODE_VERSION}")" ]]; then
  echo "error: Command Line Tools $(major_minor "${CLT_VERSION}") do not match the active Xcode ${XCODE_VERSION} ($(xcode-select -p))." >&2
  echo "Install the Command Line Tools for Xcode ${XCODE_VERSION} from Software Update or https://developer.apple.com/download/all/." >&2
  exit 1
fi

echo "Xcode ${XCODE_VERSION}, Command Line Tools ${CLT_VERSION}"

if ! command -v fxios >/dev/null 2>&1; then
  brew tap mozilla-mobile/fxios
  brew install fxios
else
  brew update
  brew upgrade fxios
fi

REPOSITORY_ROOT=$(git rev-parse --show-toplevel)
cd -- "${REPOSITORY_ROOT}"

fxios --version
fxios bootstrap --all
