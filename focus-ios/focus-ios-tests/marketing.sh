#!/bin/bash

LANGUAGES="es-ES,fr,id,it,ja,pt-BR,ru,zh-CH,en-US"

TS=`date +%Y%m%d-%H%M`

for PRODUCT in Focus Klar; do
  for DEVICE in "iPhone 7 Plus" "iPad Pro (12.9-inch)"; do
    echo "Snapshotting $PRODUCT on $DEVICE"
        DEVICEDIR="${DEVICE// /}"
        mkdir -p "screenshots/$TS/$PRODUCT/$DEVICEDIR"
        fastlane snapshot --project Blockzilla.xcodeproj --scheme "${PRODUCT}MarketingTests" \
          --erase_simulator --localize_simulator \
          --devices "$DEVICE" \
          --languages "$LANGUAGES" \
          --output_directory "screenshots/$TS/$PRODUCT/$DEVICEDIR" \
          --clear_previous_screenshots > "screenshots/$TS/$PRODUCT/$DEVICEDIR/snapshot.log" 2>&1
  done
done

echo "You can now move these to pmo:"
echo
echo "  rsync -avh screenshots/$TS people.mozilla.org:~/public_html/focus/screenshots/"
echo
echo "They will be available at:"
echo
echo "  https://people-mozilla.org/~sarentz/focus/screenshots/$TS/"
echo

