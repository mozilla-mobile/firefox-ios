#!/usr/bin/env bash
set -euo pipefail
# Uncomment the following line to enable debug mode for troubleshooting
# set -x

# ================================
# Ensure the script runs with Bash
# ================================

# Check if the script is running under Bash
if [ -z "${BASH_VERSION:-}" ]; then
  echo "Re-executing the script with Bash..."
  exec bash "$0" "$@"
fi

# ================================
# Script Parameters Validation
# ================================

# Check if the required parameters are passed
if [ "$#" -lt 4 ]; then
  echo "Usage: ./perform_snapshot_tests.sh <config_file> <environment_file> <results_dir> <scheme>"
  echo "Example: ./perform_snapshot_tests.sh config.json environment.json Results SchemeName"
  exit 1
fi

cd firefox-ios

config_file="$1"
environment_file="$2"  # Fixed environment file path
results_dir="$3"
scheme="$4"

# ================================
# Read Configuration Files
# ================================

# Validate JSON configuration
if ! jq empty "$config_file" >/dev/null 2>&1; then
  echo "Error: Invalid JSON in configuration file."
  exit 1
fi

# Read the devices and test bundles from the JSON configuration file
devices_json=$(jq -c '.devices[]' "$config_file")
tests_json=$(jq -c '.testBundles[]' "$config_file")

# Read all locales into an array
mapfile -t all_locales < <(jq -r '.locales[]' "$config_file")

# Initialize arrays to store device information
device_names=()
orientations=()
os_versions=()
is_defaults=()

default_device_name=""
default_device_os_version=""
default_device_count=0

# Initialize xcodebuild execution counter
xcodebuild_count=0

# ================================
# Collect Device Information
# ================================

# Populate device information arrays and identify the default device
while IFS= read -r device; do
  name=$(echo "$device" | jq -r '.name')
  orientation=$(echo "$device" | jq -r '.orientation')
  os_version=$(echo "$device" | jq -r '.os // empty')
  is_default=$(echo "$device" | jq -r '.isDefaultTestDevice // empty')

  device_names+=("$name")
  orientations+=("$orientation")
  os_versions+=("$os_version")
  is_defaults+=("$is_default")

  if [ "$is_default" == "true" ]; then
    default_device_name="$name"
    default_device_os_version="$os_version"
    default_device_count=$((default_device_count + 1))
  fi
done <<< "$devices_json"

# Validate default device count
if [ "$default_device_count" -eq 0 ]; then
  echo "Error: No default device specified in the configuration (isDefaultTestDevice: true)."
  exit 1
elif [ "$default_device_count" -gt 1 ]; then
  echo "Error: More than one default device specified in the configuration (isDefaultTestDevice: true)."
  exit 1
fi

echo "Default device: $default_device_name"

# Set OS versions to default if missing
for i in "${!device_names[@]}"; do
  if [ -z "${os_versions[$i]}" ] || [ "${os_versions[$i]}" == "null" ]; then
    os_versions[$i]="$default_device_os_version"
  fi
done

# ================================
# Initialize Test Groups
# ================================

# Use associative arrays to map device sets to test classes
declare -A device_set_tests
declare -A device_set_devices

# Function to create a unique key for a device set
create_device_set_key() {
  local devices=("$@")
  IFS=$'\n' sorted_devices=($(printf '%s\n' "${devices[@]}" | sort))
  echo "$(printf '%s|' "${sorted_devices[@]}")" | sed 's/|$//'
}

# Function to sanitize device set key for filenames (if needed)
sanitize_filename() {
  local filename="$1"
  # Replace spaces, parentheses, slashes, and other special characters with underscores
  echo "$filename" | tr ' /()' '_' | tr -cd '[:alnum:]_'
}

# Function to get the test target for a given test class
get_test_target() {
  local test_class="$1"
  # Adjust this function based on your project's test target names
  # For example, if all tests are in the target "EcosiaSnapshotTests"
  echo "EcosiaSnapshotTests"
}

# ================================
# Process Test Bundles and Classes
# ================================

