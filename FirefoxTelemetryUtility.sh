#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# Usage:
# This script automatically updates the `glean_index.yaml` and `gleanProbes.xcfilelist` files
# with paths to the metric YAML files currently located in the Firefox for iOS `Client/Glean/probes`
# subdirectory.
#
# This script can also help you add a metrics YAML for a new feature you are working on.
#
# OPTIONS:
#
# --update:              Simply run the script with this flag to update the `glean_index.yaml` and
#                        `gleanProbes.xcfilelist` files with file paths for any manually added metrics
#                        files in the `Client/Glean/probes` directory.
#
# --add featureName:     Creates a new metrics YAML file `feature_name.yaml`, adds it to the
#                        `Client/Glean/probes` folder, and appends the new filepath to the
#                        `glean_index.yaml` index and the `gleanProbes.xcfilelist` file list.
#
#                        The parameter should be the name the new feature or component. Please write
#                        the name in camelCase.
#
#                        A tag of `FeatureName` will automatically be added to the top of the newly
#                        created metrics file. This tag and an accompanying description should be
#                        manually added to the tags.yaml file by the developer. (FXIOS-12432 will make
#                        this process automatic in the future)
#

##############################################################################
# Global Constants
##############################################################################
readonly GLEAN_INDEX_FILE='firefox-ios/Client/Glean/glean_index.yaml'
readonly PATH_TO_FEATURE_YAMLS='firefox-ios/Client/Glean/probes'
readonly FEATURE_YAMLS="$PATH_TO_FEATURE_YAMLS/*.yaml"
readonly XCODE_INFILE_LIST='firefox-ios/Client/Glean/gleanProbes.xcfilelist'
readonly DOCUMENTATION_WARNING='Please see the documentation in the script.'

# Eventually we'll want to include metrics files from other targets in a better way
readonly PATH_TO_STORAGE_METRICS_YAML='firefox-ios/Storage/metrics.yaml'

##############################################################################
# Prints to file the YAML-formatted file paths to all the metrics files in the Glean/probes subdirectory.
# Globals:
#   FEATURE_YAMLS
# Arguments:
#   A path to the output file.
# Returns:
#   Writes output to the file path in argument 1 and debug logs to stdout.
##############################################################################
function append_paths_to_probe_index() {
    echo 'Appending the following metrics files to the Glean index:'

    # Append the Client target's metrics files
    for filename in $FEATURE_YAMLS; do
        echo " * ${filename}"

        # Write this path to the file passed in as argument 1
        relativeName="${filename}"
        echo "  - $relativeName" >>"$1"
    done

    # Append the Storage target's metrics file
    echo " * ${PATH_TO_STORAGE_METRICS_YAML}"
    echo "  - $PATH_TO_STORAGE_METRICS_YAML" >>"$1"
}

##############################################################################
# Removes everything in the probe index file after the `metrics_files:` YAML heading.
# Globals:
#   GLEAN_INDEX_FILE
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function clear_probe_index_file() {
    # Pass empty string to -i to do an in-place replacement without any backup file
    sed -i '' '/metrics_files:/q' $GLEAN_INDEX_FILE
}

##############################################################################
# Entirely deletes the contents of a file.
# Globals:
#   None
# Arguments:
#   $1 : The file to clear.
# Returns:
#   None
##############################################################################
function clear_file_contents() {
    sed -i '' d "$1"
}

##############################################################################
# Converts the given camelCase string to snake_case.
# Globals:
#   None
# Arguments:
#   $1 : The camelCase string to convert.
# Returns:
#   Prints to stdout the converted value.
##############################################################################
function convert_camel_case_to_snake_case() {
    echo "$1" | sed -r 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]'
}

##############################################################################
# Creates a new metrics file for the given component.
# Globals:
#   None
# Arguments:
#   $1 : The camelCase name of the component for which to create a metrics file.
# Returns:
#   Prints the new file path to stdout.
##############################################################################
function create_file_for_component() {
    component_file_name=$(convert_camel_case_to_snake_case "$component_name")

    new_file="$PATH_TO_FEATURE_YAMLS/$component_file_name.yaml"
    touch "$new_file"

    echo "$new_file"
}

