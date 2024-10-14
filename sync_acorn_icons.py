import requests
import json
import os
import shutil
import subprocess

_TARGET_SIZES = [
    (8, "ExtraSmall"),
    (16, "Small"),
    (20, "Medium"),
    (24, "Large"),
    (30, "ExtraLarge")
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
    asset_folder_path = "../firefox-ios/Client/Assets/Images.xcassets/"
    asset_folder_list = os.listdir(asset_folder_path)
    sizes_to_copy = map(lambda x: x[0], _TARGET_SIZES)
    for size in sizes_to_copy:
        icons_dir_path = f"acorn-icons/icons/mobile/{size}/pdf"
        directory_tree = os.walk(icons_dir_path)

        for dir_object in directory_tree:
            for file in dir_object[2]:
                icon_path = os.path.join(dir_object[0], file)
                folder_name = f"{os.path.splitext(file)[0]}.imageset".replace("Dark", "").replace("Light", "")

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
    icons_by_size = {}
    for _, titleSize in _TARGET_SIZES:
        icons_by_size[titleSize] = []

    asset_folder_path = "firefox-ios/Client/Assets/Images.xcassets/"
    for folder in os.listdir(asset_folder_path):
        if folder.endswith(".imageset"):
            file_name = folder.split(".")[0]
            
            size_key = next((key for key in icons_by_size if key in file_name), None)
            
            if size_key:
                icon_name = file_name.replace(size_key, "")
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
    for image_size, image_size_title in _TARGET_SIZES:
        size_struct_map[image_size_title] = f"{image_size}x{image_size}"

    for size, struct_name in size_struct_map.items():
        if sorted_icons[size]:
            swift_file_content += f"    // Icon size {struct_name}\n"
            swift_file_content += f"    public struct {size} {{\n"
            
            # Sort icons alphabetically and add them to the struct
            for icon_info in sorted(sorted_icons[size], key=lambda x: x[0].lower()):
                swift_file_content += f"        public static let {icon_info[0]} = \"{icon_info[1]}\"\n"
            
            if size == "ExtraLarge":
                swift_file_content += "    }\n"
            else:
                swift_file_content += "    }\n\n"
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