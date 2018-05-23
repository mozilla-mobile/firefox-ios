#!/bin/bash

# Note that fil is tl in the l10n repo
LANGUAGES="af,an,ar,ast,az,bn,br,bs,ca,cs,cy,da,de,dsb,el,en,eo,es-AR,es-CL,es-ES,es-MX,eu,fa,fi,fil,fr,ga,gd,he,hi-IN,hsb,hu,hy-AM,ia,id,is,it,ja,ka,kab,kk,kn,ko,lo,ms,my,nb,ne-NP,nl,nn,pl,pt-BR,pt-PT,ro,ru,ses,sk,sl,sq,sv,ta,te,th,tr,uk,ur,uz,vi,zh-CN,zh-TW"

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

