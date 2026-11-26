#!/usr/bin/env bash
# Usage: set-destination-label.sh DESTINATION [DESTINATION ...]
# Exports DESTINATION_LABEL, e.g. "iPhone 18 Pro (iOS 27.0), iPad (A16) (iOS 27.0)". Empty arguments are skipped.
LABELS=()
for DESTINATION in "$@"; do
    [ -z "$DESTINATION" ] && continue
    NAME=$(sed -E 's/.*name=([^,]+).*/\1/' <<< "$DESTINATION")
    OS=$(sed -E 's/.*OS=([^,]+).*/\1/' <<< "$DESTINATION")
    LABELS+=("$NAME (iOS $OS)")
done
DEVICES=$(printf '%s, ' "${LABELS[@]}")
envman add --key DESTINATION_LABEL --value "${DEVICES%, }"
