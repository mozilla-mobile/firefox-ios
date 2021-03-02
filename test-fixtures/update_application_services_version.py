import os, json
import requests
import datetime
from pprint import pprint
from enum import Enum


APPLICATION_SERVICES_TAGS_INFO = 'https://api.github.com/repos/mozilla/application-services/tags'
CARTFILE = 'Cartfile'

def available_tags():
    try:
        resp = requests.get(APPLICATION_SERVICES_TAGS_INFO)
        resp_json = resp.json()
        print (resp_json[0])
        return resp_json[0]
    except HTTPError as http_error:
        print('An HTTP error has occurred: {http_error}')
    except Exception as err:
        print('An exception has occurred: {err}')

def latest_version():
    tags = available_tags()
    latest_tag_version = tags['name']
    return latest_tag_version

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

if __name__ == '__main__':
    '''
    STEPS
    1. check Application-Services repo for latest tagged version
    2. compare latest with current cartage and cartage.resolved versions in repo 
    3. if same version exit, if not, continue 
    4. update both cartfile and cartfile.resolved
    '''
    as_repo_tag= latest_version()
    current_tag = read_cartfile_tag_version()
    if compare_versions(current_tag, as_repo_tag):
        update_cartfile_tag_version(current_tag, as_repo_tag, CARTFILE)
        update_cartfile_tag_version(current_tag, as_repo_tag, "Cartfile.resolved")