##############################################################################
# Clears the metrics files from the glean index file and rewrites them again fresh.
# Globals:
#   GLEAN_INDEX_FILE
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function update_index_file() {
    clear_probe_index_file
    append_paths_to_probe_index $GLEAN_INDEX_FILE
}

##############################################################################
# Capitalizes the first character in a string.
# Globals:
#   None
# Arguments:
#   $1 : A camelCase name to capitalize to CamelCase.
# Returns:
#   Writes the capitalized string to stdout.
##############################################################################

function capitalized_tag_name() {
    feature_name=$1
    echo "$(tr '[:lower:]' '[:upper:]' <<<"${feature_name:0:1}")${feature_name:1}"
}

##############################################################################
# Prefills a file with a template for a new metrics file related to a feature.
# Globals:
#   None
# Arguments:
#   $1 : The new metrics file
#   $2 : The name of the new feature
# Returns:
#   Writes the metrics YAML template to the file given by $1.
##############################################################################
function write_new_metrics_template() {
    capitalized_tag=$(capitalized_tag_name "$2")

    echo """# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This file defines the metrics that are recorded by the Glean SDK. They are
# automatically converted to Swift code at build time using the \`glean_parser\`
# PyPI package.

# This file is organized (roughly) alphabetically by metric names
# for easy navigation

---
\$schema: moz://mozilla.org/schemas/glean/metrics/2-0-0

\$tags:
  - ${capitalized_tag}

###############################################################################
# Documentation
###############################################################################

# Add your new metrics and/or events here.
""" >"$1"
}

##############################################################################
# Writes the file paths to the Xcode build phase input list for metric YAMLs.
# Globals:
#   XCODE_INFILE_LIST
# Arguments:
#   None
# Returns:
#   Appends to the xcode infile list.
##############################################################################
function write_probe_files_to_file_list() {
    echo "Appending to xcode filelist:"
    echo "# This is an autogenerated file using FirefoxTelemetryUtility.sh" >>$XCODE_INFILE_LIST

    for filename in $FEATURE_YAMLS; do
        echo " * ${filename}"

        # Write this path to the file passed in as argument 1
        prefix="\$(PROJECT_DIR)" # NOTE: We want this to be a string literal since it's an Xcode environment variable, so don't expand!
        relativeName="${filename#firefox-ios/}"
        echo "$prefix/$relativeName" >>$XCODE_INFILE_LIST
    done
}

##############################################################################
# Main
##############################################################################
if [ "$1" == "--add" ]; then
    if [ -z "${2}" ]; then
        echo "$DOCUMENTATION_WARNING"
        exit 1
    else
        component_name=$2

        # Check that the user did not enter the component name in the wrong format
        if echo "$component_name" | grep -q "[_-]"; then
            echo "Please enter a feature name in camelCase (not snake_case or kebab-case)"
            exit 1
        fi

        # Create the new metrics YAML file and populate with a basic template
        capitalized_tag=$(capitalized_tag_name "$component_name")
        new_file=$(create_file_for_component "$component_name")
        write_new_metrics_template "$new_file" "$component_name"
        echo -e "Successfully added file for the $component_name component:\n * $new_file\n"

        # Update the glean index file
        update_index_file
        echo -e "Successfully updated the glean index file.\n"

        # Update the Xcode `Glean SDK Generator Script` build phase input file list
        clear_file_contents $XCODE_INFILE_LIST
        write_probe_files_to_file_list
        echo -e "Successfully updated the xcode build phase infile list.\n"

        # FIXME FXIOS-12432 Could add new tags to the tags.yaml file automatically for users
        echo -e "  [!] Please add your new $capitalized_tag tag to the tags.yaml file with a description. [!]\n"

        exit 0
    fi
elif [ "$1" == "--update" ]; then
    # Update the glean index file
    update_index_file
    echo -e "Successfully updated the glean index file.\n"

    # Update the Xcode `Glean SDK Generator Script` build phase input file list
    clear_file_contents $XCODE_INFILE_LIST
    write_probe_files_to_file_list
    echo -e "Successfully updated the xcode build phase infile list.\n"

    exit 0
elif [ $# -eq 0 ]; then
    echo "No arguments supplied. $DOCUMENTATION_WARNING"
    exit 1
else
    echo "$DOCUMENTATION_WARNING"
    exit 1
fi
