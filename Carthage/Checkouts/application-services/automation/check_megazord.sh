#!/usr/bin/env bash

set -euvx

if [[ "$#" -ne 1 ]]
then
    echo "Usage:"
    echo "./automation/check_megazord.sh <megazord_name>"
    exit 1
fi

MEGAZORD_NAME=$1

# shellcheck disable=SC1091
source "libs/android_defaults.sh"

# The `full-megazord` is `libmegazord.so`. Eventually we should figure out a way
# to avoid hardcoding this check, but for now it's not too bad.
if [[ "$MEGAZORD_NAME" = "full" ]]; then
    MEGAZORD_NAME="megazord"
fi

# For now just check x86_64 since we only run this for PRs
TARGET_ARCHS=("x86_64") # "x86" "arm64" "arm")
NM_BINS=("x86_64-linux-android-nm") # "i686-linux-android-nm" "aarch64-linux-android-nm" "arm-linux-androideabi-nm")
RUST_TRIPLES=("x86_64-linux-android") # "i686-linux-android" "aarch64-linux-android" "armv7-linux-androideabi")

FORBIDDEN_SYMBOL="viaduct_detect_reqwest_backend"
for i in "${!TARGET_ARCHS[@]}"; do
    NM="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${NDK_HOST_TAG}/bin/${NM_BINS[$i]}"
    MEGAZORD_PATH="./target/${RUST_TRIPLES[i]}/release/lib${MEGAZORD_NAME}.so"
    printf '\nTesting if %s contains the legacy/test-only HTTP stack\n\n' "${MEGAZORD_PATH}"
    # Returns error status on failure, which will cause us to exit because of set -e.
    ./testing/err-if-symbol.sh "$NM" "${MEGAZORD_PATH}" "${FORBIDDEN_SYMBOL}"
done
