import requests
import filecmp
import shutil
import os
import json

CONFIG_FILE = "./firefox-ios/Client/Assets/RemoteSettingsData/RemoteSettingsFetchConfig.json"
GITHUB_ACTIONS_PATH = "./firefox-ios/Client/Assets/RemoteSettingsData/"
GITHUB_ACTIONS_TMP_PATH = f"{GITHUB_ACTIONS_PATH}tmp/"

def fetch_rules(url):
    response = requests.get(url)
    if response.status_code == 200:
        return response.json()["data"]
    else:
        print(f"Failed to fetch rules from {url}: {response.status_code}")
        return None

def save_tmp_rules(rules, tmp_file_path):
    with open(tmp_file_path, 'w') as tmp_file:
        json.dump(rules, tmp_file, indent=4)
    print(f"Saved temporary rules to {tmp_file_path}")

def update_settings_file(tmp_file_path, target_file_path, name):
    if os.path.exists(target_file_path):
        if filecmp.cmp(tmp_file_path, target_file_path):
            print(f"No changes detected for {name}.")
            os.remove(tmp_file_path)
            return False
        else:
            os.replace(tmp_file_path, target_file_path)
            print(f"Updated {target_file_path} with new rules for {name}.")
            return True
    else:
        os.replace(tmp_file_path, target_file_path)
        print(f"Created new rules file {target_file_path} for {name}.")
        return True

def main():
    if not os.path.exists(GITHUB_ACTIONS_TMP_PATH):
        os.makedirs(GITHUB_ACTIONS_TMP_PATH, exist_ok=True)
    
    with open(CONFIG_FILE, 'r') as config_file:
        config = json.load(config_file)
    
    changes_detected = False
    
    for rule in config["rules"]:
        print(f"Fetching rules for {rule['name']} from {rule['url']}")
        rules = fetch_rules(rule["url"])
        if rules:
            tmp_file_path = os.path.join(GITHUB_ACTIONS_TMP_PATH, os.path.basename(rule["file"]))
            save_tmp_rules(rules, tmp_file_path)
            if update_settings_file(tmp_file_path, rule["file"], rule["name"]):
                changes_detected = True
    
    if not changes_detected:
        print("No changes detected in any rules.")

if __name__ == "__main__":
    main()