# Loop through each test bundle
while IFS= read -r test_bundle; do
  test_bundle_name=$(echo "$test_bundle" | jq -r '.name')
  test_classes_json=$(echo "$test_bundle" | jq -c '.testClasses[]')

  # Loop through each test class in the test bundle
  while IFS= read -r test_class; do
    class_name=$(echo "$test_class" | jq -r '.name')
    runs_on_device=$(echo "$test_class" | jq -r '.runsOn // empty')
    devices_field=$(echo "$test_class" | jq -r '.devices // empty')
    locales_field=$(echo "$test_class" | jq -r '.locales // empty')

    echo "Processing Test Class: $class_name"

    # Determine the devices this test class should run on
    test_devices=()

    if [ -n "$runs_on_device" ] && [ "$runs_on_device" != "null" ]; then
      # Test class with runsOn specified
      test_device_name="$runs_on_device"
      # Check if test_device_name exists in device_names
      if ! printf '%s\n' "${device_names[@]}" | grep -Fxq "$test_device_name"; then
        echo "Error: The runsOn device '$test_device_name' specified for test class '$class_name' does not exist in the devices list."
        exit 1
      fi
      test_devices+=("$test_device_name")
      echo " - Runs on specified device: $test_device_name"
    else
      # Determine devices from devices_field
      if [ -n "$devices_field" ] && [ "$devices_field" != "null" ]; then
        # Read each device/item in the devices array
        devices_array=()
        while IFS= read -r device_item; do
          devices_array+=("$device_item")
        done < <(echo "$devices_field" | jq -r '.[]')

        devices_specified=()
        orientations_specified=()
        all_devices=false

        # Categorize each item in the devices array
        for device_item in "${devices_array[@]}"; do
          if [ "$device_item" == "all" ]; then
            all_devices=true
            echo " - Includes all devices"
          elif [ "$device_item" == "portrait" ] || [ "$device_item" == "landscape" ]; then
            orientations_specified+=("$device_item")
            echo " - Includes orientation: $device_item"
          else
            # It's a device name
            if ! printf '%s\n' "${device_names[@]}" | grep -Fxq "$device_item"; then
              echo "Error: The device '$device_item' specified in 'devices' for test class '$class_name' does not exist in the devices list."
              exit 1
            fi
            devices_specified+=("$device_item")
            echo " - Includes specific device: $device_item"
          fi
        done

        # Determine test_devices based on 'all' and orientations
        if [ "$all_devices" = true ]; then
          if [ "${#orientations_specified[@]}" -gt 0 ]; then
            # "all" with orientations specified
            echo " - Selecting all devices with specified orientations"
            for i in "${!device_names[@]}"; do
              if [[ " ${orientations_specified[@]} " =~ " ${orientations[$i]} " ]]; then
                test_devices+=("${device_names[$i]}")
                echo "   - Selected Device: ${device_names[$i]}"
              fi
            done
          else
            # "all" without orientations
            echo " - Selecting all devices without orientation filter"
            test_devices=("${device_names[@]}")
          fi
        else
          if [ "${#devices_specified[@]}" -gt 0 ]; then
            if [ "${#orientations_specified[@]}" -gt 0 ]; then
              # Specific devices with orientations
              echo " - Selecting specific devices with specified orientations"
              for device in "${devices_specified[@]}"; do
                for i in "${!device_names[@]}"; do
                  if [ "${device_names[$i]}" == "$device" ] && [[ " ${orientations_specified[@]} " =~ " ${orientations[$i]} " ]]; then
                    test_devices+=("${device_names[$i]}")
                    echo "   - Selected Device: ${device_names[$i]}"
                  fi
                done
              done
            else
              # Specific devices without orientations
              echo " - Selecting specific devices without orientation filter"
              for device in "${devices_specified[@]}"; do
                for i in "${!device_names[@]}"; do
                  if [ "${device_names[$i]}" == "$device" ]; then
                    test_devices+=("${device_names[$i]}")
                    echo "   - Selected Device: ${device_names[$i]}"
                  fi
                done
              done
            fi
          else
            if [ "${#orientations_specified[@]}" -gt 0 ]; then
              # Only orientations specified, which is not allowed
              echo "Error: Only orientations specified in 'devices' for test class '$class_name'. Please specify at least one device."
              exit 1
            else
              # No devices specified, use default device
              test_devices+=("$default_device_name")
              echo " - No devices specified. Using default device: $default_device_name"
            fi
          fi
        fi
      else
        # No devices specified, use default device
        test_devices+=("$default_device_name")
        echo " - No devices specified. Using default device: $default_device_name"
      fi
    fi

    # Handle case where no devices are selected after filtering
    if [ "${#test_devices[@]}" -eq 0 ]; then
      echo "Warning: No devices selected for test class '$class_name'. Skipping this test class."
      continue
    fi

    # Create a unique key for the device set
    device_set_key=$(create_device_set_key "${test_devices[@]}")
    echo " - Device Set Key: $device_set_key"

    # Append the test class to the corresponding device set
    device_set_tests["$device_set_key"]+="$class_name|"
    device_set_devices["$device_set_key"]=$(printf '%s|' "${test_devices[@]}")
    echo " - Appended Test Class '$class_name' to Device Set"
  done <<< "$test_classes_json"
