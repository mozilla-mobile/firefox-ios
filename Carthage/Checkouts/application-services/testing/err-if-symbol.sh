#!/usr/bin/env bash

set -euvx

if [[ "$#" -ne 3 ]]
then
    echo "Usage: <path/to/relevant/nm> <path/to/relevant/library> <symbol_name>"
    echo "Example Usage:"
    echo "$ bash testing/err-if-symbol.sh \\"
    echo "    \${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${NDK_HOST_TAG}/bin/i686-linux-android-nm \\"
    echo "    target/i686-linux-android/release/librc_log_ffi.so \\"
    echo "    viaduct_detect_reqwest_backend"
    exit 1
fi

NM=$1
LIBRARY=$2
SYMBOL=$3

if [[ ! -f "${LIBRARY}" ]]; then
    echo "Library arg \"${LIBRARY}\" does not exist"
    exit 1
fi

PATTERN="\\b${SYMBOL}\\b"

# Split up for better error detection/reporting
ALLSYMS=$("${NM}" -g "${LIBRARY}")

# Note: grep always returns an error when it gets 0 matches, so make sure it
# always has enough matches so what we don't have to silence it's errors (which
# might be about other things too...)

FOUND=$(echo "${ALLSYMS} ${SYMBOL}" | grep -cE "${PATTERN}")

if [[ "$FOUND" -ne 1 ]]; then
    echo "Error: Found unexpected symbol in \"${LIBRARY}\": \"${SYMBOL}\""
    exit 1
else
    echo "PASS ${LIBRARY}"
fi
