import requests
import filecmp
import shutil
import os
import json
import mimetypes

CONFIG_FILE = "./firefox-ios/Client/Assets/RemoteSettingsData/RemoteSettingsFetchConfig.json"
RS_DATA_PATH = "./firefox-ios/Client/Assets/RemoteSettingsData/"
GITHUB_ACTIONS_TMP_PATH = f"{RS_DATA_PATH}tmp/"

def fetch(url):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response
    except requests.exceptions.RequestException as e:
        print(f"Failed to fetch data from {url}: {e}")
        return None

def save_content(file_content, file_path, file_mimetype = None):
    if file_mimetype == "application/json":
        mode, data = 'w', json.dumps(file_content, indent=4)
    else:
        mode, data = 'w', str(file_content)
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    with open(file_path, mode) as file:
        file.write(data)
    print(f"Saved file: {file_path}")

def replace_file_with_dirs(tmp_file_path, target_file_path):
    # Ensure the parent directory of the target path exists
    target_dir = os.path.dirname(target_file_path)
    os.makedirs(target_dir, exist_ok=True)
    # Replace the file
    os.replace(tmp_file_path, target_file_path)


def update_settings_file(tmp_file_path, target_file_path, name):
    if os.path.exists(target_file_path):
        if filecmp.cmp(tmp_file_path, target_file_path):
            print(f"No changes detected for {name}.")
            os.remove(tmp_file_path)
            return False
        else:
            replace_file_with_dirs(tmp_file_path, target_file_path)
            print(f"Updated {target_file_path} with new rules for {name}.")
            return True
    else:
        replace_file_with_dirs(tmp_file_path, target_file_path)
        print(f"Created new rules file {target_file_path} for {name}.")
        return True


def fetch_records_attachments(records, collection, base_url):
    changes_detected = False
    for record in records:
        attachment = record.get("attachment", None)
        if attachment:
            attachment_subdir =  os.path.join("attachments", collection["collection_id"])
            attachment_extension = mimetypes.guess_extension(attachment["mimetype"])
            attachment_file_name = f"{record['name']}{attachment_extension}"
            attachment_file_tmp_path = os.path.join(GITHUB_ACTIONS_TMP_PATH, attachment_subdir, attachment_file_name)
            attachment_file_path = os.path.join(RS_DATA_PATH, attachment_subdir, attachment_file_name)
            attachment_url = f"{base_url}{attachment['location']}"
            attachment_content = fetch(attachment_url).text

            if attachment_content:
                save_content(attachment_content, attachment_file_tmp_path)
                if update_settings_file(attachment_file_tmp_path, attachment_file_path, record['name']):
                    changes_detected = True
    return changes_detected

def main():
    if not os.path.exists(GITHUB_ACTIONS_TMP_PATH):
        os.makedirs(GITHUB_ACTIONS_TMP_PATH, exist_ok=True)
    
    with open(CONFIG_FILE, 'r') as config_file:
        config = json.load(config_file)

    changes_detected = False

    for collection in config["collections"]:
        print(f"Fetching rules for {collection['name']} from {collection['url']}")
        records_url = f"{collection['url']}/buckets/{collection['bucket_id']}/collections/{collection['collection_id']}/records"
        response = fetch(records_url).json()
        records = response.get("data", None)

        # If no records found, skip to next collection
        if not records:
            print(f"No records found for {collection['name']}.")
            continue

        # Fetch attachments only if config has `fetch_attachments` is True
        # 1. Get base url from the server url = .capabilities.attachments.base_url
        # 2. For each record if it has an .attachment, fetch it = base_url + attachment.location.url
        # 3. Use record.name as the file name = record.name + type of attachment ( from mimetype )
        # 4. Save attachments in attachments/{collection_id}
        fetch_attachments = collection.get("fetch_attachments", False)
        base_url = None
        if fetch_attachments:
            base_url = (
                fetch(collection["url"])
                .json()
                .get("capabilities", {})
                .get("attachments", {})
                .get("base_url", None)
            )

            if not base_url:
                print(f"Attachment base URL not found for {collection['url']}")
                continue
            changes_detected |= fetch_records_attachments(records, collection, base_url)

        # Don't save records if config has `save_records` set to False
        save_records = collection.get("save_records", True)
        if save_records:
            tmp_file_path = os.path.join(GITHUB_ACTIONS_TMP_PATH, os.path.basename(collection["file"]))
            save_content(records, tmp_file_path, "application/json")
            if update_settings_file(tmp_file_path, collection["file"], collection["name"]):
                changes_detected = True

    if not changes_detected:
        print("No changes detected in any collections.")

if __name__ == "__main__":
    main()
