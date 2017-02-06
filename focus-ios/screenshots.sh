#!/bin/bash

# Note that fil is tl in the l10n repo
LANGUAGES="ar,az,br,cs,cy,de,dsb,en-US,eo,es-CL,es-ES,fa,fil,fr,ga-IE,gd,hi-IN,hsb,hu,id,it,ja,kab,lo,nb-NO,nl,nn-NO,pl,pt-BR,pt-PT,ru,ses,sk,sl,sq,sv-SE,th,tr,uk,uz,zh-CN,zh-TW"

if [ $# -eq 1 ]; then
  LANGUAGES=$1
fi

TS=`date +%Y%m%d-%H%M`

for PRODUCT in Focus Klar; do
  for DEVICE in "iPhone 7 Plus" "iPhone 5s"; do
    echo "Snapshotting $PRODUCT on $DEVICE"
        DEVICEDIR="${DEVICE// /}"
        mkdir -p "screenshots/$TS/$PRODUCT/$DEVICEDIR"
        fastlane snapshot --project Blockzilla.xcodeproj --scheme "${PRODUCT}SnapshotTests" \
          --skip_open_summary \
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