done <<< "$tests_json"

# ================================
# Execute Tests with xcodebuild
# ================================

# Verify all device sets are to be processed
echo "All device_set_keys: ${!device_set_tests[@]}"

# Iterate over each device set group and run xcodebuild
for device_set_key in "${!device_set_tests[@]}"; do
  test_classes_str="${device_set_tests[$device_set_key]}"
  device_set_devices_str="${device_set_devices[$device_set_key]}"

  echo "Processing Device Set: $device_set_key"
  echo " - Test Classes: $test_classes_str"
  echo " - Device Set Devices String: $device_set_devices_str"

  # Split the device set into an array using '|' as delimiter and remove trailing '|'
  IFS='|' read -r -a device_set <<< "${device_set_devices_str}|"

  # Remove the trailing empty element if exists
  if [ -z "${device_set[-1]}" ]; then
    unset device_set[-1]
  fi

  echo " - Device Set Array after Splitting: ${device_set[@]}"

  # Prepare the devices for environment.json with orientation
  devices_json_array=$(for device_name in "${device_set[@]}"; do
    if [ -n "$device_name" ]; then
      # Initialize device_orientation
      device_orientation=""

      # Find index of the device to get orientation
      for i in "${!device_names[@]}"; do
        if [ "${device_names[$i]}" == "$device_name" ]; then
          device_orientation="${orientations[$i]}"
          break
        fi
      done

      # Fallback if orientation is still empty
      if [ -z "$device_orientation" ]; then
        echo "Warning: Orientation not found for device '$device_name'. Defaulting to 'portrait'."
        device_orientation="portrait"
      fi

      # Escape double quotes and backslashes in device_name
      escaped_device_name=$(echo "$device_name" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
      echo "{\"name\": \"$escaped_device_name\", \"orientation\": \"$device_orientation\"}"
    fi
  done | jq -s .)

  echo " - Devices JSON Array: $devices_json_array"

  # Prepare the list of test classes by splitting on '|'
  IFS='|' read -r -a test_classes <<< "${test_classes_str%|}"
  echo " - Test Classes Array: ${test_classes[@]}"

  # Prepare the -only-testing parameters
  only_testing_params=""
  for test_class in "${test_classes[@]}"; do
    test_target=$(get_test_target "$test_class")
    test_identifier="$test_target/$test_class"
    only_testing_params+=" -only-testing \"$test_identifier\""
    echo "   - Adding Only Testing Parameter: $test_identifier"
  done

  # Determine which device to use for xcodebuild
  device_name=""
  for dev in "${device_set[@]}"; do
    if [ "$dev" == "$default_device_name" ]; then
      device_name="$default_device_name"
      break
    fi
  done

  if [ -z "$device_name" ]; then
    # If default device not in the device set, use the first device
    device_name="${device_set[0]}"
    echo " - Default device not in set. Using first device: $device_name"
  else
    echo " - Using Default Device: $device_name"
  fi

  # Get the device name to pass into the env file
  simulator_device_name="$device_name"
  echo " - Simulator Device Name: $simulator_device_name"

  # Overwrite the fixed environment.json with current device set
  locales_json_array=$(printf '%s\n' "${all_locales[@]}" | jq -R . | jq -s .)
  echo " - Locales JSON Array: $locales_json_array"

  echo "{
    \"DEVICES\": $devices_json_array,
    \"LOCALES\": $locales_json_array,
    \"SIMULATOR_DEVICE_NAME\": \"$simulator_device_name\"
  }" > "$environment_file"

  echo " - Environment file created at: $environment_file"
  cat "$environment_file"  # Print the contents of the file for verification

  # Validate the generated environment.json
  if ! jq empty "$environment_file" >/dev/null 2>&1; then
    echo "Error: Generated environment.json ($environment_file) is invalid."
    exit 1
  fi

  # Find index of the device to get OS version
  os_version=""
  for i in "${!device_names[@]}"; do
    if [ "${device_names[$i]}" == "$device_name" ]; then
      os_version="${os_versions[$i]}"
      break
    fi
  done

  echo " - OS Version for Device '$device_name': $os_version"

  # Prepare result path
  # Concatenate test class names
  test_classes_concat=$(printf '%s_' "${test_classes[@]}")
  test_classes_concat=${test_classes_concat%_}  # Remove trailing underscore
  # Sanitize test_classes_concat to remove spaces and special characters
  test_classes_concat=$(echo "$test_classes_concat" | tr ' /' '__')
  result_path="$results_dir/${test_classes_concat}_tests.xcresult"
  mkdir -p "$results_dir"

  echo " - Result Path: $result_path"

  # Prepare the xcodebuild command
  xcodebuild_cmd="xcodebuild test \
    -scheme \"$scheme\" \
    -clonedSourcePackagesDirPath \"SourcePackages/\" \
    -destination \"platform=iOS Simulator,name=$device_name,OS=$os_version\" \
    $only_testing_params \
    -resultBundlePath \"$result_path\""

  echo " - Running xcodebuild Command: $xcodebuild_cmd"

  # Disable 'set -e' temporarily to ensure the script continues even if the test fails
  set +e

  # Run the xcodebuild command
  eval $xcodebuild_cmd

  # Re-enable 'set -e'
  set -e

  # Increment xcodebuild execution counter
  xcodebuild_count=$((xcodebuild_count + 1))
