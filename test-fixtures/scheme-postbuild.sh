#
# UITests and XCUITests run this as a post-build step, to copy all files from
# test-fixtures into the app bundle, so they can be loaded by Client.app under
# test, for instance for having pregenerated prefs or pregenerated browser.db. 
#
# XCUITests in particular need this method of due to black-boxing of the host app.
# The Xcode-provided method to load test bundles does not work for App Groups.
#

#!/bin/bash
echo "SCRIPT STARTING"
echo "Script path: $0"
echo "Current dir: $(pwd)"

echo "••• Preparing test-fixtures directory for UI tests •••"

# Resolve repo root
if [ -n "$BITRISE_SOURCE_DIR" ]; then
  echo "Detected Bitrise — using BITRISE_SOURCE_DIR"
  REPO_ROOT="$BITRISE_SOURCE_DIR"
else
  # Fallback: traverse up from this script to find test-fixtures
  echo "No BITRISE_SOURCE_DIR — walking up from script path"
  SCRIPT_PATH="${BASH_SOURCE[0]}"
  DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

  while [ "$DIR" != "/" ]; do
    if [ -d "$DIR/test-fixtures" ]; then
      REPO_ROOT="$DIR"
      break
    fi
    DIR="$(dirname "$DIR")"
  done
fi

if [ -z "$REPO_ROOT" ]; then
  echo "Could not resolve repo root."
  exit 1
fi

echo "Repo root: $REPO_ROOT"

fixtures="$REPO_ROOT/test-fixtures"
echo "Fixtures path: $fixtures"

if [ ! -d "$fixtures" ]; then
  echo "Fixtures directory not found: $fixtures"
  exit 1
fi

# Prepare a temp location inside TMPDIR for the app to read at runtime
runtime_fixtures_path="$TMPDIR/test-fixtures"
echo "Copying test fixtures to runtime-accessible path: $runtime_fixtures_path"

mkdir -p "$runtime_fixtures_path"

# Copy contents
rsync -zvrt --delete --update "$fixtures/" "$runtime_fixtures_path"

echo "Fixtures prepared successfully"