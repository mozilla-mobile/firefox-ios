import os
from shutil import copyfile
from ruamel.yaml import YAML


import requests
from requests.exceptions import HTTPError


BITRISE_STACK_INFO = 'https://api.github.com/repos/bitrise-io/stacks/contents/content/stack_reports'
'''
curl ${BITRISE_STACK_INFO} | jq ' . | keys'
[
  "available_stacks",
  "project_types_with_default_stacks",
  "running_builds_on_private_cloud"
]
'''
pattern = 'osx-xcode-'
patterns = [pattern]
BITRISE_YML = 'bitrise.yml'
WORKFLOW = 'NewXcodeVersions'

def get_stack_info():
    try:
        resp = requests.get(BITRISE_STACK_INFO)    
        resp.raise_for_status()
        resp_json = resp.json()
        return resp_json
    except HTTPError as http_error:
        print('An HTTP error has occurred: {http_error}')
    except Exception as err:
        print('An exception has occurred: {err}')

def latest_stack(stacks_info):
    stack_names = [stack.get("name").replace(".md", "") for stack in stacks_info]
    keys = sorted([stack_name for stack_name in stack_names if pattern in stack_name])
    return keys[-1]
        
def latest_stable_stack(stacks_info):
    stack_names = [stack.get("name").replace(".md", "") for stack in stacks_info]
    keys = sorted([stack_name for stack_name in stack_names 
                   if pattern in stack_name and '-edge' not in stack_name])
    return keys[-1]
        
def write_to_bitrise_yml(yaml, version):
    yaml['workflows'][WORKFLOW]['meta']['bitrise.io']['stack'] = '{0}{1}'.format(pattern, version)
    with open(tmp_file, 'w+') as tmpfile:
        obj_yaml.dump(yaml, tmpfile)
        copyfile(tmp_file, BITRISE_YML)
        os.remove(tmp_file)

if __name__ == '__main__':
    '''
    STEPS
    1. check bitrise API stack info for the default stack version
    2. compare latest with current bitrise.yml stack version in repo
    3. if same exit, if not, continue
    4. modify bitrise.yml (update stack value)
    '''

    stacks_info = get_stack_info()
    latest_stable_semver = latest_stable_stack(stacks_info).split(pattern)[1]
    latest_semver = latest_stack(stacks_info).split(pattern)[1]
    tmp_file = 'tmp.yml'

    with open(BITRISE_YML, 'r') as infile:

        obj_yaml = YAML()

        # prevents re-formatting of yml file
        obj_yaml.preserve_quotes = True
        obj_yaml.width = 4096

        y = obj_yaml.load(infile)

        current_semver = y['workflows'][WORKFLOW]['meta']['bitrise.io']['stack']
        
        # remove pattern prefix from current_semver to compare with largest
        current_semver = current_semver.split(pattern)[1]
        
        print("current_semver: {0}".format(current_semver))
        print("latest_stable_semver: {0}".format(latest_stable_semver))
        print("latest_semver: {0}".format(latest_semver))
        
        # if we use an edge stack currently, see if there is a new stable version
        if '-edge' in current_semver:
            # if there is a stable stack of the same version or later, use stable stack.
            # otherwise do nothing
            if latest_stable_semver >= current_semver.replace('-edge', ''):
                print("Stable version of Bitrise stack available: {0} ... updating bitrise.yml!".format(latest_stable_semver))
                write_to_bitrise_yml(y, latest_stable_semver)
            else:
                print('No stable version of Bitrise stack available! aborting.')
        # if we are using a stable stack, see if there is a new stable version
        elif current_semver < latest_stable_semver:
            print('New stable Bitrise stack available: {0} ... updating bitrise.yml!'.format(latest_stable_semver))
            write_to_bitrise_yml(y, latest_stable_semver)
        # if a new edge version is available, update bitrise.yml
        elif current_semver < latest_semver:
            print('New edge version of Bitrise stack available: {0} ... updating bitrise.yml!'.format(latest_semver))
            write_to_bitrise_yml(y, latest_semver)
        # we're using the absolutely latest version available
        else:
             print('Xcode version unchanged or more recent! aborting.')
