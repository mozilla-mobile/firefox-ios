#!/bin/bash

# Note that fil is tl in the l10n repo
LANGUAGES="af,an,ar,ast,az,bn,br,bs,ca,cs,cy,da,de,dsb,el,en,eo,es-AR,es-CL,es-ES,es-MX,eu,fa,fi,fil,fr,ga,gd,he,hi-IN,hsb,hu,hy-AM,ia,id,is,it,ja,ka,kab,kk,kn,ko,lo,ms,my,nb,ne-NP,nl,nn,pl,pt-BR,pt-PT,ro,ru,ses,sk,sl,sq,sv,ta,te,th,tr,uk,ur,uz,vi,zh-CN,zh-TW"

if [ $# -eq 1 ]; then
  LANGUAGES=$1
fi

DEVICE="iPhone 11"
TS=`date +%Y%m%d-%H%M`

for PRODUCT in Focus Klar; do
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
