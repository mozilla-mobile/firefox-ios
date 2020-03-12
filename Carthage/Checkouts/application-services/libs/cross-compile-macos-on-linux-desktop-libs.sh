#!/usr/bin/env bash

# Install clang, a port of cctools, and the macOS SDK into /tmp. This
# is all cribbed from mozilla-central; start at
# https://searchfox.org/mozilla-central/rev/39cb1e96cf97713c444c5a0404d4f84627aee85d/build/macosx/cross-mozconfig.common.

set -euvx

MANIFEST="${PWD}/macos-cc-tools.manifest"

pushd /tmp

tooltool.py \
  --url=http://taskcluster/tooltool.mozilla-releng.net/ \
  --manifest="${MANIFEST}" \
  fetch

popd
