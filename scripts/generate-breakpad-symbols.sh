#!/bin/sh

DATE=$( /bin/date +"%Y-%m-%d" )
ARCHIVE=$( /bin/ls -t "${HOME}/Library/Developer/Xcode/Archives/${DATE}" | /usr/bin/grep xcarchive | /usr/bin/sed -n 1p )
DSYM="${HOME}/Library/Developer/Xcode/Archives/${DATE}/${ARCHIVE}/dSYMs/${PRODUCT_NAME}.app.dSYM"
MACHO="${HOME}/Library/Developer/Xcode/Archives/${DATE}/${ARCHIVE}/Products/Applications/${PRODUCT_NAME}.app/${PRODUCT_NAME}"
SYMBOLS_DIR="${PROJECT_DIR}/build_symbols"

mkdir -p "${SYMBOLS_DIR}"

"${PROJECT_DIR}/tools/dump_syms" -a arm64 "${MACHO}" > "${SYMBOLS_DIR}/${MOZ_RELEASE_CHANNEL}.${MOZ_VERSION}.${MOZ_BUILD_ID}.arm64.sym"
"${PROJECT_DIR}/tools/dump_syms" -a armv7 "${MACHO}" > "${SYMBOLS_DIR}/${MOZ_RELEASE_CHANNEL}.${MOZ_VERSION}.${MOZ_BUILD_ID}.armv7.sym"
