#!/usr/bin/env bash

set -euvx

if [[ "${#}" -lt 1 ]] || [[ "${#}" -gt 2 ]]
then
  echo "Usage:"
  echo "./build-sqlcipher-desktop.sh <ABSOLUTE_SRC_DIR> [CROSS_COMPILE_TARGET]"
  exit 1
fi

SQLCIPHER_SRC_DIR=${1}
# Whether to cross compile from Linux to a different target.  Really
# only intended for automation.
CROSS_COMPILE_TARGET=${2-}

if [[ -n "${CROSS_COMPILE_TARGET}" ]] && [[ "$(uname -s)" != "Linux" ]]; then
  echo "Can only cross compile from 'Linux'; 'uname -s' is $(uname -s)"
  exit 1
fi

if [[ "${CROSS_COMPILE_TARGET}" =~ "win32-x86-64" ]]; then
  DIST_DIR=$(abspath "desktop/win32-x86-64/sqlcipher")
  NSS_DIR=$(abspath "desktop/win32-x86-64/nss")
  TARGET_OS="windows"
elif [[ "${CROSS_COMPILE_TARGET}" =~ "darwin" ]]; then
  DIST_DIR=$(abspath "desktop/darwin/sqlcipher")
  NSS_DIR=$(abspath "desktop/darwin/nss")
  TARGET_OS="macos"
elif [[ -n "${CROSS_COMPILE_TARGET}" ]]; then
  echo "Cannot build SQLCipher for unrecognized target OS ${CROSS_COMPILE_TARGET}"
  exit 1
elif [[ "$(uname -s)" == "Darwin" ]]; then
  DIST_DIR=$(abspath "desktop/darwin/sqlcipher")
  NSS_DIR=$(abspath "desktop/darwin/nss")
  TARGET_OS="macos"
elif [[ "$(uname -s)" == "Linux" ]]; then
  # This is a JNA weirdness: "x86-64" rather than "x86_64".
  DIST_DIR=$(abspath "desktop/linux-x86-64/sqlcipher")
  NSS_DIR=$(abspath "desktop/linux-x86-64/nss")
  TARGET_OS="linux"
else
   echo "Cannot build SQLcipher on unrecognized host OS $(uname -s)"
   exit 1
fi

if [[ -d "${DIST_DIR}" ]]; then
  echo "${DIST_DIR} folder already exists. Skipping build."
  exit 0
fi

echo "# Building sqlcipher"

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
  -DSQLITE_SECURE_DELETE=1 \
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
  -lgcm-aes-x86_c_lib \
"

if [[ "${TARGET_OS}" == "windows" ]]; then
  LIBS="${LIBS} -lintel-gcm-wrap_c_lib"
elif [[ "${TARGET_OS}" == "linux" ]]; then
  LIBS="${LIBS} -lintel-gcm-wrap_c_lib -lintel-gcm-s_lib"
fi

BUILD_DIR=$(mktemp -d)
pushd "${BUILD_DIR}"

# Why `--with-pic --enable-shared`?  We're doing unusual things.  By
# default, libtool builds a static library (.a) with a non-PIC .o, and
# a shared library (.so, say) with a PIC .o.  We want to compile PIC
# .o files for use in subsequent compilations and wrap them in a .a.
# We achieve that by forcing PIC (even for the .a) and disabling the
# shared library (.so) entirely.

if [[ "${CROSS_COMPILE_TARGET}" =~ "darwin" ]]; then
  export CC=/tmp/clang/bin/clang

  export AR=/tmp/cctools/bin/x86_64-darwin11-ar
  export RANLIB=/tmp/cctools/bin/x86_64-darwin11-ranlib
  export STRIP=/tmp/cctools/bin/x86_64-darwin11-strip
  export LIBTOOL=/tmp/cctools/bin/x86_64-darwin11-libtool
  export NM=/tmp/cctools/bin/x86_64-darwin11-nm
  export LD=/tmp/cctools/bin/x86_64-darwin11-ld

  export CFLAGS='-B /tmp/cctools/bin -target x86_64-darwin11 -mlinker-version=137 -isysroot /tmp/MacOSX10.11.sdk -I/tmp/MacOSX10.11.sdk/usr/include -iframework /tmp/MacOSX10.11.sdk/System/Library/Frameworks'
  export LDFLAGS='-B /tmp/cctools/bin -Wl,-syslibroot,/tmp/MacOSX10.11.sdk -Wl,-dead_strip'
  # This is crucial.  Without this, libtool drops the `-target ...`
  # flags from the clang compiler linker driver invocation, resulting
  # in clang choosing a random system `ld` rather than the macOS
  # linker from the cctools port.
  export LTLINK_EXTRAS='-XCClinker -target -XCClinker x86_64-darwin11 -XCClinker -B -XCClinker /tmp/cctools/bin'

  # See https://searchfox.org/mozilla-central/rev/8848b9741fc4ee4e9bc3ae83ea0fc048da39979f/build/macosx/cross-mozconfig.common#12-13.
  export LD_LIBRARY_PATH=/tmp/clang/lib

  "${SQLCIPHER_SRC_DIR}/configure" \
    --with-pic \
    --disable-shared \
    --host=x86_64-apple-darwin \
    --with-crypto-lib=none \
    --disable-tcl \
    --enable-tempstore=yes \
    CFLAGS="${CFLAGS} ${SQLCIPHER_CFLAGS}" \
    LDFLAGS="${LDFLAGS} -L${NSS_DIR}/lib" \
    LIBS="${LIBS}"
