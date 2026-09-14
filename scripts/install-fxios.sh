#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/
#

#
# Installs the fxios-ctl version pinned in .fxios-version and prints the path
# to the binary on stdout. Everything else goes to stderr, so callers can do:
#
#   FXIOS=$(scripts/install-fxios.sh)
#   "$FXIOS" bootstrap
#
# The release tarball is downloaded straight from GitHub rather than through
# the mozilla-mobile/fxios Homebrew tap: tapping pulls in Homebrew's global
# state, where an unrelated broken formula in any other installed tap fails
# the whole `brew tap` and leaves fxios uninstallable.
#
# Usage:
#   scripts/install-fxios.sh              Install if missing, print path.
#   scripts/install-fxios.sh --path-only  Print path if already installed,
#                                         exit 1 without downloading.
#

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION_FILE="$REPO_ROOT/.fxios-version"

if [ ! -f "$VERSION_FILE" ]; then
    echo "error: $VERSION_FILE not found" >&2
    exit 1
fi

# Reads a `key=value` field from the version file, ignoring comments.
read_field() {
    sed -n "s/^$1[[:space:]]*=[[:space:]]*\([^[:space:]#]*\).*/\1/p" "$VERSION_FILE" | head -1
}

VERSION=$(read_field version)

case "$(uname -m)" in
    arm64)  ARCH=arm64 ;;
    x86_64) ARCH=x86_64 ;;
    *)
        echo "error: unsupported architecture $(uname -m)" >&2
        exit 1
        ;;
esac

EXPECTED_SHA=$(read_field "sha256_$ARCH")

if [ -z "$VERSION" ] || [ -z "$EXPECTED_SHA" ]; then
    echo "error: $VERSION_FILE must define both 'version' and 'sha256_$ARCH'" >&2
    exit 1
fi

INSTALL_DIR="$REPO_ROOT/.tools/fxios/$VERSION"
BIN="$INSTALL_DIR/fxios"

if [ "${1:-}" = "--path-only" ]; then
    if [ -x "$BIN" ]; then
        echo "$BIN"
        exit 0
    fi
    exit 1
fi

if [ -x "$BIN" ]; then
    echo "fxios $VERSION already installed." >&2
    echo "$BIN"
    exit 0
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL="fxios-v$VERSION-macos-$ARCH.tar.gz"

echo "Installing fxios $VERSION ($ARCH)." >&2
curl --proto '=https' --tlsv1.2 -sSfL \
    -o "$TMP_DIR/$TARBALL" \
    "https://github.com/mozilla-mobile/fxios-ctl/releases/download/v$VERSION/$TARBALL" >&2

ACTUAL_SHA=$(shasum -a 256 "$TMP_DIR/$TARBALL" | cut -d ' ' -f 1)
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
    echo "error: checksum mismatch for fxios $VERSION ($ARCH)" >&2
    echo "  expected: $EXPECTED_SHA" >&2
    echo "  actual:   $ACTUAL_SHA" >&2
    echo "Refusing to install. Update .fxios-version if the pin is stale." >&2
    exit 1
fi

mkdir -p "$TMP_DIR/unpacked"
tar -xzf "$TMP_DIR/$TARBALL" -C "$TMP_DIR/unpacked"
mkdir -p "$INSTALL_DIR"

# Move into place under a temporary name first so that concurrent installs
# can't observe a partially written binary.
chmod +x "$TMP_DIR/unpacked/fxios"
mv "$TMP_DIR/unpacked/fxios" "$INSTALL_DIR/fxios.$$"
mv "$INSTALL_DIR/fxios.$$" "$BIN"

echo "$BIN"
