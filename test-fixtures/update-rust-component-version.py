import json
import requests
import re
from github import Github
from pbxproj import XcodeProject


GITHUB_REPO = "mozilla/rust-components-swift"
SPM_PACKAGE = "Client.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
FIREFOX_PROJECT = "Client.xcodeproj/project.pbxproj"
RUST_COMPONENTS_ID = "433F87D62788F34500693368"
github_access_token = "GITHUB_TOKEN"


def get_newest_rust_components_version():
    g = Github()
    try:
        repo = g.get_repo(GITHUB_REPO)
        nightly_tag = repo.get_tags()[0]
        newest_tag = nightly_tag.name
        newest_commit = str(nightly_tag.commit)
        only_commit = re.findall(r'"([^"]*)"', newest_commit)
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)

    return (str(newest_tag), str(only_commit[0]))


def read_rust_components_tag_version(SPM_PACKAGE):
    # Read Package file to find the current rust-component version
    try:
        with open(SPM_PACKAGE) as f:
            data = json.load(f)

            for i in data["pins"]:
                if i["identity"] == "rust-components-swift":
                    # Return the current version and commit
                    return i["state"]["version"], i["state"]["revision"]
    except FileNotFoundError:
        print("Could not read rust component tag")
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")

    return None, None



def read_project_min_version():
    project = XcodeProject.load(FIREFOX_PROJECT)
    return project.get_object(RUST_COMPONENTS_ID).requirement.version


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
        with open(file_name, "r") as file:
            data = file.read()
            data = data.replace(current_tag, rust_component_repo_tag)
            data = data.replace(current_commit, rust_component_repo_commit)
    except FileNotFoundError:
        print("There was a problem reading to update the SPM file")
        return
    except IOError as e:
        print(f"Could not read the file: {e}")
        return

    # Write the updated data back to the file
    try:
        with open(file_name, "w") as file:
            file.write(data)
    except IOError as e:
        print(f"Could not write to the file: {e}")


def update_proj_file(current_tag, rust_component_repo_tag, file_name):
    # Read and update the data
    try:
        with open(file_name, "r") as file:
            data = file.read()
            data = data.replace(current_tag, rust_component_repo_tag)
    except FileNotFoundError:
        print("Could not read project file")
        return
    except IOError as e:
        print(f"Error reading project file: {e}")
        return

    # Write the updated data back to the file
    try:
        with open(file_name, "w") as file:
            file.write(data)
    except IOError as e:
        print(f"Could not update project file: {e}")


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
    current_min_version = read_project_min_version()
    if compare_versions(current_tag, rust_component_repo_tag):
        # If the version does not match, then the files are updated
        update_spm_file(current_tag, current_commit, rust_component_repo_tag,
                        rust_component_repo_commit, SPM_PACKAGE)
        update_proj_file(current_min_version,
                         rust_component_repo_tag, FIREFOX_PROJECT)

        # Save the newer version to be used in the PR info
        f = open("test-fixtures/newest_tag.txt", "w+")
        f.write(rust_component_repo_tag+"\n")


if __name__ == '__main__':
    main()
