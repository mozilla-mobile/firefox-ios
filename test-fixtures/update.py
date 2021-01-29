import os
import re
import sys
import pathlib
from shutil import copyfile
import yaml


import requests
import semver
from requests.exceptions import HTTPError


BITRISE_STACK_INFO = 'https://app.bitrise.io/app/6c06d3a40422d10f/all_stack_info'
'''
curl ${BITRISE_STACK_INFO} | jq ' . | keys'
[
  "available_stacks",
  "project_types_with_default_stacks",
  "running_builds_on_private_cloud"
]
'''
pattern = 'osx-xcode-'
BITRISE_YML = '../bitrise.yml'
WORKFLOW = 'NewXcodeVersions'

resp = requests.get(BITRISE_STACK_INFO)
resp.raise_for_status()
resp_json = resp.json()


def parse_semver(raw_str):
    parsed = raw_str.split(pattern)[1]
    if parsed[-1] == 'x':
        p = parsed.split('.x')[0]
        return '{0}.0'.format(p)
    else:
        return False


def available_stacks():
    try:
        resp = requests.get(BITRISE_STACK_INFO)
        resp_json = resp.json()
        return resp_json['available_stacks']
    except HTTPError as http_error:
        print('An HTTP error has occurred: {http_error}')
    except Exception as err:
        print('An exception has occurred: {err}')


def largest_version():
    stacks = available_stacks()
    count = 0
    for item in stacks:
        if pattern in item:
            p = parse_semver(item)
            if p:
                if count == 0 or semver.compare(largest, p) == -1:
                    largest = p 
                count += 1
    return '{0}.x'.format(largest.split('.0')[0])



if __name__ == '__main__':
    '''
    STEPS
    1. check bitrise API stack info for latest XCode version
    2. compare latest with current bitrise.yml stack version in repo 
    3. if same exit, if not, continue 
    4. modify bitrise.yml (update stack value)
    '''


    largest_semver = largest_version()

    tmp_file = 'tmp.yml'
    with open(BITRISE_YML, 'r') as infile:
        y = yaml.safe_load(infile)
        current_semver = y['workflows'][WORKFLOW]['meta']['bitrise.io']['stack'] 

        if current_semver == largest_semver:
            print('Xcode version unchanged! aborting.')
        else:
            print('New Xcode version available: {0} ... updating bitrise.yml!'.format(largest_semver))
            y['workflows'][WORKFLOW]['meta']['bitrise.io']['stack'] = largest_semver 
            with open(tmp_file, 'w+') as tmpfile:
                yaml.dump(y, tmpfile, default_flow_style=False) 
                copyfile(tmp_file, BITRISE_YML)

