import io
import pandas as pd
import re
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
import sys

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
    session = requests.Session()
    retries = Retry(
        total=CONFIG["RETRIES"],
        backoff_factor=CONFIG["BACKOFF_FACTOR"],
        status_forcelist=CONFIG["STATUS_FORCELIST"],
    )
    session.mount("http://", HTTPAdapter(max_retries=retries))
    session.mount("https://", HTTPAdapter(max_retries=retries))

    response = session.get(url)
    if response.status_code == 200:
        return response.content.decode("utf-8")
    else:
        raise Exception(f"Failed to download CSV: {response.status_code}")


def parse_uri_csv(csv_content):
    df = pd.read_csv(io.StringIO(csv_content))
    filtered_df = df[
        (df["Status"] == "Permanent")
        & (~df["URI Scheme"].str.contains("OBSOLETE", na=False))
    ]
    return filtered_df["URI Scheme"].dropna().sort_values().tolist()


def update_swift_file(new_urischemes, swift_file_path):
    start_index, end_index = find_uris_section_indices(swift_file_path)
    with open(swift_file_path, "r") as file:
        lines = file.readlines()

    new_lines = ['    "{}",\n'.format(scheme) for scheme in new_urischemes]
    # end_index needs to be non-inclusive otherwise the trailing list bracket
    # will be removed when updated list is shorter than before
    updated_lines = lines[:start_index] + new_lines + lines[end_index - 1 :]
    with open(swift_file_path, "w") as file:
        file.writelines(updated_lines)


def find_uris_section_indices(swift_file_path):
    start_index = -1
    end_index = -1

    with open(swift_file_path, "r") as file:
        for i, line in enumerate(
            file, start=1
        ):  # Use enumerate to iterate with 1-based index
            if "private let permanentURISchemes" in line and start_index == -1:
                start_index = i
                continue
            if start_index != -1 and "]" in line:
                end_index = i
                break

    if start_index == -1 or end_index == -1:
        raise Exception(
            "Could not find the 'permanentURISchemes' array in the Swift file."
        )
    return start_index, end_index


def extract_current_uris(swift_file_path):
    # start/end use 1-based index for true line number
    start_line, end_line = find_uris_section_indices(swift_file_path)
    uris = []
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
    return uris


def main():
    csv_url = CONFIG["URI_WEBSITE"]
    swift_file_path = f'{CONFIG["IOS_URI_PATH"]}/{CONFIG["IOS_URIS_FILE"]}'

    try:
        uri_response_csv = get_uri_csv_with_retries(csv_url)
        permanent_urischemes = parse_uri_csv(uri_response_csv)
        current_uris = extract_current_uris(swift_file_path)
        uri_diff = [uri for uri in permanent_urischemes if uri not in set(current_uris)]

        if uri_diff:
            print(f"Updating URIs with diff: {uri_diff}")
            update_swift_file(permanent_urischemes, swift_file_path)
        else:
            print(
                "No update needed. Swift file already contains the latest permanent URI schemes."
            )
    except Exception as e:
        print(f"Error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
