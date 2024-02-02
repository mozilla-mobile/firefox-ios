#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
"""
This script automates the process of updating icon assets in the Firefox iOS project.
It downloads the latest release of icon assets from the FirefoxUX/acorn-icons repository
on GitHub, extracts the .tar.gz file, and processes the contents to update the icon assets.

The script performs the following steps:
1. Downloads the latest .tar.gz file from the specified GitHub releases page.
2. Extracts the downloaded file and navigates to specific directories (16, 20, 24, 30).
3. For each .pdf file in these directories, creates corresponding .imageset directories,
   copies the PDF files, and generates Contents.json files.
4. Updates the StandardImageIndentifiers.swift file in the project with new constants
   representing these icons, sorted alphabetically and categorized by size (Small, Medium,
   Large, ExtraLarge).

Usage:
Run the script from the root directory of the firefox-ios project. The script requires
internet access to download the assets and depends on the 'requests' Python package.

    python3 /taskcluster/scripts/acorn-icons-update.py
"""

import requests
import tarfile
import os
import re
import json
import shutil

# Constants
GITHUB_RELEASES_URL = "https://api.github.com/repos/FirefoxUX/acorn-icons/releases"
DOWNLOAD_DIR = "./downloads"
EXTRACTED_DIR = "./extracted"
IMAGESET_PATH = "./firefox-ios/Client/Assets/Images.xcassets"
SWIFT_FILE_PATH = (
    "./BrowserKit/Sources/Common/Constants/StandardImageIndentifiers.swift"
)


def download_latest_release():
    response = requests.get(GITHUB_RELEASES_URL)
    releases = response.json()
    latest_release = releases[0] if releases else None
    if not latest_release:
        print("No releases found.")
        return

    tarball_url = latest_release["tarball_url"]
    version_number = latest_release["tag_name"]
    file_name = f"acorn-icons-{version_number}.tar.gz"
    print(f"Downloading {file_name}...")

    tarball_response = requests.get(tarball_url, stream=True)
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)

    file_path = os.path.join(DOWNLOAD_DIR, file_name)
    with open(file_path, "wb") as file:
        for chunk in tarball_response.iter_content(chunk_size=1024):
            file.write(chunk)

    print(f"Downloaded {file_name} to {file_path}.")
    return file_path


def extract_tar_gz(file_path):
    if not os.path.exists(file_path):
        print(f"File {file_path} does not exist.")
        return None

    with tarfile.open(file_path, "r:gz") as tar:
        tar.extractall(path=EXTRACTED_DIR)
        print(f"Extracted {file_path} to {EXTRACTED_DIR}")
    return EXTRACTED_DIR


def find_pdf_directory_with_regex(base_dir, size):
    pattern = re.compile(r"FirefoxUX-acorn-icons-[\da-f]+")
    for dirpath, dirnames, _ in os.walk(base_dir):
        for dirname in dirnames:
            if pattern.match(dirname):
                pdf_dir_path = os.path.join(
                    dirpath, dirname, f"icons/mobile/{size}/pdf"
                )
                if os.path.exists(pdf_dir_path):
                    return pdf_dir_path
    return None


def create_imageset_directories(pdf_dir, size_struct):
    for filename in os.listdir(pdf_dir):
        if filename.endswith(".pdf"):
            imageset_name = filename.replace(".pdf", ".imageset")
            imageset_path = os.path.join(IMAGESET_PATH, imageset_name)
            os.makedirs(imageset_path, exist_ok=True)

            shutil.copy(os.path.join(pdf_dir, filename), imageset_path)

            contents = {
                "images": [{"filename": filename, "idiom": "universal"}],
                "info": {"author": "xcode", "version": 1},
                "properties": {"preserves-vector-representation": True},
            }

            with open(os.path.join(imageset_path, "Contents.json"), "w") as json_file:
                json.dump(contents, json_file, indent=2)


def update_swift_file(pdf_dir, swift_file_path, size_struct):
    # Extracting the pdf names and stripping the size_struct suffix for variable names
    pdf_names = [
        os.path.splitext(f)[0] for f in os.listdir(pdf_dir) if f.endswith(".pdf")
    ]
    variable_names = [name.replace(size_struct, "") for name in pdf_names]
    pdf_names.sort()
    variable_names.sort()

    with open(swift_file_path, "r") as file:
        lines = file.readlines()

    start_index, end_index = None, None
    struct_declaration = f"public struct {size_struct} {{"
    for index, line in enumerate(lines):
        if line.strip() == struct_declaration:
            start_index = index + 1
        elif start_index is not None and line.strip() == "}":
            end_index = index
            break

    if start_index is None or end_index is None:
        print(f"Could not find the '{size_struct}' struct in the Swift file.")
        return

    # Variable name without size suffix, value with size suffix
    new_lines = [
        f'        public static let {var_name} = "{pdf_name}"\n'
        for var_name, pdf_name in zip(variable_names, pdf_names)
    ]
    updated_lines = lines[:start_index] + new_lines + lines[end_index:]

    with open(swift_file_path, "w") as file:
        file.writelines(updated_lines)

    print(f"Swift file updated successfully for {size_struct}.")


def main():
    tar_gz_file_path = download_latest_release()
    if not tar_gz_file_path:
        return

    extracted_dir = extract_tar_gz(tar_gz_file_path)
    if not extracted_dir:
        return

    for size, size_struct in [
        ("16", "Small"),
        ("20", "Medium"),
        ("24", "Large"),
        ("30", "ExtraLarge"),
    ]:
        pdf_directory = find_pdf_directory_with_regex(extracted_dir, size)
        if pdf_directory:
            create_imageset_directories(pdf_directory, size_struct)
            update_swift_file(pdf_directory, SWIFT_FILE_PATH, size_struct)
        else:
            print(f"PDF directory for {size_struct} not found.")


if __name__ == "__main__":
    main()
