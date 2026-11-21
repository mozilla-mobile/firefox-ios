#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Adapted from nimbus-fml.sh
# https://github.com/mozilla/application-services/blob/main/components/nimbus/ios/scripts/nimbus-fml.sh

set -xeuo pipefail

function download() {
    local url="${1}"
    local path="${2}"

    curl --proto '=https' --tlsv1.2 -f -L "${url}" -o "${path}"
}

function download_fml() {
    local nimbus_fml="${1}"
    local nimbus_fml_dir="$(dirname "${nimbus_fml}")"

    local package_swift_path="MozillaRustComponents/Package.swift"
    local raw_version=$(grep "let version =" "$package_swift_path" | grep -oE "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+")
    local patch=${raw_version##*.}

    local as_version=${raw_version//\.0\./\.}
    local as_artifacts_url="https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.nimbus-fml.${as_version}/artifacts/public%2Fbuild%2F"

    download "${as_artifacts_url}nimbus-fml.zip" "${nimbus_fml}.zip"
    download "${as_artifacts_url}nimbus-fml.sha256" "${nimbus_fml}.sha256"

    pushd "${nimbus_fml_dir}"
    shasum --check nimbus-fml.sha256
    popd

    local triple
    case "$(uname -m):$(uname)" in
        arm64:Darwin)
            triple="aarch64-apple-darwin"
            ;;
        arm64:Linux)
            triple="aarch64-unknown-linux-gnu"
            ;;
        x86_64:Darwin)
            triple="x86_64-apple-darwin"
            ;;
        x86_64:Linux)
            triple="x86_64-unknown-linux-musl"
            ;;
        *)
            echo "Unsupported architecture/OS $(uname -a)" >&2
            exit 1
            ;;
    esac

    unzip -o -j "${nimbus_fml}.zip" -d "${nimbus_fml_dir}" "${triple}/release/nimbus-fml"
}

TEMP=$(mktemp -d)
NIMBUS_FML="${TEMP}/nimbus-fml"

download_fml "${NIMBUS_FML}"

"${NIMBUS_FML}" lint ./firefox-ios/nimbus.fml.yaml
