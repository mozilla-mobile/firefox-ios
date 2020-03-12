#!/usr/bin/env bash

set -euvx

# Our short-names for the architectures.
TARGET_ARCHS=("x86_64" "x86" "arm64" "arm")
# The directories required for the Android-Gradle plugin and APK
# layout, like `jniLibs/x86` or `lib/x86` respectively.
TARGET_ARCHS_DISTS=("x86_64" "x86" "arm64-v8a" "armeabi-v7a")
# The corresponding Rust target names.
TARGET_ARCHS_TOOLCHAINS=("x86_64-linux-android" "i686-linux-android" "aarch64-linux-android" "arm-linux-androideabi")

# End of configuration.

if [[ "${#}" -ne 2 ]]
then
    echo "Usage:"
    echo "./build-all-android.sh <SQLCIPHER_SRC_PATH> <NSS_SRC_PATH>"
    exit 1
fi

# shellcheck disable=SC1091
source "android_defaults.sh"
SQLCIPHER_SRC_PATH=${1}
NSS_SRC_PATH=${2}

echo "# Building NSS"
for i in "${!TARGET_ARCHS[@]}"; do
  DIST=${TARGET_ARCHS_DISTS[${i}]}
  DIST_DIR=$(abspath "android/${DIST}/nss")
  if [[ -d "${DIST_DIR}" ]]; then
    echo "${DIST_DIR} already exists. Skipping building nss."
  else
    ./build-nss-android.sh "${NSS_SRC_PATH}" "${DIST_DIR}" "${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${NDK_HOST_TAG}" "${TARGET_ARCHS_TOOLCHAINS[${i}]}" "${ANDROID_NDK_API_VERSION}" || exit 1
  fi
done

echo "# Building sqlcipher"
for i in "${!TARGET_ARCHS[@]}"; do
  DIST=${TARGET_ARCHS_DISTS[${i}]}
  NSS_DIR=$(abspath "android/${DIST}/nss")
  DIST_DIR=$(abspath "android/${DIST}/sqlcipher")
  if [[ -d "${DIST_DIR}" ]]; then
    echo "${DIST_DIR} already exists. Skipping building sqlcipher."
  else
    ./build-sqlcipher-android.sh "${SQLCIPHER_SRC_PATH}" "${DIST_DIR}" "${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${NDK_HOST_TAG}" "${TARGET_ARCHS_TOOLCHAINS[${i}]}" "${ANDROID_NDK_API_VERSION}" "${NSS_DIR}" || exit 1
  fi
done
