#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/
#

#
# Installs the SwiftLint version pinned in .swiftlint-version and prints the
# path to the binary on stdout. Everything else goes to stderr, so callers can
# do:
#
#   SWIFTLINT=$(scripts/install-swiftlint.sh)
#   "$SWIFTLINT" lint
#
# Usage:
#   scripts/install-swiftlint.sh              Install if missing, print path.
#   scripts/install-swiftlint.sh --path-only  Print path if already installed,
#                                             exit 1 without downloading. Used
#                                             by the Xcode build phases so a
#                                             build never blocks on a download.
#

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION_FILE="$REPO_ROOT/.swiftlint-version"

if [ ! -f "$VERSION_FILE" ]; then
    echo "error: $VERSION_FILE not found" >&2
    exit 1
fi

# Reads a `key=value` field from the version file, ignoring comments.
read_field() {
    sed -n "s/^$1[[:space:]]*=[[:space:]]*\([^[:space:]#]*\).*/\1/p" "$VERSION_FILE" | head -1
}

VERSION=$(read_field version)
EXPECTED_SHA=$(read_field sha256)

if [ -z "$VERSION" ] || [ -z "$EXPECTED_SHA" ]; then
    echo "error: $VERSION_FILE must define both 'version' and 'sha256'" >&2
    exit 1
fi

INSTALL_DIR="$REPO_ROOT/.tools/swiftlint/$VERSION"
BIN="$INSTALL_DIR/swiftlint"

if [ "${1:-}" = "--path-only" ]; then
    if [ -x "$BIN" ]; then
        echo "$BIN"
        exit 0
    fi
    exit 1
fi

if [ -x "$BIN" ]; then
    echo "SwiftLint $VERSION already installed." >&2
    echo "$BIN"
    exit 0
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Installing SwiftLint $VERSION." >&2
curl --proto '=https' --tlsv1.2 -sSfL \
    -o "$TMP_DIR/portable_swiftlint.zip" \
    "https://github.com/realm/SwiftLint/releases/download/$VERSION/portable_swiftlint.zip" >&2

ACTUAL_SHA=$(shasum -a 256 "$TMP_DIR/portable_swiftlint.zip" | cut -d ' ' -f 1)
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
    echo "error: checksum mismatch for SwiftLint $VERSION" >&2
    echo "  expected: $EXPECTED_SHA" >&2
    echo "  actual:   $ACTUAL_SHA" >&2
    echo "Refusing to install. Update .swiftlint-version if the pin is stale." >&2
    exit 1
fi

unzip -q "$TMP_DIR/portable_swiftlint.zip" -d "$TMP_DIR/unpacked"
mkdir -p "$INSTALL_DIR"
cp "$TMP_DIR/unpacked/LICENSE" "$INSTALL_DIR/LICENSE"

# Move into place under a temporary name first so that concurrent installs
# (for example a build phase racing the pre-push hook) can't observe a
# partially written binary.
chmod +x "$TMP_DIR/unpacked/swiftlint"
mv "$TMP_DIR/unpacked/swiftlint" "$INSTALL_DIR/swiftlint.$$"
mv "$INSTALL_DIR/swiftlint.$$" "$BIN"

echo "$BIN"
