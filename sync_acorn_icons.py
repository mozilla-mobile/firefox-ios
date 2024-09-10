import requests
import json
import os
import shutil
import subprocess
import json

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

def download_icons_and_save():
    temp_dir_folder_name = "temp_dir"
    os.makedirs(temp_dir_folder_name, exist_ok=True)
    os.chdir(temp_dir_folder_name)
    subprocess.run(["git", "clone", "https://github.com/FirefoxUX/acorn-icons"])

    target_dir_to_copy = [16, 20, 24, 30]
    asset_folder_path = "../firefox-ios/Client/Assets/Images.xcassets/"
    images_list_present = os.listdir(asset_folder_path)
    for dir in target_dir_to_copy:
        dir_path = f"acorn-icons/icons/mobile/{dir}/pdf"
        directory_tree = os.walk(dir_path)

        for dir_object in directory_tree:
            for file in dir_object[2]:
                icon_path = os.path.join(dir_object[0], file)
                folder_name = f"{os.path.splitext(file)[0]}.imageset".replace("Dark", "").replace("Light", "")
                
                # file has to be a pdf and we need the file already present in the images folder
                if file.endswith(".pdf") and folder_name in images_list_present: 
                    destination_folder = os.path.join(asset_folder_path, folder_name)
                    os.makedirs(destination_folder, exist_ok=True)
                    
                    destination_file = os.path.join(destination_folder, file)
                    shutil.copy(icon_path, destination_file)
                    print(f"Copied {file} to {destination_folder} and created Contents.json")
    
    os.chdir("..")
    subprocess.run(["rm", "-rf", temp_dir_folder_name])

def sort_icons_by_size() -> dict:
    icons_by_size: dict[str, list[tuple[str]]] = {
        "Small": [],
        "Medium": [],
        # Extra Large should be before Large since next() method will pick always Large either 
        "ExtraLarge": [],
        "Large": []
    }

    asset_folder_path = "firefox-ios/Client/Assets/Images.xcassets/"
    for folder in os.listdir(asset_folder_path):
        if folder.endswith(".imageset"):
            file_name = folder.split(".")[0]
            
            size_key = next((key for key in icons_by_size if key in file_name), None)
            
            if size_key == "ExtraLarge":
                icon_name = file_name.replace(size_key, "")
                icons_by_size[size_key].append((icon_name, file_name))

    return icons_by_size

def generate_standard_image_identifiers_swift(sorted_icons: dict):
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

    size_struct_map = {
        "Small": "16x16",
        "Medium": "20x20",
        "Large": "24x24",
        "ExtraLarge": "30x30"
    }

    for size, struct_name in size_struct_map.items():
        if sorted_icons[size]:
            swift_file_content += f"    // Icon size {struct_name}\n"
            swift_file_content += f"    public struct {size} {{\n"
            
            # Sort icons alphabetically and add them to the struct
            for icon_info in sorted(sorted_icons[size]):
                swift_file_content += f"        public static let {icon_info[0]} = \"{icon_info[1]}\"\n"
            
            swift_file_content += "    }\n"

    # Closing the main struct
    swift_file_content += "}"

    # Step 4: Write the generated Swift file content to a .swift file
    with open("StandardImageIdentifiers.swift", "w") as swift_file:
        swift_file.write(swift_file_content)


    print("PDF files have been processed and copied with content.json files.")




download_icons_and_save()
sorted_icons = sort_icons_by_size()
generate_standard_image_identifiers_swift(sorted_icons)