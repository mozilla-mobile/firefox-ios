"""
This script can be used to build the message for the release in GitHub. It will fetch commits between
two versions, make the diff and properly tag users with @mention. Contributors will be listed in the message,
ignoring users emails that are listed in the 'author_exception_list'.

The script can either be used with manual versions input, or the script can fetch latest released versions
from the App Store.

To use you first need to install python requirements through pip in your virtual environment.
- python -m venv venv
- source venv/bin/activate
- pip install -r requirements.txt   

Then create a `config.py` file that will contain the username and token to access GitHub API with format:
```
username = "username"
token = "123456"
```
You can create a Github token following https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token

Once that's done, you can start using the script.
Two versions can be passed in as arguments:
- python github_release.py -o 'oldVersion' -n 'newVersion'
- python github_release.py -o 107.3 -n 108.0

Or no versions can be passed in, and the script will retrieve the versions from the App Store (versions needs to be already released for this to work):
- python github_release.py
"""

import argparse
import config
import git
import requests
import re
import os
import time

from dataclasses import dataclass
from github import Github
from typing import Optional


@dataclass
class Version:
    major: int
    minor: int

    @property
    def string_name(self):
        return f"{self.major}.{self.minor}"

    @classmethod
    def build_version(cls, version_string: str):
        if "." in version_string:
            split = version_string.split(".")
            return cls(int(split[0]), int(split[1]))
        else:
            return cls(int(version_string), 0)


# The Firefox for iOS App Store URL
firefox_url = 'https://apps.apple.com/ca/app/firefox-private-safe-browser/id989804926'

# Any author email added into this list won't appear in the contributors thank you note
author_exception_list = ['4530+thatswinnie@users.noreply.github.com',
                         'lmarceau@mozilla.com',
                         'mitchell.orla@gmail.com',
                         'omitchell@mozilla.com',
                         'nikieme3@gmail.com',
                         'nish.bhasin@gmail.com',
                         'yriosdiaz@mozilla.com',
                         'yrrios13@gmail.com',
                         'nishantpatel2718@gmail.com',
                         'clare.m.so@gmail.com',
                         'cso@mozilla.com',
                         '11182210+adudenamedruby@users.noreply.github.com',
                         '11182210+polymathruby@users.noreply.github.com',
                         '107960801+jjSDET@users.noreply.github.com',
                         'roux@mozilla.com',
                         'isabelrios@gmail.com',
                         'dnarcese@gmail.com',
                         '41898282+github-actions[bot]@users.noreply.github.com',
                         'litianu.razvan@gmail.com',
                         'ralucaiordan@icloud.com',
                         '51127880+PARAIPAN9@users.noreply.github.com',
                         '49699333+dependabot[bot]@users.noreply.github.com']


def fetch_raw_data(url: str) -> str:
    return requests.get(url).content.decode("utf-8")


def get_store_versions() -> (Version, Version):
    """
    Find current and previous release versions from App Store
    Returns:
        current_version, previous_version
    """
    data = fetch_raw_data(firefox_url)
    versions = re.findall(r'"versionDisplay\\":\\"(.*?)\\",\\"releaseNotes\\', data)

    return Version.build_version(versions[0]), Version.build_version(versions[1])


def get_diff_commits(current_version: Version,
                     previous_version: Version) -> str:
    """
    Get the commits difference between two versions.
    We find the intersection with main to be able to make the diff then prettify logs
    """
    repo = git.Repo(search_parent_directories=True)
    commit_origin_current = repo.commit(f"mozilla/release/v{current_version.string_name}")

    stream = os.popen(f'git merge-base mozilla/release/v{previous_version.string_name} mozilla/main')
    commit_intersect = stream.read().strip('\n')
    # Add 1 to date to avoid getting that commit in the diff
    commit_intersect_object = repo.commit(f"{commit_intersect}")
    max_date = commit_intersect_object.committed_date + 1

    # Pretty format doc: https://git-scm.com/docs/pretty-formats
    return repo.git.log(f'--since={max_date}',
                        '--pretty=format:email: %ae username: %an with commit: %s',
                        commit_intersect,
                        commit_origin_current)


