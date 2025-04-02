#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Glean SDK metrics build script.
#
# More about Glean at https://mozilla.github.io/glean
#
# This script generates metrics and pings as defined in user-provided files
# and generates Swift code to be included in the final build.
# It uses the `glean_parser`.
# See https://mozilla.github.io/glean_parser/ for details.
#
# To use it in a Swift project, follow these steps:
# 1. Import the `sdk_generator.sh` script into your project.
# 2. Add your `metrics.yaml` and (optionally) `pings.yaml` and `tags.yaml` to your project.
# 3. Add a new "Run Script" build step and set the command to `bash $PWD/sdk_generator.sh`
# 4. Add your definition files (`metrics.yaml`, `pings.yaml`, `tags.yaml`) as Input Files for the "Run Script" step.
# 5. Run the build.
# 6. Add the files in the `Generated` folder to your project.
# 7. Add the same files from the `Generated` folder as Output Files of the newly created "Run SCript" step.
# 8. Start using the generated metrics.

set -e

MIN_GLEAN_PARSER_VERSION=16.1

# CMDNAME is used in the usage text below.
# shellcheck disable=SC2034
CMDNAME=$(basename "$0")
USAGE=$(cat <<'HEREDOC'
$(CMDNAME)
Glean Team <glean-team@mozilla.com>

Glean SDK metrics build script.

More about Glean at https://mozilla.github.io/glean

This script generates metrics and pings as defined in user-provided files
and generates Swift code to be included in the final build.
It uses the `glean_parser`.
See https://mozilla.github.io/glean_parser/ for details.

This script should be executed as a "Run Build Script" phase from Xcode.

USAGE:
    ${CMDNAME} [OPTIONS] [PATH ...]

ARGS:
    <PATH>...  Explicit list of definition files to parse.
               If not specified the plugin will use the \$SCRIPT_INPUT_FILE_{N} environment variables.

OPTIONS:
    -a, --allow-reserved               Allow reserved names.
    -o, --output  <PATH>               Folder to place generated code in. Default: \$SOURCE_ROOT/\$PROJECT/Generated
    -g, --glean-namespace <NAME>       The Glean namespace to use in generated code.
    -m, --markdown <PATH>              Generate markdown documentation in provided directory.
    -b, --build-date <TEXT>            Set a specific build date or disable build date generation with `0`.
        --expire-by-version <INTEGER>  Expire metrics by version, with the provided major version.
    -h, --help                         Display this help message.
HEREDOC
)

helptext() {
    echo "$USAGE"
}

declare -a PARAMS=()
ALLOW_RESERVED=""
GLEAN_NAMESPACE=Glean
DOCS_DIRECTORY=""
BUILD_DATE=""
EXPIRE_VERSION=""
declare -a YAML_FILES=()
OUTPUT_DIR="${SOURCE_ROOT}/${PROJECT}/Generated"

while (( "$#" )); do
    case "$1" in
        -a|--allow-reserved)
            ALLOW_RESERVED="--allow-reserved"
            shift
            ;;
        -o|--output)
            OUTPUT_DIR=$2
            shift 2
            ;;
        -g|--glean-namespace)
            GLEAN_NAMESPACE=$2
            shift 2
            ;;
        -m|--markdown)
            DOCS_DIRECTORY=$2
            shift 2
            ;;
        -b|--build-date)
            BUILD_DATE="--option build_date=$2"
            shift 2
            ;;
        --expire-by-version)
            EXPIRE_VERSION="--expire-by-version $2"
            shift 2
            ;;
        -h|--help)
            helptext
            exit 0
            ;;
        --) # end argument parsing
            shift
            break
            ;;
        --*=|-*) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *) # preserve positional arguments
            PARAMS+=("$1")
            shift
            ;;
    esac
done

if [ "$ACTION" = "indexbuild" ]; then
  echo "Skipping code generation in 'indexbuild' build. See https://bugzilla.mozilla.org/show_bug.cgi?id=1744504 for more info."
  exit 0
fi

if [ "${#PARAMS[@]}" -gt 0 ]; then
    YAML_FILES=("${PARAMS[@]}")
else
    if [ -z "$SCRIPT_INPUT_FILE_COUNT" ] || [ "$SCRIPT_INPUT_FILE_COUNT" -eq 0 ]; then
        echo "warning: No input files specified."
        exit 0
    fi

    for i in $(seq 0 $((SCRIPT_INPUT_FILE_COUNT - 1))); do
        infilevar="SCRIPT_INPUT_FILE_${i}"
        infile="${!infilevar}"
        YAML_FILES+=("${infile}")
    done
fi

if [ -z "$SOURCE_ROOT" ]; then
    echo "Error: No \$SOURCE_ROOT defined."
    echo "Execute this script as a build step in Xcode."
    exit 2
fi

if [ -z "$PROJECT" ]; then
    echo "Error: No \$PROJECT defined."
    echo "Execute this script as a build step in Xcode."
    exit 2
fi

VENVDIR="${SOURCE_ROOT}/.venv"

[ -x "${VENVDIR}/bin/python" ] || python3 -m venv "${VENVDIR}"
# We need at least pip 20.3 for Big Sur support, see https://pip.pypa.io/en/stable/news/#id48
# Latest pip is 21.0.1
pip_version=$("${VENVDIR}/bin/pip" -V | grep "\d\d.\d" -o)
min_pip_version="20.3"

echo "Current pip version: $pip_version"
if (( $(echo "$pip_version < $min_pip_version" | bc -l ) )); then
    "${VENVDIR}/bin/pip" install "pip>=$min_pip_version"
fi

glean_parser_version=$("${VENVDIR}/bin/pip" freeze | grep "glean_parser" | grep "\d\d.\d" -o || echo "0.0")
echo "Current glean parser version: $glean_parser_version"

if (( $(echo "$glean_parser_version < $MIN_GLEAN_PARSER_VERSION" | bc -l) )); then
    "${VENVDIR}/bin/pip" install --upgrade "glean_parser~=$MIN_GLEAN_PARSER_VERSION"
fi

# Run the glinter
# Turn its warnings into warnings visible in Xcode (but don't do for the success message)
"${VENVDIR}"/bin/python -m glean_parser \
    glinter \
    $ALLOW_RESERVED \
    "${YAML_FILES[@]}" 2>&1 \
    | sed 's/^\(.\)/warning: \1/'  \
    | sed '/Your metrics are Glean/s/^warning: //'

PARSER_OUTPUT=$("${VENVDIR}"/bin/python -m glean_parser \
    translate \
    -f "swift" \
    -o "${OUTPUT_DIR}" \
    -s "glean_namespace=${GLEAN_NAMESPACE}" \
    $BUILD_DATE \
    $EXPIRE_VERSION \
    $ALLOW_RESERVED \
    "${YAML_FILES[@]}" 2>&1) || { echo "$PARSER_OUTPUT"; echo "error: glean_parser failed. See errors above."; exit 1; }

if [ -n "$DOCS_DIRECTORY" ]; then
    "${VENVDIR}"/bin/python -m glean_parser \
        translate \
        -f "markdown" \
        -o "${DOCS_DIRECTORY}" \
        $ALLOW_RESERVED \
        "${YAML_FILES[@]}"
fi

exit 0
