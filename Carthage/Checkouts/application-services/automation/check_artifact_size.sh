#!/usr/bin/env bash
#
# A simple check that our release .aar files are a reasonable size.
# If this fails then something has gone wrong with the build process,
# such as pulling in unwanted dependencies or failing to strip debug symbols.

set -eu

if [[ "$#" -ne 2 ]]
then
    echo "Usage:"
    echo "./automation/check_artifact_size.sh <buildDir> <artifactId>"
    exit 1
fi

BUILD_DIR="$1"
ARTIFACT_ID="$2"

# Even our largest .aar should be less than 35M.
# Seems like a lot? They include compiled rust code for 4 architectures.
# We expect this size to decrease over time as we make changes to the way
# we perform megazord builds, but at least it's an upper bound for now...
LIMIT=36700160

if [[ -d "${BUILD_DIR}" ]]; then
    while IFS= read -r -d '' AAR_FILE; do
        SIZE=$(du -b "${AAR_FILE}" | cut -f 1)
        if [[ "${SIZE}" -gt "${LIMIT}" ]]; then
            echo "ERROR: Build artifact is unacceptably large." >&2
            du -h "${AAR_FILE}" >&2
            exit 1
        fi
    done <   <(find "${BUILD_DIR}" -path "*/${ARTIFACT_ID}/*" -name "*.aar" -print0)
fi
