import os
import requests
import re

# Define constants
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # Navigate one level up from "test"
BITRISE_YML = os.path.join(BASE_DIR, "bitrise.yml")
BITRISE_STEPLIB_URL = "https://api.github.com/repos/bitrise-io/bitrise-steplib/contents/steps"

# GitHub Access Token
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")

# Step versions that should NOT be updated
LOCKED_VERSIONS = {
    "git-clone": "6.2"
}

def fetch_latest_version(step_id):
    """Fetch the latest version of a step from the Bitrise Step Library."""
    if step_id in LOCKED_VERSIONS:
        print(f"Skipping update for {step_id}, keeping version {LOCKED_VERSIONS[step_id]}")
        return LOCKED_VERSIONS[step_id]  # Return locked version

    try:
        url = f"{BITRISE_STEPLIB_URL}/{step_id}"
        headers = {"Authorization": f"token {GITHUB_TOKEN}"}
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        items = response.json()
        # Filter out directories that represent versions
        versions = [
            item["name"] for item in items
            if all(c.isdigit() or c == '.' for c in item["name"])
        ]
        if not versions:
            print(f"No valid versions found for step {step_id}.")
            return None
        latest_version = sorted(versions, key=lambda x: list(map(int, x.split('.'))))[-1]
        return latest_version
    except requests.exceptions.RequestException as e:
        print(f"Error fetching latest version for {step_id}: {e}")
        return None

def update_bitrise_yaml():
    """Update outdated steps in the Bitrise YAML file."""
    # Load the existing YAML
    with open(BITRISE_YML, "r") as file:
        content = file.readlines()

    # Placeholder for updated steps
    updated_lines = []
    updated_steps = []

    for line in content:
        match = re.match(r"^\s*-\s*([a-zA-Z0-9\-_]+)@([\d\.]+):", line)
        if match:
            step_id, current_version = match.groups()
            latest_version = fetch_latest_version(step_id)
            if current_version != latest_version:
                updated_steps.append(f"{step_id}: {current_version} -> {latest_version}")
                line = line.replace(f"{step_id}@{current_version}", f"{step_id}@{latest_version}")
        updated_lines.append(line)

    # Write back the updated file
    with open(BITRISE_YML, "w") as file:
        file.writelines(updated_lines)

    if updated_steps:
        print("Updated steps:")
        print("\n".join(updated_steps))
    else:
        print("No updates were necessary.")

if __name__ == "__main__":
    update_bitrise_yaml()
