#!/usr/bin/env python3

import json
import os
import subprocess

device_name = os.environ.get("SIMULATOR_DEVICE", "iPhone 15")
target_ios_version = os.environ.get("IOS_VERSION", "iOS 17.2")
json_version = target_ios_version.replace(" ", "-").replace(".", "-")

# Run xcrun simctl list devices and load the JSON output
output = subprocess.check_output(["xcrun", "simctl", "list", "devices", "--json"])
devices = json.loads(output)

# Filter devices for the specified iOS version
filtered_devices = {}
for runtime, runtime_devices in devices["devices"].items():
    for device in runtime_devices:
        if device["isAvailable"] == True and json_version in runtime and device_name == device["name"]:
            print(device["udid"])
            break