elif [[ "${CROSS_COMPILE_TARGET}" =~ "win32-x86-64" ]]; then

pushd "${SQLCIPHER_SRC_DIR}"

# From https://github.com/qTox/qTox/blob/9525505bff8719c84b6193174ea5e7ec097c54b8/windows/cross-compile/build.sh#L390-L446.
# shellcheck disable=SC2016
sed -i s/'if test "$TARGET_EXEEXT" = ".exe"'/'if test ".exe" = ".exe"'/g configure

# Can't quite figure out what to tell ./configure so that it gets the picture
# here (it doesn't seem to handle host/build/target args correctly)... Oh well,
# this is a bit of a sledgehammer but does the job.
sed -i s/'BEXE = @BUILD_EXEEXT@'/'BEXE = ""'/g Makefile.in

> Makefile.in-patch cat << "EOF"
--- Makefile.in        2017-12-21 19:31:28.000000000 +0000
+++ Makefile.in        2018-11-06 23:58:45.576548000 +0000
@@ -1092,9 +1092,9 @@
    $(TOP)/ext/fts5/fts5_unicode2.c \
    $(TOP)/ext/fts5/fts5_varint.c \
    $(TOP)/ext/fts5/fts5_vocab.c  \

-fts5parse.c:  $(TOP)/ext/fts5/fts5parse.y lemon
+fts5parse.c:  $(TOP)/ext/fts5/fts5parse.y lemon$(BEXE)
       cp $(TOP)/ext/fts5/fts5parse.y .
       rm -f fts5parse.h
       ./lemon$(BEXE) $(OPTS) fts5parse.y
EOF

patch --forward --ignore-whitespace < Makefile.in-patch
popd

  "${SQLCIPHER_SRC_DIR}/configure" \
    --with-pic \
    --disable-shared \
    --build=x86_64 \
    --host=x86_64-w64-mingw32 \
    --target=x86_64-w64-mingw32 \
    --enable-tempstore=yes \
    --with-crypto-lib=none \
    --disable-tcl \
    CFLAGS="${SQLCIPHER_CFLAGS}" \
    LDFLAGS="-L${NSS_DIR}/lib" \
    LIBS="${LIBS}"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  "${SQLCIPHER_SRC_DIR}/configure" \
    --with-pic \
    --disable-shared \
    --enable-tempstore=yes \
    --with-crypto-lib=none \
    --disable-tcl \
    CFLAGS="${SQLCIPHER_CFLAGS}" \
    LDFLAGS="-L${NSS_DIR}/lib" \
    LIBS="${LIBS}"
elif [[ "$(uname -s)" == "Linux" ]]; then
  "${SQLCIPHER_SRC_DIR}/configure" \
    --with-pic \
    --disable-shared \
    --enable-tempstore=yes \
    --with-crypto-lib=none \
    --disable-tcl \
    CFLAGS="${SQLCIPHER_CFLAGS}" \
    LDFLAGS="-L${NSS_DIR}/lib" \
    LIBS="${LIBS}"
fi

make sqlite3.h
make sqlite3ext.h
make libsqlcipher.la

mkdir -p "${DIST_DIR}/include/sqlcipher"
mkdir -p "${DIST_DIR}/lib"

cp -p "${BUILD_DIR}/sqlite3.h" "${DIST_DIR}/include/sqlcipher"
cp -p "${BUILD_DIR}/sqlite3ext.h" "${DIST_DIR}/include/sqlcipher"
cp -p "${BUILD_DIR}/.libs/libsqlcipher.a" "${DIST_DIR}/lib"

chmod +w "${DIST_DIR}/lib/libsqlcipher.a"

if [[ "${CROSS_COMPILE_TARGET}" =~ "win32-x86-64" ]]; then
  mv "${DIST_DIR}/lib/libsqlcipher.a" "${DIST_DIR}/lib/sqlcipher.lib"
fi

popd
