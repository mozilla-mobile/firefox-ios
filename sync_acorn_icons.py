import requests
import json
import os
import re
import shutil
import subprocess

"""
This script automates the process of fetching, syncing, and organizing Acorn icons for the Firefox iOS project.
It performs the following tasks:
1. Fetches the latest release of the Acorn icons repository from GitHub.
2. Saves the latest release information locally to detect if a new release needs to be synced.
3. Downloads the icons from the latest release and synchronizes them with the project's asset folders (see `ASSET_FOLDER_PATHS`).
4. Sorts icons into categories based on their size (e.g., ExtraSmall, Small, Large, etc.).
5. Generates the StandardImageIdentifiers.swift from BrowserKit's Common package.

Important:
- If a new size needs to be added, modify the `TARGET_SIZES` list by adding the appropriate tuple item.
  The tuple is composed of:
  - The first item: the directory name where the Acorn icons for that size are stored (e.g., for the "ExtraSmall" category, 
    the icons are stored in `mobile/8`).
  - The second item: the size category used in the file names and in the `StandardImageIdentifiers.swift` structures (e.g., "ExtraSmall").

Usage:
- This script is designed to be run periodically by a Github action.
- It will automatically detect and download new releases, update the asset folder, and regenerate the image identifiers.

If you want to test the script locally make sure to have all the required packages installed and remove the root json file `latest_acorn_release.json`.
Then run `python3 sync_acorn_icons.py`. All the time the script is run the `latest_acorn_release.json` is created so if you see nothing in the console
remove this file first.
"""

# List the target sizes that now are supported from FXIOS
# Only those sizes are synced for updates.
TARGET_SIZES = [
    ("8", "ExtraSmall"),
    ("16", "Small"),
    ("20", "Medium"),
    ("24", "Large"),
    ("30", "ExtraLarge"),
    ("72", "ExtraExtraExtraLarge")
]

# Asset catalogs kept in sync with Acorn.
ASSET_FOLDER_PATHS = [
    "firefox-ios/Client/Assets/Images.xcassets/",
    "firefox-ios/CredentialProvider/CredentialAssets.xcassets/",
    "firefox-ios/Extensions/ShareTo/Images.xcassets/",
    "firefox-ios/WidgetKit/Assets.xcassets/"
]

def fetch_latest_release_from_acorn() -> dict|None:
    owner = "FirefoxUX" 
    repo = "acorn-icons"    
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    try:
        response = requests.get(url=url)
        if response.status_code == 200:
            return response.json()
    except Exception as e:
        print(f"It was not possible to retrieve the latest acorn release.\nerror: {e}")
        exit()
    
def save_latest_release_if_needed(data: dict) -> bool:
    '''
    Saves the latest release object if needed.

    :returns bool: True if a new release has been deteceted, otherwise False
    '''
    file_path = "latest_acorn_release.json"
    if not os.path.exists(file_path):
        with open(file_path, "w"):
            pass
        
    file = open(file_path, "r+")
    should_fetch_new_icons = False
    if not file.read():
        json.dump(data, fp=file, indent=4)
        should_fetch_new_icons = True
    else:
        file.seek(0)
        latest_fetched_id = data["id"]
        saved_id = json.load(file)["id"]
        if latest_fetched_id > saved_id:
            # new release has to be fetched
            with open(file_path, "w") as file:
                json.dump(data, fp=file, indent=4)
                should_fetch_new_icons = True
    file.close()
    return should_fetch_new_icons

