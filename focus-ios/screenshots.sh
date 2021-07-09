#!/bin/bash

set -ex


function get_abs_path {
    local file_path="$1"
    echo "$( cd "$(dirname "$file_path")" >/dev/null 2>&1 ; pwd -P )"
}

CURRENT_DIR="$(get_abs_path $0)"
PROJECT_DIR="$(get_abs_path $CURRENT_DIR/../../../..)"

mkdir -p screenshots

if [ "$1" = '--test-without-building' ]; then
    EXTRA_FAST_LANE_ARGS='--test_without_building'
    shift
fi

# Note that fil is tl in the l10n repo
LANGUAGES="af,an,ar,ast,az,bn,br,bs,ca,cs,cy,da,de,dsb,el,en,eo,es-AR,es-CL,es-ES,es-MX,eu,fa,fi,fil,fr,ga,gd,he,hi-IN,hsb,hu,hy-AM,ia,id,is,it,ja,ka,kab,kk,kn,ko,lo,ms,my,nb,ne-NP,nl,nn,pl,pt-BR,pt-PT,ro,ru,ses,sk,sl,sq,sv,ta,te,th,tr,uk,ur,uz,vi,zh-CN,zh-TW"

if [ $# -eq 1 ]; then
  LANGUAGES=$1
fi

DEVICE="iPhone 11"

for PRODUCT in Focus Klar; do
    echo "Snapshotting $PRODUCT on $DEVICE"
        DEVICEDIR="${DEVICE// /}"
        mkdir -p "screenshots/$PRODUCT/$DEVICEDIR"
        fastlane snapshot --project Blockzilla.xcodeproj --scheme "${PRODUCT}SnapshotTests" \
          --derived_data_path screenshots-derived-data \
          --skip_open_summary \
          --erase_simulator --localize_simulator \
          --devices "$DEVICE" \
          --languages "$LANGUAGES" \
          --output_directory "screenshots/$PRODUCT/$DEVICEDIR" \
           $EXTRA_FAST_LANE_ARGS
    echo "Fastlane exited with code: $?"
done
