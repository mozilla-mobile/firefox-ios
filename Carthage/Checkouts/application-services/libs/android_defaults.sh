#!/usr/bin/env bash

if [[ -z "${ANDROID_NDK_API_VERSION:-}" ]]; then
    export ANDROID_NDK_API_VERSION=21
    echo "The ANDROID_NDK_API_VERSION env variable is not set. Defaulting to ${ANDROID_NDK_API_VERSION}"
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
    export NDK_HOST_TAG="darwin-x86_64"
elif [[ "$(uname -s)" == "Linux" ]]; then
    export NDK_HOST_TAG="linux-x86_64"
else
    echo "Unsupported OS."
fi
