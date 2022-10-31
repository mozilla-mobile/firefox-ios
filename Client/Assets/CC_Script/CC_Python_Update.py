import requests
import filecmp
import shutil
import os

FILE_TO_DOWNLOAD = "https://hg.mozilla.org/mozilla-central/raw-file/tip/toolkit/components/passwordmgr/LoginManager.shared.mjs"
REAL_FILE_NAME = "LoginManager.shared.mjs"
TEMP_FILE_NAME_APPEND = "TEMP_DOWNLOADED_FILE"
GITHUB_ACTIONS_PATH = "./Client/Assets/CC_Script/"
TEMP_FILE_PATH = GITHUB_ACTIONS_PATH + TEMP_FILE_NAME_APPEND
REAL_FILE_PATH = GITHUB_ACTIONS_PATH + REAL_FILE_NAME

# Methods related to file download, compare, copy contents and removal

def downloadTemporaryFileToCompare():
    reqHeader = {
        "Cache-Control": "no-cache",
        "Pragma": "no-cache"
    }

    try:
        response = requests.get(FILE_TO_DOWNLOAD, stream=True, headers=reqHeader)
        try:
            file = open(TEMP_FILE_PATH, "w")
            file.close()
        except:
            print("Could not write to the file")
        with open(TEMP_FILE_PATH, 'wb') as f:
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
        print("Nothing to remove, all clear")
        return False

# main

def main():
    # download (file to compare changes
    downloadTemporaryFileToCompare()

    # file does not exist
    if os.path.exists(REAL_FILE_PATH) == False:
        shutil.move(TEMP_FILE_PATH, REAL_FILE_PATH)
    else:
    # compare if there are any changes with the file
    # downloaded vs what we currently have on disk
        compare_file_result = compare_file(TEMP_FILE_PATH, REAL_FILE_PATH)
        if compare_file_result == False:
            copyContents(TEMP_FILE_PATH, REAL_FILE_PATH)
        else:
            print("No change, do nothing")

    # remove temp downloaded file for cleanup
    removeFile(TEMP_FILE_PATH)

if __name__ == '__main__':
    main()
