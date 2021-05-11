import os, json
import requests
import datetime
from pprint import pprint
from enum import Enum
from github import Github


GITHUB_REPO = "mozilla/application-services"
CARTFILE = 'Cartfile'
github_access_token = os.getenv("GITHUB_TOKEN")

def get_latest_as_version():
    g = Github(github_access_token)
    repo = g.get_repo(GITHUB_REPO)

    latest_tag = repo.get_tags()[0].name
    return (str(latest_tag))

def read_cartfile_tag_version():
    # Read Cartfile to find the current a-s version
    with open(CARTFILE) as fp:
        line = fp.readline()
        cnt = 1
        while line:
            line = fp.readline()
            cnt += 1

            # Find the line that defines the a-s version
            if 'mozilla/application-services' in line:
                version_found = line.find('"v')
                current_tag_version = ''
                # version format: vXX.Y.Z
                version_starts = version_found +1
                version_ends = version_starts +7
                for i in range(version_starts, version_ends):
                    current_tag_version+=line[i]
                return(current_tag_version)

def update_cartfile_tag_version(current_tag, as_repo_tag, file_name):
    # Read the Cartfile and Cartife.resolved, update
    file = open(file_name, "r+")
    data = file.read()
    data = data.replace(current_tag, as_repo_tag)
    file.close()
    
    file = open(file_name, "wt")
    file.write(data)
    file.close()


def compare_versions(current_tag_version, repo_tag_version):
    # Compare a-s version used and the latest available in a-s repo
    if current_tag_version < repo_tag_version:
        print("Update A-S version and create PR")
        return True
    else:
        print("No new versions, skip")
        return False

def main():
    '''
    STEPS
    1. check Application-Services repo for latest tagged version
    2. compare latest with current cartage and cartage.resolved versions in repo 
    3. if same version exit, if not, continue 
    4. update both cartfile and cartfile.resolved
    '''
    github_access_token = os.getenv("GITHUB_TOKEN")
    if not github_access_token:
        print("No GITHUB_TOKEN set. Exiting.")

    as_repo_tag= get_latest_as_version()
    current_tag = read_cartfile_tag_version()
    if compare_versions(current_tag, as_repo_tag):
        update_cartfile_tag_version(current_tag, as_repo_tag, CARTFILE)
        update_cartfile_tag_version(current_tag, as_repo_tag, "Cartfile.resolved")

        # Save the newer version to be used in the PR info
        f= open("test-fixtures/newest_tag.txt","w+")
        f.write(as_repo_tag+"\n")

if __name__ == '__main__':
    main()
