import requests
import filecmp
import difflib
import shutil
import os

FILE_TO_DOWNLOAD = "https://gist.githubusercontent.com/nbhasin2/758043d79213507ee6e163fee8f2625e/raw/185cead0c64587fd2e20f374d345105269136e18/myfile.js"
TEMP_FILE_NAME_APPEND = "TEMP_DOWNLOADED_FILE"
REAL_FILE_NAME = "myfile.js"
TEMP_FILE_PATH = "./" + TEMP_FILE_NAME_APPEND
REAL_FILE_PATH = "./"+ REAL_FILE_NAME

CREDENTIAL_PROVIDER_JS_URL = "https://hg.mozilla.org/mozilla-central/raw-file/tip/toolkit/components/passwordmgr/LoginManagerChild.jsm"
LOGINS_MANAGER_JSM_PATH = "./Client/Assets/CC_Script/LoginManagerChild.jsm"

def download_and_update_credential_provider_script():
    try:
        response = requests.get(FILE_TO_DOWNLOAD_OR_UPDATE_URL, stream=True)
        try:
            file = open(LOGINS_MANAGER_JSM_PATH, "w")
            file.close()
        except:
            print("Could not write to the file")
        with open(LOGINS_MANAGER_JSM_PATH, 'wb') as f:
            for chunk in response.iter_content():
                f.write(chunk)
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)

def downloadTemporaryFileToCompare():
    reqHeader = {
        "Cache-Control": "no-cache",
        "Pragma": "no-cache"
    }

    try:
        response = requests.get(FILE_TO_DOWNLOAD, stream=True, headers=reqHeader)
        try:
            file = open(TEMP_FILE_NAME_APPEND, "w")
            file.close()
        except:
            print("Could not write to the file")
        with open(TEMP_FILE_NAME_APPEND, 'wb') as f:
            for chunk in response.iter_content():
                f.write(chunk)
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)

def compare_file(file1, file2): 
    result = filecmp.cmp(file1,file2)
    print("comparing two files -> ?", result)
    return result

def copyContents(fromFile, toFile):
    print("copying contents")
    with open(fromFile, 'rb') as f2, open(toFile, 'wb') as f1:
        shutil.copyfileobj(f2, f1)

def removeFile(fileToRemove):
    if os.path.exists(fileToRemove):
        os.remove(fileToRemove)
        return True
    else:
        print("The file does not exist") 
        return False

def main():
    downloadTemporaryFileToCompare()

    # File does not exist
    if os.path.exists(REAL_FILE_PATH) == False:
        shutil.move(TEMP_FILE_PATH, REAL_FILE_PATH)
    else:
    # Compare if there are any changes with the file 
    # downloaded vs what we currently have on disk
        compare_file_result = compare_file(TEMP_FILE_PATH, REAL_FILE_PATH) 
        if compare_file_result == False:
            copyContents(TEMP_FILE_PATH, REAL_FILE_PATH)
    removeFile(TEMP_FILE_PATH)

if __name__ == '__main__':
    main()
