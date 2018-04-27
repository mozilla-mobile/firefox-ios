#!/bin/bash

if [[ "$USE_ROME_CARTHAGE" = "YES"  &&  "$BUDDYBUILD_SCHEME" != "Fennec_Enterprise_*" ]] ; then
    echo "[Rome script] installing rome "
    brew install blender/homebrew-tap/rome

    mkdir -p ~/.aws
    echo "[default]
    region = us-west-2" > ~/.aws/config

    echo "[Rome script] download missing frameworks"
    rome download --platform iOS

    echo "[Rome script] list what is missing and update/build if needed"
    rome list --missing --platform ios | awk '{print $1}' | xargs carthage bootstrap --platform ios

    echo "[Rome script] upload what is missing"
    rome list --missing --platform ios | awk '{print $1}' | xargs rome upload --platform ios
else
 carthage bootstrap --platform ios
fi
