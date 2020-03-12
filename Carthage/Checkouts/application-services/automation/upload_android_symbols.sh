#!/usr/bin/env bash

set -euvx

if [[ "${#}" -ne 1 ]]
then
    echo "Usage:"
    echo "./automation/upload_android_symbols.sh <project path>"
    exit 1
fi

if [[ ! -f "$PWD/libs/android_defaults.sh" ]]
then
    echo "upload_android_symbols.sh must be executed from the root directory."
    exit 1
fi

PROJECT_PATH=${1}

# shellcheck disable=SC1091
source "libs/android_defaults.sh"

OUTPUT_FOLDER="crashreporter-symbols"
DUMP_SYMS_DIR="automation/symbols-generation/bin"

if [[ ! -f "${DUMP_SYMS_DIR}/dump_syms" ]]; then
  tooltool.py --manifest=automation/symbols-generation/dump_syms.manifest --url=http://taskcluster/tooltool.mozilla-releng.net/ fetch
  chmod +x dump_syms
  mkdir -p "${DUMP_SYMS_DIR}"
  mv dump_syms "${DUMP_SYMS_DIR}"
fi

# Keep the 3 in sync.
TARGET_ARCHS=("x86_64" "x86" "arm64" "arm")
JNI_LIBS_TARGETS=("x86_64" "x86" "arm64-v8a" "armeabi-v7a")
OBJCOPY_BINS=("x86_64-linux-android-objcopy" "i686-linux-android-objcopy" "aarch64-linux-android-objcopy" "arm-linux-androideabi-objcopy")

rm -rf "${OUTPUT_FOLDER}"
mkdir -p "${OUTPUT_FOLDER}"

# 1. Generate the symbols.
for i in "${!TARGET_ARCHS[@]}"; do
  export OBJCOPY="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${NDK_HOST_TAG}/bin/${OBJCOPY_BINS[${i}]}"
  JNI_SO_PATH="${PROJECT_PATH}/build/rustJniLibs/android/${JNI_LIBS_TARGETS[${i}]}"
  for sofile in "${JNI_SO_PATH}"/*.so; do
    python3 automation/symbols-generation/symbolstore.py -c -s . --vcs-info "${DUMP_SYMS_DIR}"/dump_syms "${OUTPUT_FOLDER}" "${sofile}"
  done
done

# 2. Upload them.
pip3 install -r automation/symbols-generation/requirements.txt
python3 automation/symbols-generation/upload_symbols.py "${OUTPUT_FOLDER}"