done

# ================================
# Combine Test Results
# ================================

echo "Combining all xcresult files into a single xcresult..."

combined_result_path="$results_dir/all_tests.xcresult"

# Define the Xcode path based on the CI environment variable
if [ "${CI:-false}" = "true" ]; then
    xcresulttool_path="/Applications/Xcode_16.4.app/Contents/Developer/usr/bin/xcresulttool"
else
    xcresulttool_path="/Applications/Xcode.app/Contents/Developer/usr/bin/xcresulttool"
fi

# Verify that xcresulttool exists
if [ ! -x "$xcresulttool_path" ]; then
  echo "Error: xcresulttool not found at $xcresulttool_path"
  exit 1
fi

# Find all xcresult files in the results directory
xcresult_files=($(find "$results_dir" -name "*.xcresult"))

# Check if any xcresult files were found
if [ "${#xcresult_files[@]}" -eq 0 ]; then
  echo "Error: No xcresult files found in $results_dir to combine."
  exit 1
fi

# Check if xcresult is one
if [ "${#xcresult_files[@]}" -eq 1 ]; then
  echo "Only one xcresult file found. Copying to combined result path."
  cp -R "${xcresult_files[0]}" "$combined_result_path"
  echo "Combined xcresult created at: $combined_result_path"
  exit 0
fi

# Merge the xcresult files into one
$xcresulttool_path merge "${xcresult_files[@]}" --output-path "$combined_result_path"

echo "Combined xcresult created at: $combined_result_path"