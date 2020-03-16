#!/usr/bin/env bash

# This script builds the NSS3 library (with NSPR) for Desktop.

set -euvx

if [[ "${#}" -lt 1 ]] || [[ "${#}" -gt 2 ]]
then
  echo "Usage:"
  echo "./build-nss-desktop.sh <ABSOLUTE_SRC_DIR> [CROSS_COMPILE_TARGET]"
  exit 1
fi

NSS_SRC_DIR=${1}
# Whether to cross compile from Linux to a different target.  Really
# only intended for automation.
CROSS_COMPILE_TARGET=${2-}

if [[ -n "${CROSS_COMPILE_TARGET}" ]] && [[ "$(uname -s)" != "Linux" ]]; then
  echo "Can only cross compile from 'Linux'; 'uname -s' is $(uname -s)"
  exit 1
fi

if [[ "${CROSS_COMPILE_TARGET}" =~ "win32-x86-64" ]]; then
  DIST_DIR=$(abspath "desktop/win32-x86-64/nss")
  TARGET_OS="windows"
elif [[ "${CROSS_COMPILE_TARGET}" =~ "darwin" ]]; then
  DIST_DIR=$(abspath "desktop/darwin/nss")
  TARGET_OS="macos"
elif [[ -n "${CROSS_COMPILE_TARGET}" ]]; then
  echo "Cannot build NSS for unrecognized target OS ${CROSS_COMPILE_TARGET}"
  exit 1
elif [[ "$(uname -s)" == "Darwin" ]]; then
  DIST_DIR=$(abspath "desktop/darwin/nss")
  TARGET_OS="macos"
elif [[ "$(uname -s)" == "Linux" ]]; then
  # This is a JNA weirdness: "x86-64" rather than "x86_64".
  DIST_DIR=$(abspath "desktop/linux-x86-64/nss")
  TARGET_OS="linux"
else
   echo "Cannot build NSS on unrecognized host OS $(uname -s)"
   exit 1
fi

if [[ -d "${DIST_DIR}" ]]; then
  echo "${DIST_DIR} folder already exists. Skipping build."
  exit 0
fi

# TODO compile on macOS/windows machines once `chainOfTrust` is supported on macOS (1499051).
if [[ "${CROSS_COMPILE_TARGET}" =~ "darwin" ]]; then
  # Generated from nss-try@0c5d37301637ed024de8c2cbdbecf144aae12163.
  curl -sfSL --retry 5 --retry-delay 10 -O "https://fxa-dev-bucket.s3-us-west-2.amazonaws.com/a-s/nss_nspr_static_libs_darwin.tar.bz2"
  SHA256="b25d6d057d39213aeb5426dfbb0223a1d33f1706a1fcde1b3547fd7895c922f7"
  echo "${SHA256}  nss_nspr_static_libs_darwin.tar.bz2" | shasum -a 256 -c - || exit 2
  tar xvjf nss_nspr_static_libs_darwin.tar.bz2 && rm -rf nss_nspr_static_libs_darwin.tar.bz2
  NSS_DIST_DIR=$(abspath "dist")
elif [[ "${CROSS_COMPILE_TARGET}" =~ "win32-x86-64" ]]; then
  # Generated from nss-try@0c5d37301637ed024de8c2cbdbecf144aae12163.
  curl -sfSL --retry 5 --retry-delay 10 -O "https://fxa-dev-bucket.s3-us-west-2.amazonaws.com/a-s/nss_nspr_static_libs_win32.7z"
  SHA256="cdafb89f727f7a5d6cf1c6c01b58af150f780a4438863d3a1f98b6aa50809ded"
  echo "${SHA256}  nss_nspr_static_libs_win32.7z" | shasum -a 256 -c - || exit 2
  7z x nss_nspr_static_libs_win32.7z -aoa && rm -rf nss_nspr_static_libs_win32.7z
  NSS_DIST_DIR=$(abspath "dist")
elif [[ "$(uname -s)" == "Darwin" ]] || [[ "$(uname -s)" == "Linux" ]]; then
  "${NSS_SRC_DIR}"/nss/build.sh \
    -v \
    --opt \
    --static \
    --disable-tests \
    -Ddisable_dbm=1 \
    -Dsign_libs=0 \
    -Ddisable_libpkix=1
  NSS_DIST_DIR="${NSS_SRC_DIR}/dist"
fi

if [[ "${CROSS_COMPILE_TARGET}" =~ "win32-x86-64" ]]; then
  EXT="lib"
  PREFIX=""
elif [[ "$(uname -s)" == "Darwin" ]] || [[ "$(uname -s)" == "Linux" ]]; then
  EXT="a"
  PREFIX="lib"
fi

mkdir -p "${DIST_DIR}/include/nss"
mkdir -p "${DIST_DIR}/lib"
NSS_DIST_OBJ_DIR="${NSS_DIST_DIR}/Release"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}certdb.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}certhi.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}cryptohi.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}freebl_static.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}nss_static.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}nssb.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}nssdev.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}nsspki.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}nssutil.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}pk11wrap_static.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}pkcs12.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}pkcs7.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}smime.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}softokn_static.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}ssl.${EXT}" "${DIST_DIR}/lib"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}hw-acc-crypto.${EXT}" "${DIST_DIR}/lib"

# HW specific.
# https://searchfox.org/mozilla-central/rev/1eb05019f47069172ba81a6c108a584a409a24ea/security/nss/lib/freebl/freebl.gyp#159-163
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}gcm-aes-x86_c_lib.${EXT}" "${DIST_DIR}/lib"
# https://searchfox.org/mozilla-central/rev/1eb05019f47069172ba81a6c108a584a409a24ea/security/nss/lib/freebl/freebl.gyp#224-233
if [[ "${TARGET_OS}" == "windows" ]] || [[ "${TARGET_OS}" == "linux" ]]; then
  cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}intel-gcm-wrap_c_lib.${EXT}" "${DIST_DIR}/lib"
  # https://searchfox.org/mozilla-central/rev/1eb05019f47069172ba81a6c108a584a409a24ea/security/nss/lib/freebl/freebl.gyp#43-47
  if [[ "${TARGET_OS}" == "linux" ]]; then
    cp -p -L "${NSS_DIST_OBJ_DIR}/lib/${PREFIX}intel-gcm-s_lib.${EXT}" "${DIST_DIR}/lib"
  fi
fi

# For some reason the NSPR libs always have the "lib" prefix even on Windows.
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/libplc4.${EXT}" "${DIST_DIR}/lib/${PREFIX}plc4.${EXT}"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/libplds4.${EXT}" "${DIST_DIR}/lib/${PREFIX}plds4.${EXT}"
cp -p -L "${NSS_DIST_OBJ_DIR}/lib/libnspr4.${EXT}" "${DIST_DIR}/lib/${PREFIX}nspr4.${EXT}"

cp -p -L -R "${NSS_DIST_DIR}/public/nss/"* "${DIST_DIR}/include/nss"
cp -p -L -R "${NSS_DIST_OBJ_DIR}/include/nspr/"* "${DIST_DIR}/include/nss"

rm -rf "${NSS_DIST_DIR}"
