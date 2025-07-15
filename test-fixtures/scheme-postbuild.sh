#
# UITests and XCUITests run this as a post-build step, to copy all files from
# test-fixtures into the app bundle, so they can be loaded by Client.app under
# test, for instance for having pregenerated prefs or pregenerated browser.db. 
#
# XCUITests in particular need this method of due to black-boxing of the host app.
# The Xcode-provided method to load test bundles does not work for App Groups.
#

#!/bin/bash
exec 1>&2  # redirect stdout to stderr so Bitrise shows it

echo "🏗️ SCRIPT STARTING"
echo "🔍 Script path: $0"
echo "📂 Current dir: $(pwd)"

echo "••• Preparing test-fixtures directory for UI tests •••"

SCRIPT_PATH="${BASH_SOURCE[0]:-${(%):-%N}}"
echo $SCRIPT_PATH
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
echo $SCRIPT_DIR
SRCROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
echo $SRCROOT

fixtures="$SRCROOT/test-fixtures"
echo $fixtures
[[ -d "$fixtures" ]] || {
  echo "Fixtures directory not found at: $fixtures"
  exit 1
}

# Prepare a temp location inside TMPDIR for the app to read at runtime
runtime_fixtures_path="$TMPDIR/test-fixtures"
echo "Copying test fixtures to runtime-accessible path: $runtime_fixtures_path"
mkdir -p "$runtime_fixtures_path"

# Perform the copy
rsync -zvrt --delete --update "$fixtures/" "$runtime_fixtures_path"

echo "Fixtures prepared successfully"
