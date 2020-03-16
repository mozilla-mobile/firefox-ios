#!/usr/bin/env bash

# This script downloads and builds the SQLcipher library for Android.

set -euvx

if [[ "${#}" -ne 6 ]]
then
    echo "Usage:"
    echo "./build-sqlcipher-android.sh <ABSOLUTE_SRC_DIR> <DIST_DIR> <TOOLCHAIN_PATH> <TOOLCHAIN> <ANDROID_NDK_API_VERSION> <NSS_DIR>"
    exit 1
fi

SQLCIPHER_SRC_DIR=${1}
DIST_DIR=${2}
TOOLCHAIN_PATH=${3}
TOOLCHAIN=${4}
ANDROID_NDK_API_VERSION=${5}
NSS_DIR=${6}

if [[ -d "${DIST_DIR}" ]]; then
  echo "${DIST_DIR} folder already exists. Skipping build."
  exit 0
fi

export AR="${TOOLCHAIN_PATH}/bin/${TOOLCHAIN}-ar"
export CC="${TOOLCHAIN_PATH}/bin/${TOOLCHAIN}${ANDROID_NDK_API_VERSION}-clang"
export CXX="${TOOLCHAIN_PATH}/bin/${TOOLCHAIN}${ANDROID_NDK_API_VERSION}-clang++"
# https://developer.android.com/ndk/guides/other_build_systems:
# For 32-bit ARM, the compiler is prefixed with armv7a-linux-androideabi,
# but the binutils tools are prefixed with arm-linux-androideabi.
if [[ "${TOOLCHAIN}" == "arm-linux-androideabi" ]]; then
  export CC="${TOOLCHAIN_PATH}/bin/armv7a-linux-androideabi${ANDROID_NDK_API_VERSION}-clang"
  export CXX="${TOOLCHAIN_PATH}/bin/armv7a-linux-androideabi${ANDROID_NDK_API_VERSION}-clang++"
fi
export LD="${TOOLCHAIN_PATH}/bin/${TOOLCHAIN}-ld"
export RANLIB="${TOOLCHAIN_PATH}/bin/${TOOLCHAIN}-ranlib"

if [[ "${TOOLCHAIN}" == "x86_64-linux-android" ]]
then
  HOST="x86_64-linux"
elif [[ "${TOOLCHAIN}" == "i686-linux-android" ]]
then
  HOST="i686-linux"
elif [[ "${TOOLCHAIN}" == "aarch64-linux-android" ]]
then
  HOST="arm-linux"
elif [[ "${TOOLCHAIN}" == "arm-linux-androideabi" ]]
then
  HOST="arm-linux"
else
  echo "Unknown toolchain"
  exit 1
fi

# Keep in sync with SQLCIPHER_CFLAGS in `build-sqlcipher-desktop.sh` for now (it probably makes
# sense to try to avoid this duplication in the future).
# TODO: We could probably prune some of these, and it would be nice to allow debug builds (which
# should set `SQLITE_DEBUG` and `SQLITE_ENABLE_API_ARMOR` and not `NDEBUG`).
SQLCIPHER_CFLAGS=" \
  -DSQLITE_HAS_CODEC \
  -DSQLITE_SOUNDEX \
  -DHAVE_USLEEP=1 \
  -DSQLITE_MAX_VARIABLE_NUMBER=99999 \
  -DSQLITE_THREADSAFE=1 \
  -DSQLITE_DEFAULT_JOURNAL_SIZE_LIMIT=1048576 \
  -DNDEBUG=1 \
  -DSQLITE_ENABLE_MEMORY_MANAGEMENT=1 \
  -DSQLITE_ENABLE_LOAD_EXTENSION \
  -DSQLITE_ENABLE_COLUMN_METADATA \
  -DSQLITE_ENABLE_UNLOCK_NOTIFY \
  -DSQLITE_ENABLE_RTREE \
  -DSQLITE_ENABLE_STAT3 \
  -DSQLITE_ENABLE_STAT4 \
  -DSQLITE_ENABLE_JSON1 \
  -DSQLITE_ENABLE_FTS3_PARENTHESIS \
  -DSQLITE_ENABLE_FTS4 \
  -DSQLITE_ENABLE_FTS5 \
  -DSQLCIPHER_CRYPTO_NSS \
  -DSQLITE_ENABLE_DBSTAT_VTAB \
  -DSQLITE_SECURE_DELETE \
  -DSQLITE_DEFAULT_PAGE_SIZE=32768 \
  -DSQLITE_MAX_DEFAULT_PAGE_SIZE=32768 \
  -I${NSS_DIR}/include \
"

LIBS="\
  -lcertdb \
  -lcerthi \
  -lcryptohi \
  -lfreebl_static \
  -lhw-acc-crypto \
  -lnspr4 \
  -lnss_static \
  -lnssb \
  -lnssdev \
  -lnsspki \
  -lnssutil \
  -lpk11wrap_static \
  -lplc4 \
  -lplds4 \
  -lsoftokn_static \
"

if [[ "${TOOLCHAIN}" == "x86_64-linux-android" ]] || [[ "${TOOLCHAIN}" == "i686-linux-android" ]]; then
  LIBS="${LIBS} -lgcm-aes-x86_c_lib"
elif [[ "${TOOLCHAIN}" == "aarch64-linux-android" ]]; then
  LIBS="${LIBS} -lgcm-aes-aarch64_c_lib"
fi
if [[ "${TOOLCHAIN}" == "x86_64-linux-android" ]]; then
  LIBS="${LIBS} -lintel-gcm-wrap_c_lib -lintel-gcm-s_lib"
fi

BUILD_DIR=$(mktemp -d)
pushd "${BUILD_DIR}"

"${SQLCIPHER_SRC_DIR}/configure" \
  --host="${HOST}" \
  --with-pic \
  --verbose \
  --disable-shared \
  --with-crypto-lib=none \
  --disable-tcl \
  --enable-tempstore=yes \
  CFLAGS="${SQLCIPHER_CFLAGS}" \
  LDFLAGS="-L${NSS_DIR}/lib" \
  LIBS="${LIBS} -llog -lm"

make sqlite3.h
make sqlite3ext.h
make libsqlcipher.la

mkdir -p "${DIST_DIR}/include/sqlcipher"
mkdir -p "${DIST_DIR}/lib"

cp -p "${BUILD_DIR}/sqlite3.h" "${DIST_DIR}/include/sqlcipher"
cp -p "${BUILD_DIR}/sqlite3ext.h" "${DIST_DIR}/include/sqlcipher"
cp -p "${BUILD_DIR}/.libs/libsqlcipher.a" "${DIST_DIR}/lib"

# Just in case, ensure that the created binaries are not -w.
chmod +w "${DIST_DIR}/lib/libsqlcipher.a"

popd
