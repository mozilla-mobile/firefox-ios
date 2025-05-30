#!/usr/bin/env python
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import base64
import jwt
import os
import requests
import time

# This script adds a test group to a build in TestFlight using the App Store Connect API.

# Required environment variables:
ISSUER_ID = os.getenv("APPSTORECONNECT_APIKEY_ISSUER_ID")
KEY_ID = os.getenv("APPSTORECONNECT_APIKEY_KEY_ID")
# The private key should be base64 encoded and stored in the environment variable APPSTORECONNECT_APIKEY_B64
# It's base64 encoded to avoid issues with special characters in the key (like newlines).
API_KEY = base64.b64decode(os.getenv("APPSTORECONNECT_APIKEY_B64")).decode("utf-8")
# Firefox Beta App ID - retrieved from App Store Connect
# You can find the App ID in the URL when you view the app in App Store Connect.
APPSTORE_APP_ID = os.getenv("APPSTORE_APP_ID")
# The group name to be added to the build in TestFlight
TEST_FLIGHT_GROUP_NAME = os.getenv("TEST_FLIGHT_EXTERNAL_GROUP_NAME", "Nightly")
# The version of the build in TestFlight
BUILD_VERSION = os.getenv("BITRISE_NIGHTLY_VERSION", "9000")

def generate_jwt_token(issuer_id, key_id, private_key):
    """Generates a JWT token using the given credentials."""
    payload = {
        "iss": issuer_id,
        "exp": int(time.time()) + 2 * 60,  # Token valid for 2 minutes
        "aud": "appstoreconnect-v1",
    }

    token = jwt.encode(
        payload,
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "alg": "ES256", "typ": "JWT"},
    )
    return token


def api_call(url, jwt_token, method="GET", payload=None, params=None):
    """Handles making API requests to App Store Connect."""
    print(f"Calling API: {url}")
    if params:
        print(f" -> Params: {params}")
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Content-Type": "application/json",
    }

    response = requests.request(method, url, headers=headers, json=payload, params=params)
    if response.status_code in [200, 201]:
        return response.json()
    elif response.status_code == 204:
        return  # Empty response
    elif response.status_code == 401:
        print(response)
        raise Exception("Token expired or invalid.")
    raise Exception(f"API request failed: {response.status_code} - {response.text}")


def get_paginated_data(url, jwt_token, params=None):
    data = []
    while True:
        result = api_call(url, jwt_token, params=params)
        data.extend(result["data"])
        if next := result["links"].get("next") and False:
            url = next
            params = None
        else:
            return data


def main():
    jwt_token = generate_jwt_token(
        issuer_id=ISSUER_ID, key_id=KEY_ID, private_key=API_KEY
    )

    # Fetch beta groups
    beta_groups = get_paginated_data(
        "https://api.appstoreconnect.apple.com/v1/betaGroups", jwt_token, {
            "filter[app]": APPSTORE_APP_ID,
            "filter[name]": TEST_FLIGHT_GROUP_NAME,
        }
    )
    assert len(beta_groups) == 1
    group = beta_groups[0]
    print(f"Found group: {group['id']} {group['attributes']['name']}")

    # Fetch builds for the app with a specific pre-release version
    builds = get_paginated_data(
        "https://api.appstoreconnect.apple.com/v1/builds", jwt_token, {
            "filter[app]": APPSTORE_APP_ID,
            "filter[preReleaseVersion.version]": BUILD_VERSION,
            "fields[preReleaseVersions]": "version",
            "sort": "-version",
            "limit": "1"
        }
    )
    assert len(builds) == 1
    build = builds[0]
    print(f"Found build: ID<{build['id']}> version<{build['attributes']['version']}> uploaded<{build['attributes']['uploadedDate']}>")

    # Add the beta group to the build
    payload = {"data": [{"type": "betaGroups", "id": group["id"]}]}
    api_call(
        f"https://api.appstoreconnect.apple.com/v1/builds/{build['id']}/relationships/betaGroups",
        jwt_token=jwt_token,
        method="POST",
        payload=payload,
    )
    print(f"Added {TEST_FLIGHT_GROUP_NAME} to build {build['attributes']['version']}")

if __name__ == "__main__":
    main()
