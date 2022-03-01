import os, json
import requests
import datetime
import re
from github import Github


GITHUB_REPO = "mozilla/rust-components-swift"
SPM_PACKAGE = "Client.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
FIREFOX_PROJECT = "Client.xcodeproj/project.pbxproj"
github_access_token = "GITHUB_TOKEN"

def get_newest_rust_components_version():
    g = Github()
    try:
        repo = g.get_repo(GITHUB_REPO)

        newest_tag = repo.get_tags()[0].name
        newest_commit = str(repo.get_tags()[0].commit)
        only_commit = re.findall(r'"([^"]*)"', newest_commit)
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


    return (str(newest_tag), str(only_commit[0]))

def read_rust_components_tag_version():
    # Read Package file to find the current rust-component version
    try:
        f = open(SPM_PACKAGE)
        data = json.load(f)
        pin = data["object"]
        print("inside try")
        print(pin)

        for i in pin["pins"]:
            if i["package"] == "MozillaRustComponentsSwift":
                # return the json with the RustComponent info
                json_new_version = i["state"]
        f.close()
    except:
        print("Could not read rust component tag")
    # Return the current version and commit
    finally:
        return json_new_version["version"], json_new_version["revision"]

def read_project_min_version():
    line_number = 0
    list_of_results = []
    string_to_search = 'https://github.com/mozilla/rust-components-swift'

    with open(FIREFOX_PROJECT) as f:
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
    # Compare rust-component version used and the newest available in rust-component repo
    if current_tag_version < repo_tag_version:
        print("Update Rust Component version and create a PR")
        return True
    else:
        print("No new versions, skip")
        return False

def update_spm_file(current_tag, current_commit, rust_component_repo_tag, rust_component_repo_commit, file_name):
    # Read the SPM package file and update it
    try:
        file = open(file_name, "r+")
        try:
            data = file.read()
            data = data.replace(current_tag, rust_component_repo_tag)
            data = data.replace(current_commit, rust_component_repo_commit)
        except:
            print("Could not read the file")
        finally:
            file.close()
    except:
        print("There was a problem reading to update the spm file")

    try:
        file = open(file_name, "wt")
        try:
            file.write(data)
        except:
            print("Could not write to the file")
        finally:
            file.close()
    except:
        print("There was a problem updating the spm file")

def update_proj_file(current_tag, rust_component_repo_tag, file_name):
    try:
        file = open(file_name, "r+")
        data = file.read()
        data = data.replace(current_tag, rust_component_repo_tag)
    except:
        print("Could not read project file")
    finally:
        file.close()

    try:
        file = open(file_name, "wt")
        file.write(data)
    except:
        print("Could not update project file")
    finally:
        file.close()

def main():
    '''
    STEPS
    1. check Rust Components repo for newest tagged version
    2. compare newest with current SPM and project versions in repo
    3. if same version exit, if not, continue 
    4. update both SMP and project files
    
    '''

    rust_component_repo_tag, rust_component_repo_commit = get_newest_rust_components_version()
    current_tag, current_commit = read_rust_components_tag_version()
    current_min_version  = read_project_min_version()
    if compare_versions(current_tag, rust_component_repo_tag):
        # If the version does not match, then the files are updated
        update_spm_file(current_tag, current_commit, rust_component_repo_tag, rust_component_repo_commit, SPM_PACKAGE)
        update_proj_file(current_min_version, rust_component_repo_tag, FIREFOX_PROJECT)

        # Save the newer version to be used in the PR info
        f= open("test-fixtures/newest_tag.txt","w+")
        f.write(rust_component_repo_tag+"\n")

if __name__ == '__main__':
    main()
