import os, json
import requests
import datetime
import re
from github import Github


GITHUB_REPO = "mozilla/rust-components-swift"
SPM_PACKAGE = "Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
BLOCKZILLA_PROJECT = "Blockzilla.xcodeproj/project.pbxproj"
github_access_token = os.getenv("GITHUB_TOKEN")

def get_latest_rust_components_version():
    g = Github(github_access_token)
    repo = g.get_repo(GITHUB_REPO)

    latest_tag = repo.get_tags()[0].name
    latest_commit = str(repo.get_tags()[0].commit)
    only_commit = re.findall(r'"([^"]*)"', latest_commit)

    return (str(latest_tag), str(only_commit[0]))

def read_rust_components_tag_version():
    # Read Package file to find the current rust-component version
    f = open(SPM_PACKAGE)
    data = json.load(f)
    pin = data["object"]

    for i in pin["pins"]:
        if i["package"] == "MozillaRustComponentsSwift":
            # return the json with the RustComponent info
            json_new_version = i["state"]
    f.close()
    # Return the current version and commit
    return json_new_version["version"], json_new_version["revision"]

def read_project_min_version():
    line_number = 0
    list_of_results = []
    string_to_search = 'https://github.com/mozilla/rust-components-swift'

    with open(BLOCKZILLA_PROJECT) as f:
        #if 'https://github.com/mozilla/rust-components-swift' in f.read():
        line_read = 0
        for line in f:
            # For each line, check if line contains the string
            line_number += 1
            if string_to_search in line:
                # If yes, then look for the field we are interested in: minimumVersion
                for i in range(3):
                    minimumVersion = next(f, '').strip()

                version_found = minimumVersion.find("=")
                last_line_position = minimumVersion.find(";")
                current_tag_version = ''
                # version format: XX.Y.Z
                for i in range(version_found+2 , last_line_position):
                    current_tag_version+= minimumVersion[i]
                # Return the current rust-component version in project
                return current_tag_version

def compare_versions(current_tag_version, repo_tag_version):
    # Compare rust-component version used and the latest available in rust-component repo
    if current_tag_version < repo_tag_version:
        print("Update rust componet version and create PR")
        return True
    else:
        print("No new versions, skip")
        return False

def update_spm_file(current_tag, current_commit, rust_component_repo_tag, rust_component_repo_commit, file_name):
    # Read the SPM package file and update it
    file = open(file_name, "r+")
    data = file.read()
    data = data.replace(current_tag, rust_component_repo_tag)
    data = data.replace(current_commit, rust_component_repo_commit)
    file.close()
    
    file = open(file_name, "wt")
    file.write(data)
    file.close()


def update_proj_file(current_tag, rust_component_repo_tag, file_name):
    file = open(file_name, "r+")
    data = file.read()
    data = data.replace(current_tag, rust_component_repo_tag)

    file.close()
    
    file = open(file_name, "wt")
    file.write(data)
    file.close()

def main():
    
    '''
    STEPS
    1. check Rust Components repo for latest tagged version
    2. compare latest with current SPM and project versions in repo 
    3. if same version exit, if not, continue 
    4. update both SMP and project files
    
    '''

    rust_component_repo_tag, rust_component_repo_commit = get_latest_rust_components_version()
    current_tag, current_commit = read_rust_components_tag_version()
    current_min_version  = read_project_min_version()
    if compare_versions(current_tag, rust_component_repo_tag):
        # If the version does not match, then the files are updated
        update_spm_file(current_tag, current_commit, rust_component_repo_tag, rust_component_repo_commit, SPM_PACKAGE)
        update_proj_file(current_min_version, rust_component_repo_tag, BLOCKZILLA_PROJECT)

        # Save the newer version to be used in the PR info
        f= open("github-actions-scripts/newest_tag.txt","w+")
        f.write(rust_component_repo_tag+"\n")

if __name__ == '__main__':
    main()
