import requests
import json
import subprocess
import os
import shutil

def fetch_latest_release_from_acorn() -> dict|None:
    owner = "FirefoxUX" 
    repo = "acorn-icons"    
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    response = requests.get(url=url)
    if response.status_code == 200:
        return response.json()
    
def save_latest_release_if_needed(data: dict) -> bool:
    file = open("latest_acorn_release.json", "r+")
    should_fetch_new_icons = False
    if len(file.read()) == 0:
        json.dump(data, fp=file, indent=4)
        should_fetch_new_icons = True
    else:
        file.flush()
        current_fetched_id = data["id"]
        saved_id = json.load(file)["id"]
        if current_fetched_id == saved_id:
            # new release has to be fetched
            file.truncate(0)
            json.dump(data, fp=file, indent=4)
            should_fetch_new_icons = True
    file.close()
    return should_fetch_new_icons


'''
latest_release_obj = fetch_latest_release_from_acorn()
if latest_release_obj:
    should_fetch_new_release = save_latest_release_if_needed(latest_release_obj)
'''
import os
import shutil
import subprocess
import json

# Step 1: Set up temporary directory and output directory
os.makedirs("temp_dir", exist_ok=True)
os.makedirs("output_icons", exist_ok=True)
os.chdir("temp_dir")
subprocess.run(["git", "clone", "https://github.com/FirefoxUX/acorn-icons"])

# Step 2: Define target directories to copy PDFs from
target_dir_to_copy = [16, 20, 24, 30]
output_folder_path = "../output_icons"

# Step 3: Walk through target directories and process PDF files
for dir in target_dir_to_copy:
    dir_path = f"acorn-icons/icons/mobile/{dir}/pdf"
    
    if os.path.exists(dir_path):
        content = os.walk(dir_path)
        for sub_content in content:
            for file in sub_content[2]:
                if file.endswith(".pdf"):
                    icon_path = os.path.join(sub_content[0], file)
                    
                    # Create folder for the file in output_icons with .imageset suffix
                    folder_name = os.path.splitext(file)[0] + ".imageset"
                    destination_folder = os.path.join(output_folder_path, folder_name)
                    os.makedirs(destination_folder, exist_ok=True)
                    
                    # Copy the PDF file to the new folder
                    destination_file = os.path.join(destination_folder, file)
                    shutil.copy(icon_path, destination_file)
                    
                    # Create the content.json file in the same folder
                    contents_json_file = {
                        "images": [
                            {
                                "filename": file,
                                "idiom": "universal"
                            }
                        ],
                        "info": {
                            "author": "xcode",
                            "version": 1
                        },
                        "properties": {
                            "preserves-vector-representation": True
                        }
                    }
                    
                    # Write the content.json file
                    json_filename = os.path.join(destination_folder, "Contents.json")
                    with open(json_filename, "w") as json_file:
                        json.dump(contents_json_file, json_file, indent=4)
                    
                    print(f"Copied {file} to {destination_folder} and created Contents.json")

# Dictionary to hold the icons by size
icons_by_size = {
    "Small": [],
    "Medium": [],
    "ExtraLarge": [],
    "Large": []
}

# Directory containing the icons
output_icons_dir = "../output_icons"

# Step 1: Iterate through the `.imageset` folders and sort icons by size
for folder in os.listdir(output_icons_dir):
    if folder.endswith(".imageset"):
        # Extract file name (without extension)
        file_name = folder.split(".")[0]
        
        # Dynamically determine the size_key by searching for the key in the folder name
        size_key = next((key for key in icons_by_size if key in file_name), None)
        
        if size_key:
            # Clean up icon name by removing size designators
            icon_name = file_name.replace(size_key, "")
            # Add the cleaned icon name to the corresponding size category
            icons_by_size[size_key].append(icon_name)

# Step 2: Create the Swift file content
swift_file_content = """
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This struct defines all the standard image identifiers of icons and images used in the app.
/// When adding new identifiers, please respect alphabetical order.
/// Sing the song if you must.
public struct StandardImageIdentifiers {
"""

# Step 3: Generate Swift structs for each size category
size_struct_map = {
    "Small": "16x16",
    "Medium": "20x20",
    "Large": "24x24",
    "ExtraLarge": "30x30"
}

for size, struct_name in size_struct_map.items():
    if icons_by_size[size]:
        swift_file_content += f"    // Icon size {struct_name}\n"
        swift_file_content += f"    public struct {size} {{\n"
        
        # Sort icons alphabetically and add them to the struct
        for icon in sorted(icons_by_size[size]):
            swift_file_content += f"        public static let {icon} = \"{icon}\"\n"
        
        swift_file_content += "    }\n"

# Closing the main struct
swift_file_content += "}"

# Step 4: Write the generated Swift file content to a .swift file
with open("../StandardImageIdentifiers.swift", "w") as swift_file:
    swift_file.write(swift_file_content)

print("Swift file 'StandardImageIdentifiers.swift' generated successfully.")

# Step 4: Clean up temporary directory
os.chdir("..")
subprocess.run(["rm", "StandardImageIdentifiers.swift"])
subprocess.run(["rm", "-rf", "output_icons"])
subprocess.run(["rm", "-rf", "temp_dir"])

print("PDF files have been processed and copied with content.json files.")