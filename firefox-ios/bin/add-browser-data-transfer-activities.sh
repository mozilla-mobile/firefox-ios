#!/usr/bin/env bash
#
# Adds the BrowserKit data transfer activities to the built Info.plist of developer (Debug) and Beta builds.
# The source Client/Info.plist leaves them out, so every other configuration never registers them.
# Registering an activity makes iOS offer Firefox for browser data import or export, which would look like
# a shipped feature while it is still being implemented.
#
# Usage: add-browser-data-transfer-activities.sh <build configuration> <built Info.plist>

set -e

configuration="$1"
plist="$2"

case "$configuration" in
    Debug|FirefoxBeta) ;;
    *) exit 0 ;;
esac

activities="BEBrowserDataExchangeImportActivity"

for activity in $activities; do
    index=0
    found=false
    while value=$(/usr/libexec/PlistBuddy -c "Print :NSUserActivityTypes:$index" "$plist" 2>/dev/null); do
        if [ "$value" = "$activity" ]; then
            found=true
            break
        fi
        index=$((index + 1))
    done

    if [ "$found" = false ]; then
        /usr/libexec/PlistBuddy -c "Add :NSUserActivityTypes: string $activity" "$plist"
    fi
done
