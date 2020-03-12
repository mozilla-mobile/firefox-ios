#!/usr/bin/env bash
set -euvx

# XCode tries to be helpful and overwrites the PATH. Reset that.
PATH="$(bash -l -c 'echo $PATH')"

# This should be invoked from inside xcode, not manually
if [[ "${#}" -ne 4 ]]
then
    echo "Usage (note: only call inside xcode!):"
    echo "path/to/build-scripts/xc-universal-binary.sh <STATIC_LIB_NAME> <FFI_TARGET> <APPSVC_ROOT_PATH> <buildvariant>"
    exit 1
fi
# e.g. liblogins_ffi.a
STATIC_LIB_NAME=${1}
# what to pass to cargo build -p, e.g. logins_ffi
FFI_TARGET=${2}
# path to app services root
APPSVC_ROOT=${3}
# buildvariant from our xcconfigs
BUILDVARIANT=${4}

RELFLAG=
RELDIR="debug"
if [[ "${BUILDVARIANT}" != "debug" ]]; then
    RELFLAG=--release
    RELDIR=release
fi

LIBSDIR=${APPSVC_ROOT}/libs
TARGETDIR=${APPSVC_ROOT}/target

# If the libs don't exist, or it's modification time is older than the last commit in ${LIBSDIR}/ios, wipe it out.
if [[ ! -d "${LIBSDIR}/ios" ]] || [[ "$(stat -f "%m" "${LIBSDIR}/ios")" -lt "$(git log -n 1 --pretty=format:%at -- "${LIBSDIR}")" ]]; then
    echo "No iOS libs present, or they are stale"
    pushd "${LIBSDIR}"
    rm -rf ios
    env -i PATH="${PATH}" HOME="${HOME}" ./build-all.sh ios
    popd
else
    echo "iOS libs already present, not rebuilding"
fi

# We can't use cargo lipo because we can't link to universal libraries :(
# https://github.com/rust-lang/rust/issues/55235
LIBS_ARCHS=("x86_64" "arm64")
IOS_TRIPLES=("x86_64-apple-ios" "aarch64-apple-ios")
for i in "${!LIBS_ARCHS[@]}"; do
    LIB_ARCH=${LIBS_ARCHS[${i}]}
    env -i \
        PATH="${PATH}" \
        NSS_STATIC=1 \
        NSS_DIR="${LIBSDIR}/ios/${LIB_ARCH}/nss" \
        SQLCIPHER_LIB_DIR="${LIBSDIR}/ios/${LIB_ARCH}/sqlcipher/lib" \
        SQLCIPHER_INCLUDE_DIR="${LIBSDIR}/ios/${LIB_ARCH}/sqlcipher/include" \
        RUSTC_WRAPPER="${RUSTC_WRAPPER:-}" \
        SCCACHE_IDLE_TIMEOUT="${SCCACHE_IDLE_TIMEOUT:-}" \
        SCCACHE_CACHE_SIZE="${SCCACHE_CACHE_SIZE:-}" \
        SCCACHE_ERROR_LOG="${SCCACHE_ERROR_LOG:-}" \
        RUST_LOG="${RUST_LOG:-}" \
    "${HOME}"/.cargo/bin/cargo build --locked -p "${FFI_TARGET}" --lib ${RELFLAG} --target "${IOS_TRIPLES[${i}]}"
done

UNIVERSAL_BINARY=${TARGETDIR}/universal/${RELDIR}/${STATIC_LIB_NAME}
NEED_LIPO=

# if the universal binary doesnt exist, or if it's older than the static libs,
# we need to run `lipo` again.
if [[ ! -f "${UNIVERSAL_BINARY}" ]]; then
    NEED_LIPO=1
elif [[ "$(stat -f "%m" "${TARGETDIR}/x86_64-apple-ios/${RELDIR}/${STATIC_LIB_NAME}")" -gt "$(stat -f "%m" "${UNIVERSAL_BINARY}")" ]]; then
    NEED_LIPO=1
elif [[ "$(stat -f "%m" "${TARGETDIR}/aarch64-apple-ios/${RELDIR}/${STATIC_LIB_NAME}")" -gt "$(stat -f "%m" "${UNIVERSAL_BINARY}")" ]]; then
    NEED_LIPO=1
fi
if [[ "${NEED_LIPO}" = "1" ]]; then
    mkdir -p "${TARGETDIR}/universal/${RELDIR}"
    lipo -create -output "${UNIVERSAL_BINARY}" \
        "${TARGETDIR}/x86_64-apple-ios/${RELDIR}/${STATIC_LIB_NAME}" \
        "${TARGETDIR}/aarch64-apple-ios/${RELDIR}/${STATIC_LIB_NAME}"
fi
