#!/bin/env python
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import print_function

import redo
import requests
import shutil
import sys
import os
from optparse import OptionParser

DEFAULT_SYMBOL_URL = "https://symbols.mozilla.org/upload/"
MAX_RETRIES = 5

def Upload_Symbols(zip_file):
    print("Uploading symbols file '{0}' to '{1}'".format(zip_file, DEFAULT_SYMBOL_URL), file=sys.stdout)
    zip_name = os.path.basename(zip_file)

    # Fetch the symbol server token from Taskcluster secrets.
    secrets_url = "http://taskcluster/secrets/v1/secret/{}".format("project/application-services/symbols-token")
    res = requests.get(secrets_url)
    res.raise_for_status()
    secret = res.json()
    auth_token = secret["secret"]["token"]

    if len(auth_token) == 0:
        print("Failed to get the symbol token.", file=sys.stderr)

    for i, _ in enumerate(redo.retrier(attempts=MAX_RETRIES), start=1):
        print("Attempt %d of %d..." % (i, MAX_RETRIES))
        try:
            if zip_file.startswith("http"):
                zip_arg = {"data": {"url", zip_file}}
            else:
                zip_arg = {"files": {zip_name: open(zip_file, 'rb')}}
            r = requests.post(
                DEFAULT_SYMBOL_URL,
                headers={"Auth-Token": auth_token},
                allow_redirects=False,
                # Allow a longer read timeout because uploading by URL means the server
                # has to fetch the entire zip file, which can take a while. The load balancer
                # in front of symbols.mozilla.org has a 300 second timeout, so we'll use that.
                timeout=(10, 300),
                **zip_arg)
            # 500 is likely to be a transient failure.
            # Break out for success or other error codes.
            if r.status_code < 500:
                break
            print("Error: {0}".format(r), file=sys.stderr)
        except requests.exceptions.RequestException as e:
            print("Error: {0}".format(e), file=sys.stderr)
        print("Retrying...", file=sys.stdout)
    else:
        print("Maximum retries hit, giving up!", file=sys.stderr)
        return False

    if r.status_code >= 200 and r.status_code < 300:
        print("Uploaded successfully", file=sys.stdout)
        return True

    print("Upload symbols failed: {0}".format(r), file=sys.stderr)
    return False

def main():
    parser = OptionParser(usage="usage: <symbol store path>")
    (options, args) = parser.parse_args()

    if len(args) < 1:
        parser.error("not enough arguments")
        exit(1)

    symbol_path=args[0]
    shutil.make_archive(symbol_path , "zip", symbol_path)
    Upload_Symbols(symbol_path + ".zip")

# run main if run directly
if __name__ == "__main__":
    main()
