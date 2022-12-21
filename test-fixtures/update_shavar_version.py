import requests
import json


GCP_VERSION_FILE= "https://storage.googleapis.com/shavar-lists-ios-public/Public/version.txt"
CONTENT_BLOCKER_FILE="content-blocker.sh"

def get_shavar_version_from_gcp():
    resp = requests.get(GCP_VERSION_FILE)
    gcp_latest_version=resp.json()
    print(f"Shavar latest version on GCP {gcp_latest_version}")
    return gcp_latest_version

def read_current_shavar_version_on_repo():
    string_to_search = 'CURRENT_SHAVAR_LIST_VERSION='
    line_number = 0
    list_of_results = []
    with open(CONTENT_BLOCKER_FILE) as f:
        line_read = 0
        for line in f:
            if string_to_search in line:
                get_version=str(line).split('=')
                remove_new_line=get_version[1].replace("\n", "")
                remove_quotes=remove_new_line[1].replace('"', "")
                current_shavar_version_on_repo=int(remove_quotes)
                return current_shavar_version_on_repo

def compare_versions(shavar_version_on_gcp, current_shavar_version_on_repo):
    if shavar_version_on_gcp > current_shavar_version_on_repo:
        print("Update shavar lists")
        return True

def update_content_blocker_file(shavar_version_on_gcp, current_shavar_version_on_repo, CONTENT_BLOCKER_FILE):
    # Read content_blocker file
    try:
        file = open(CONTENT_BLOCKER_FILE, "r+")
        try:
            data = file.read()
            data = data.replace(str(current_shavar_version_on_repo), str(shavar_version_on_gcp))
        except:
            print("Could not read content-blocker file")
        finally:
            file.close()
    except:
        print("Could not open content-blocker file")

    # Update content_blocker file
    try:
        file = open(CONTENT_BLOCKER_FILE, "wt") 
        try:
            file.write(data)
            file.close()
        except:
            print("Could not write in content-blocker file")
    except:
        print("There was a problem updating the file")

def main():
    '''
    STEPS
    1. Check latest shavar version on GCP bucket
    2. Compare with current shavar version in repo
    3. If there is a new version, update content-blocker script
    '''
    shavar_version_on_gcp=get_shavar_version_from_gcp()
    current_shavar_version_on_repo=read_current_shavar_version_on_repo()
    if compare_versions(shavar_version_on_gcp, current_shavar_version_on_repo):
        update_content_blocker_file(shavar_version_on_gcp, current_shavar_version_on_repo, CONTENT_BLOCKER_FILE)

if __name__ == '__main__':
    main()
