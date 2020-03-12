#!/usr/bin/env python3

# Purpose: Prepare an Application-Services release
# Dependencies: yaml
# Usage: ./automation/prepare-release.py minor

import argparse
from datetime import datetime
import subprocess
import re
import webbrowser
import yaml

from shared import step_msg, fatal_err, run_cmd_checked, ensure_working_tree_clean

parser = argparse.ArgumentParser(description="Prepares an application-services release "
                                             "(increment versions, write changelog, send PR to GitHub).")
parser.add_argument("release_type",
                    choices=["major", "minor", "patch"],
                    help="The release type to be done. See https://semver.org/ for guidance.")
parser.add_argument("--base-branch",
                    default="master",
                    help="The branch to make a release from. Default is master.")
parser.add_argument("--remote",
                    default="origin",
                    help="The remote name that corresponds to the Application Services main repository.")

args = parser.parse_args()
base_branch = args.base_branch
remote = args.remote
release_type = args.release_type

# Constants
BUILDCONFIG_FILE = ".buildconfig-android.yml"
BUILDCONFIG_VERSION_FIELD = "libraryVersion"
UNRELEASED_CHANGES_FILE = "CHANGES_UNRELEASED.md"
CHANGELOG_FILE = "CHANGELOG.md"

# 1. Calculate new version number.

with open(BUILDCONFIG_FILE, "r") as stream:
    buildConfig = yaml.safe_load(stream)

cur_version = buildConfig[BUILDCONFIG_VERSION_FIELD]
cur_version_full = f"v{cur_version}"
[major, minor, patch] = map(lambda n: int(n), cur_version.split(".", 3))

if release_type == "major":
    major += 1
    minor = 0
    patch = 0
elif release_type == "minor":
    minor += 1
    patch = 0
elif release_type == "patch":
    patch += 1

next_version = f"{major}.{minor}.{patch}"
next_version_full = f"v{next_version}"

step_msg(f"Preparing release {next_version_full}")

# 2. Create a new branch based on the branch we want to release from.

ensure_working_tree_clean()

step_msg(f"Updating remote {remote}")
run_cmd_checked(["git", "remote", "update", remote])

release_branch = f"cut-{next_version_full}"
step_msg(f"Creating release branch {release_branch} from {base_branch}")
run_cmd_checked(["git", "checkout", "-b", release_branch, "--no-track", f"{remote}/{base_branch}"])

# 3. Bump YML version

step_msg(f"Bumping version in {BUILDCONFIG_FILE}")
buildConfig[BUILDCONFIG_VERSION_FIELD] = next_version

with open(BUILDCONFIG_FILE, "w") as stream:
    yaml.dump(buildConfig, stream, sort_keys=False)

# 4. Process changelog files

with open(UNRELEASED_CHANGES_FILE, "r") as stream:
    unreleased_changes = stream.read()

# Copy the text after the "Full Changelog" line in the unreleased changes file.
to_find = re.escape("[Full Changelog]")
changes = re.split(f"^{to_find}.+$", unreleased_changes, flags=re.MULTILINE)[1].strip()

with open(CHANGELOG_FILE, "r") as stream:
    changelog = stream.read()

today_date = datetime.today().strftime("%Y-%m-%d")

new_changelog = f"""# {next_version_full} (_{today_date}_)

[Full Changelog](https://github.com/mozilla/application-services/compare/{cur_version_full}...{next_version_full})

{changes}

{changelog}"""

new_changes_unreleased = f"""**See [the release process docs](docs/howtos/cut-a-new-release.md) for the steps to take when cutting a new release.**

# Unreleased Changes

[Full Changelog](https://github.com/mozilla/application-services/compare/{next_version_full}...master)
"""

with open(CHANGELOG_FILE, "w") as stream:
    stream.write(new_changelog)

with open(UNRELEASED_CHANGES_FILE, "w") as stream:
    stream.write(new_changes_unreleased)

# 5. Create a commit and send a PR

step_msg(f"Creating a commit with the changes")
run_cmd_checked(["git", "add", "-A"]) # We can use -A since we checked the working dir is clean.
run_cmd_checked(["git", "commit", "-m", f"Cut release {next_version_full}"])

response = input("Great! Would you like to push and open a pull-request? ([Y]/N)").lower()
if response != "y" and response != "" and response != "yes":
    exit(0)
run_cmd_checked(["git", "push", remote, release_branch])
webbrowser.open_new_tab(f"https://github.com/mozilla/application-services/compare/{base_branch}...{release_branch}")
