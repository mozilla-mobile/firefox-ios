import requests

CREDENTIAL_PROVIDER_JS_URL = "https://hg.mozilla.org/mozilla-central/raw-file/tip/toolkit/components/passwordmgr/LoginManagerChild.jsm"
LOGINS_MANAGER_JSM_PATH = "./Client/Assets/CC_Script/LoginManagerChild.jsm"

def download_and_update_credential_provider_script():
    try:
        response = requests.get(CREDENTIAL_PROVIDER_JS_URL, stream=True)
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

def main():
    download_and_update_credential_provider_script()

if __name__ == '__main__':
    main()
