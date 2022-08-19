import requests
import re
import git
import os

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
author_exception_list = ['Nishant Patel',
                         'yoanarios',
                         'Nishant Bhasin',
                         'isabelrios',
                         'lmarceau',
                         'Laurie Marceau',
                         'OrlaM',
                         'Winnie Teichmann',
                         'roux g. buciu',
                         'Daniela Arcese',
                         'github-actions[bot]']


def fetch_raw_data(url: str) -> str:
    return requests.get(url).content.decode("utf-8")


# Find released version from App Store
def get_store_version() -> Version:
    data = fetch_raw_data(firefox_url)
    version_string = re.search('whats-new__latest__version\">Version (.*)</p>', data).group(1)
    split = version_string.split(".")
    return Version(int(split[0]), int(split[1]))


def calculate_previous_version(version: Version) -> Version:
    if version.minor == 0:
        return Version(version.major - 1, 0)
    else:
        return Version(version.major, version.minor - 1)


def get_diff_commits(current_version: Version, previous_version: Version) -> str:
    repo = git.Repo(search_parent_directories=True)

    commit_origin_current = repo.commit(f"mozilla/v{current_version.string_name}")
    commit_origin_previous = repo.commit(f"mozilla/v{previous_version.string_name}")

    stream = os.popen(f'git merge-base mozilla/v{previous_version.string_name} mozilla/main')
    commit_intersect = stream.read().strip('\n')
    # Add 1 to date to avoid getting that commit in the diff
    commit_intersect_object = repo.commit(f"{commit_intersect}")
    max_date = commit_intersect_object.committed_date + 1

    # Pretty format doc: https://git-scm.com/docs/pretty-formats
    result = repo.git.log(f'--since={max_date}',
                          '--pretty=format:- @%an with: %s',
                          commit_intersect,
                          commit_origin_current)
    return result


if __name__ == '__main__':
    # Uncomment for tests
    current = Version(major=104, minor=0)
    previous = Version(major=103, minor=0)

    # current = get_store_version()
    # print(f"Found App store version: {current}")
    #
    # previous = calculate_previous_version(current)
    # print(f"Previous is then: {previous}")

    commits = get_diff_commits(current, previous)
    commits_list = commits.split("\n")
    ex = '\n'.join(commits_list)
    print(f"Found commits: {ex}")

    contributor_commits = []
    for commit in commits_list:
        author = re.search('- @(.*) with: ', commit).group(1)
        if author not in author_exception_list:
            contributor_commits.append(commit)

    # Build release
    current_tag = f"v{current.string_name}"
    previous_tag = f"v{previous.string_name}"
    formatted_commits = '\n'.join(contributor_commits)
    release_message = f"# {current_tag} \n" \
                      f"This is our official {current_tag} release of Firefox - iOS. It's based on the " \
                      f"[{current_tag} branch](https://github.com/mozilla-mobile/firefox-ios/tree/{current_tag}) \n\n" \
                      f"## Differences between {previous_tag} & {current_tag} \n" \
                      f"You can view the changes between our previous and newly released version " \
                      f"[here](https://github.com/mozilla-mobile/firefox-ios/compare/{previous_tag}...{current_tag}).\n\n" \
                      f"## Contributions \n" \
                      f"We've had lots of contributions from the community this release, including:\n" \
                      f"{formatted_commits}\n" \
                      f"Thanks everyone!"
    print(release_message)