def download_icons_and_save_in_assets():
    temp_dir_folder_name = "temp_dir"
    os.makedirs(temp_dir_folder_name, exist_ok=True)
    os.chdir(temp_dir_folder_name)
    clone_response = subprocess.run(["git", "clone", "https://github.com/FirefoxUX/acorn-icons"])
    if clone_response.returncode != 0:
        print(f"Couldn't clone acorn icon repository")
        exit()
    asset_folders = [(f"../{path}", os.listdir(f"../{path}")) for path in ASSET_FOLDER_PATHS]
    sizes_to_copy = map(lambda x: x[0], TARGET_SIZES)
    for size in sizes_to_copy:
        icons_dir_path = f"acorn-icons/icons/mobile/{size}/pdf"
        directory_tree = os.walk(icons_dir_path)

        for dir_object in directory_tree:
            for file in dir_object[2]:
                icon_path = os.path.join(dir_object[0], file)
                folder_name = f"{os.path.splitext(file)[0]}.imageset".replace("Dark", "").replace("Light", "")

                for asset_folder_path, asset_folder_list in asset_folders:
                    asset_file_path = f"{asset_folder_path}{folder_name}/{file}"
                    # file has to be a pdf and we need the file already present in the images folder
                    # the file need to be already in the asset folder, no different file can be added
                    if file.endswith(".pdf") and folder_name in asset_folder_list and os.path.exists(asset_file_path):
                        destination_folder = os.path.join(asset_folder_path, folder_name)
                        os.makedirs(destination_folder, exist_ok=True)

                        destination_file = os.path.join(destination_folder, file)
                        shutil.copy(icon_path, destination_file)
    
    os.chdir("..")
    subprocess.run(["rm", "-rf", temp_dir_folder_name])

def sort_icons_by_size() -> dict:
    '''
    Sort all the Acorns icons found in ASSET_FOLDER_PATHS by their respective size.
    Icons shared between several asset catalogs are only listed once.

    Returns:
        dict: A dictionary with the title sizes as key and as value the list of acorn folders with the respective size
        {
            "ExtraSmall": [],
            "Small": [],
            ...
        }
    '''
    # regular expression to check for camel case format starting with lowercase char i.e crossCircleFill
    lower_camel_case_pattern = re.compile(r"^[a-z][a-zA-Z0-9]*$")

    icons_by_size = {}
    for _, titleSize in TARGET_SIZES:
        icons_by_size[titleSize] = []

    seen_icons = set()
    for asset_folder_path in ASSET_FOLDER_PATHS:
        for folder in sorted(os.listdir(asset_folder_path)):
            if not folder.endswith(".imageset"):
                continue

            file_name = folder.split(".")[0]
            if file_name in seen_icons:
                continue
            seen_icons.add(file_name)

            # Longest match wins so that sizes sharing a suffix (Large, ExtraLarge,
            # ExtraExtraExtraLarge) resolve to the most specific one
            size_key = max((key for key in icons_by_size if key in file_name), key=len, default=None)
            if not size_key:
                continue

            icon_name = file_name.replace(size_key, "")
            # Check wheter the icon_name is in lower camel case format otherwise the name is not a valid swift name for an acorn icon.
            if not lower_camel_case_pattern.match(icon_name):
                print(f"Skipping {folder}, \"{icon_name}\" is not lowerCamelCase")
                continue

            icons_by_size[size_key].append((icon_name, file_name))

    return icons_by_size

def generate_standard_image_identifiers_swift(sorted_icons: dict):
    swift_file_content = """// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This struct defines all the standard image identifiers of icons and images used in the app.
/// When adding new identifiers, please respect alphabetical order.
/// Sing the song if you must.
public struct StandardImageIdentifiers {
"""
    size_struct_map = {}
    for image_size, image_size_title in TARGET_SIZES:
        size_struct_map[image_size_title] = f"{image_size}x{image_size}"

    struct_blocks = []
    for size, struct_name in size_struct_map.items():
        if sorted_icons[size]:
            block = f"    // Icon size {struct_name}\n"
            block += f"    public struct {size} {{\n"

            # Sort icons alphabetically and add them to the struct
            for icon_info in sorted(sorted_icons[size], key=lambda x: x[0].lower()):
                block += f"        public static let {icon_info[0]} = \"{icon_info[1]}\"\n"

            block += "    }\n"
            struct_blocks.append(block)

    swift_file_content += "\n".join(struct_blocks)
    swift_file_content += "}\n"

    standard_image_file_path = "BrowserKit/Sources/Common/Constants/StandardImageIdentifiers.swift"
    with open(standard_image_file_path, "w") as swift_file:
        swift_file.write(swift_file_content)

def main():
    latest_release = fetch_latest_release_from_acorn()
    if latest_release:
        should_download_icons = save_latest_release_if_needed(latest_release)
        if should_download_icons:
            download_icons_and_save_in_assets()
            sorted_icons = sort_icons_by_size()
            generate_standard_image_identifiers_swift(sorted_icons)

main()