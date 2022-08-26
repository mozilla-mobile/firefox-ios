import config
import git
import requests
import re
import os
import time

from github import Github
from dataclasses import dataclass


@dataclass
class Version:
    major: int
    minor: int

    @property
    def string_name(self):
        return f"{self.major}.{self.minor}"


# The Firefox for iOS App Store URL
firefox_url = 'https://apps.apple.com/ca/app/firefox-private-safe-browser/id989804926'

# Any author added into this list won't appear in the contributors thank you note
author_exception_list = ['4530+thatswinnie@users.noreply.github.com',
                         'lmarceau@mozilla.com',
                         'mitchell.orla@gmail.com',
                         'nikieme3@gmail.com',
                         'yriosdiaz@mozilla.com',
                         'nishantpatel2718@gmail.com',
                         '11182210+electricRGB@users.noreply.github.com',
                         'isabelrios@gmail.com',
                         '41898282+github-actions[bot]@users.noreply.github.com',
                         'litianu.razvan@gmail.com',
                         'ralucaiordan@icloud.com',
                         '51127880+PARAIPAN9@users.noreply.github.com']


def fetch_raw_data(url: str) -> str:
    return requests.get(url).content.decode("utf-8")


# Find released version from App Store
def get_store_version() -> Version:
    data = fetch_raw_data(firefox_url)
    version_string = re.search('whats-new__latest__version\">Version (.*)</p>', data).group(1)
    split = version_string.split(".")
    return Version(int(split[0]), int(split[1]))


# TODO: Cannot be calculated like this, needs to be fetched from app store.
def calculate_previous_version(version: Version) -> Version:
    if version.minor == 0:
        return Version(version.major - 1, 0)
    else:
        return Version(version.major, version.minor - 1)


def get_diff_commits(current_version: Version, previous_version: Version) -> str:
    repo = git.Repo(search_parent_directories=True)
    commit_origin_current = repo.commit(f"mozilla/v{current_version.string_name}")

    stream = os.popen(f'git merge-base mozilla/v{previous_version.string_name} mozilla/main')
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
    contributor_commits = []
    for commit in commits:
        author = re.search('email: (.*) username:', commit).group(1)
        if author not in author_exception_list:
            contributor_commits.append(commit)
    return contributor_commits


def get_usernames_commits(commits: list) -> dict[str:[str]]:
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
            time.sleep(5)

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
           f"[{current_tag} branch](https://github.com/mozilla-mobile/firefox-ios/tree/{current_tag}) \n\n" \
           f"## Differences between {previous_tag} & {current_tag} \n" \
           f"You can view the changes between our previous and newly released version " \
           f"[here](https://github.com/mozilla-mobile/firefox-ios/compare/{previous_tag}...{current_tag}).\n\n" \
           f"{contributions}"


def build_contribution_message(commits: dict[str:[str]]) -> str:
    # If there's no contributors, then don't build this section
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


if __name__ == '__main__':
    # Uncomment for tests
    current = Version(major=104, minor=1)
    previous = Version(major=104, minor=0)

    # TODO: If script parameters use them, if not fetch version from App Store
    # current = get_store_version()
    # print(f"Found App store version: {current}")
    #
    # previous = calculate_previous_version(current)
    # print(f"Previous is then: {previous}")

    raw_commits_list = get_diff_commits(current, previous).split("\n")
    filtered_list = filter_commits(raw_commits_list)
    username_list = get_usernames_commits(filtered_list)
    release_message = build_release_message(current, previous, username_list)

    print(f"{release_message}")
