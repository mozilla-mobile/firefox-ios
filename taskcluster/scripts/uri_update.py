#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
"""
This script updates the URI schemes in the iOS Swift file based on the latest CSV data from IANA.
It fetches the CSV, parses it for permanent URI schemes, compares them with the existing ones in the Swift file,
and updates the Swift file if there are new or removed URIs.

Usage:
    python uri_update.py
"""


import io
import logging
import re
import sys

import pandas as pd
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s-%(levelname)s: %(message)s")

CONFIG = {
    "URI_WEBSITE": "https://www.iana.org/assignments/uri-schemes/uri-schemes-1.csv",
    "IOS_URI_PATH": "firefox-ios/Shared/Extensions/",
    "IOS_URIS_FILE": "URLExtensions.swift",
    "RETRIES": 2,
    "BACKOFF_FACTOR": 0.3,
    "STATUS_FORCELIST": [500, 502, 503, 504],
}


# use exponential backoff because why not
def get_uri_csv_with_retries(url):
    """
    Fetches the URI CSV from the specified URL with retry logic.

    Parameters:
    - url (str): The URL to fetch the CSV from.

    Returns:
    - str: The content of the CSV file.
    """
    session = requests.Session()
    retries = Retry(
        total=CONFIG["RETRIES"],
        backoff_factor=CONFIG["BACKOFF_FACTOR"],
        status_forcelist=CONFIG["STATUS_FORCELIST"],
    )
    session.mount("http://", HTTPAdapter(max_retries=retries))
    session.mount("https://", HTTPAdapter(max_retries=retries))

    try:
        response = session.get(url)
        response.raise_for_status()
        return response.content.decode("utf-8")
    except Exception as e:
        logging.error(f"Failed to download CSV: {e}")
        sys.exit(1)


def parse_uri_csv(api_response_csv):
    """
    Parses the given CSV content for permanent URI schemes.

    Parameters:
    - api_response_csv (str): The CSV content returned from the api as a string.

    Returns:
    - list: A list of permanent URI schemes.
    """
    df = pd.read_csv(io.StringIO(api_response_csv))
    filtered_df = df[
        (df["Status"] == "Permanent")
        & (~df["URI Scheme"].str.contains("OBSOLETE", na=False))
    ]
    return filtered_df["URI Scheme"].dropna().sort_values().tolist()


def update_swift_file(new_urischemes, swift_file_path):
    """
    Updates the Swift file with new URI schemes.

    Parameters:
    - new_urischemes (list): A list of new URI schemes to update in the Swift file.
    - swift_file_path (str): The file path of the Swift file to update.

    """
    try:
        start_index, end_index = find_uris_section_indices(swift_file_path)

        with open(swift_file_path, "r") as file:
            lines = file.readlines()

        new_lines = [f'    "{scheme}",\n' for scheme in new_urischemes]
        updated_lines = lines[:start_index] + new_lines + lines[end_index - 1 :]

        with open(swift_file_path, "w") as file:
            file.writelines(updated_lines)
    except Exception as e:
        logging.error(f"Failed to update the Swift file: {e}")
        sys.exit(1)


def find_uris_section_indices(swift_file_path):
    """
    Finds the start and end indices of the URI schemes section in the Swift file.

    Parameters:
    - swift_file_path (str): The file path of the Swift file.

    Returns:
    - tuple: A tuple containing the start and end line numbers of the URI schemes section.
    """
    start_index = -1
    end_index = -1

    try:
        with open(swift_file_path, "r") as file:
            # Use enumerate to iterate with 1-based index
            for i, line in enumerate(file, start=1):
                if "private let permanentURISchemes" in line and start_index == -1:
                    start_index = i
                    continue
                if start_index != -1 and "]" in line:
                    end_index = i
                    break
    except Exception as e:
        logging.error(f"An error occurred while reading {swift_file_path}: {e}")
        sys.exit(1)

    if start_index == -1 or end_index == -1:
        logging.error(f"Could not find 'permanentURISchemes' array in the Swift file.")
        sys.exit(1)
    return start_index, end_index


def extract_current_uris(swift_file_path):
    """
    Extracts the current URIs from the Swift file.

    Parameters:
    - swift_file_path (str): The file path of the Swift file.

    Returns:
    - list: A list of URIs extracted from the Swift file.
    """
    # start/end use 1-based index for true line number
    start_line, end_line = find_uris_section_indices(swift_file_path)
    uris = []
    try:
        with open(swift_file_path, "r") as file:
            # use enumerate and start i at 1 for 1-based index
            for i, line in enumerate(file, start=1):
                if start_line <= i <= end_line:
                    # Extract URI between the first pair of double quotes
                    match = re.search(r'"([^"]+)"', line)
                    if match:
                        uris.append(match.group(1))
                elif i == end_line:
                    break
    except Exception as e:
        logging.error(f"An error occurred while reading {swift_file_path}: {e}")
        sys.exit(1)
    return uris


def main():
    logging.info(f"Current CONFIG for task:\n{CONFIG}")
    csv_url = CONFIG["URI_WEBSITE"]
    swift_file_path = f'{CONFIG["IOS_URI_PATH"]}/{CONFIG["IOS_URIS_FILE"]}'

    try:
        uri_response_csv = get_uri_csv_with_retries(csv_url)
        permanent_urischemes = parse_uri_csv(uri_response_csv)
        current_uris = extract_current_uris(swift_file_path)
        uri_diff = [uri for uri in permanent_urischemes if uri not in set(current_uris)]

        if uri_diff:
            logging.info(f"Updating URIs with diff: {uri_diff}")
            update_swift_file(permanent_urischemes, swift_file_path)
        else:
            logging.info("No update needed. File contains latest permanent URISchemes.")
    except Exception as e:
        logging.error(f"Error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
