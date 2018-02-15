#
# UITests and XCUITests run this as a post-build step, to copy all files from
# test-fixtures into the app bundle, so they can be loaded by Client.app under
# test, for instance for having pregenerated prefs or pregenerated browser.db. 
#
# XCUITests in particular need this method of due to black-boxing of the host app.
# The Xcode-provided method to load test bundles does not work for App Groups.
#

echo "••• Populate test-fixtures dir in Client.app bundle •••"
fixtures="${SRCROOT}/test-fixtures"
[[ -e $fixtures ]] || exit 1
outpath="${TARGET_BUILD_DIR}/Client.app"
rsync -zvrt --update "$fixtures" "$outpath" 