def filter_commits(commits: list) -> list[str]:
    """
    Removing commits that were made by members of the `author_exception_list`
    """
    contributor_commits = []
    for commit in commits:
        author = re.search('email: (.*) username:', commit).group(1)
        if author not in author_exception_list:
            print(f"Found contributor commit: {commit}")
            contributor_commits.append(commit)
    return contributor_commits


def get_usernames_commits(commits: list) -> dict[str:[str]]:
    """
    Retrieves the @mention username as this information isn't available with local git.
    Whenever we fetch from the GitHub API for a username, we throttle as we can hit the rate limit rapidly.
    This is also why we temporarily save the found usernames to avoid making too much API calls.
    Returns:
        A dictionary containing an array of commits for specific users.
        Key being the username, value being the array of commits (of format #12345)
    """
    mention_commits = {}
    saved_users = {}

    g = Github(f"{config.username}", f"{config.token}")

    for commit in commits:
        username = re.search('username: (.*) with commit:', commit).group(1)
        print(f"Analyzing commit: {commit}")
        try:
            subject = re.findall(r"#\b\d{5}\b", commit)[0]
        except IndexError:
            # If we can't grasp PR number, use the whole commit as subject
            subject = re.search('with commit: (.*)', commit).group(1)

        if username in saved_users:
            # Do not search again since we have the username already
            found_user = saved_users[username][0]
        else:
            # Find username to @mention from API
            found = g.search_users(f"{username}")
            if found.totalCount == 0:
                # Username for @mention not found
                found_user = username
            else:
                # Should be the first found user
                found_user = f"@{found[0].login}"
            time.sleep(4)

        append_to_dict(mention_commits, found_user, subject)
        if username not in saved_users:
            saved_users[username] = [found_user]

    return mention_commits


def append_to_dict(to: {}, key: str, value: str):
    if key in to:
        to[key].append(value)
    else:
        to[key] = [value]


def build_release_message(current_version: Version,
                          previous_version: Version,
                          commits: dict[str:[str]]) -> str:
    current_tag = f"v{current_version.string_name}"
    previous_tag = f"v{previous_version.string_name}"
    contributions = build_contribution_message(commits)

    return f"# Overview \n" \
           f"This is our official {current_tag} release of Firefox-iOS. It's based on the " \
           f"[{current_tag} branch](https://github.com/mozilla-mobile/firefox-ios/tree/release/{current_tag}) \n\n" \
           f"## Differences between {previous_tag} & {current_tag} \n" \
           f"You can view the changes between our previous and newly released version " \
           f"[here](https://github.com/mozilla-mobile/firefox-ios/compare/release/{previous_tag}...release/{current_tag}).\n\n" \
           f"{contributions}"


def build_contribution_message(commits: dict[str:[str]]) -> str:
    # If there's no contributors, then it doesn't build this section.
    if len(commits) == 0:
        return ""

    formatted_commits = ""
    for key, value in commits.items():
        if len(value) > 1:
            assembled_user_commits = ', '.join(value)
            formatted_commits += f"{key} with commits: {assembled_user_commits} \n"
        else:
            formatted_commits += f"{key} with commit: {value[0]} \n"

    return f"## Contributions \n" \
           f"We've had lots of contributions from the community this release, including:\n\n" \
           f"{formatted_commits}\n" \
           f"Thanks everyone!"


parser = argparse.ArgumentParser()
parser.add_argument("-o", "--previous_version", help="The previously released version", type=str)
parser.add_argument("-n", "--current_version", help="The currently released version", type=str)


if __name__ == '__main__':
    args = parser.parse_args()
    current_version: Optional[str] = args.current_version
    previous_version: Optional[str] = args.previous_version

    if current_version and previous_version:
        current = Version.build_version(current_version)
        previous = Version.build_version(previous_version)
    else:
        current, previous = get_store_versions()

    print(f"Running with version current: {current.string_name}, previous: {previous.string_name}")
    raw_commits_list = get_diff_commits(current, previous).split("\n")
    filtered_list = filter_commits(raw_commits_list)
    username_list = get_usernames_commits(filtered_list)
    release_message = build_release_message(current, previous, username_list)

    print(f"***** Start of release message *****\n\n")
    print(f"{release_message}")
    print(f"\n\n***** End of release message *****")
