#!/bin/bash

# Note that fil is tl in the l10n repo
LANGUAGES="af,ar,az,bn,br,ca,cs,cy,de,dsb,en-US,eo,es,es-CL,eu,fa,fil,fr,ga-IE,gd,he,hi-IN,hsb,hu,id,is,it,ja,kab,kk,ko,lo,my,nb-NO,nl,nn-NO,pl,pt-BR,pt-PT,ru,ses,sk,sl,sq,sv-SE,th,tr,uk,uz,zh-CN,zh-TW"

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
          --derived_data_path screenshots-derived-data \
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

