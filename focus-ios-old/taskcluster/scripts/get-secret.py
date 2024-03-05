#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import absolute_import, print_function, unicode_literals

import argparse
import base64
import errno
import json
import os
import taskcluster


def write_secret_to_file(path, data, key, base64decode=False, json_secret=False, append=False, prefix=''):
    path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../' + path))
    try:
        os.makedirs(os.path.dirname(path))
    except OSError as error:
        if error.errno != errno.EEXIST:
            raise
    print("Outputting secret to: {}".format(path))

    with open(path, 'a' if append else 'w') as f:
        value = data['secret'][key]
        if base64decode:
            value = base64.b64decode(value)
        if json_secret:
            value = json.dumps(value)
        f.write(prefix + value)


def fetch_secret_from_taskcluster(name):
    try:
        secrets = taskcluster.Secrets({
            # BaseUrl is still needed for tasks that haven't migrated to taskgraph yet.
            'baseUrl': 'http://taskcluster/secrets/v1',
        })
    except taskcluster.exceptions.TaskclusterFailure:
        # taskcluster library >=5 errors out when `baseUrl` is used
        secrets = taskcluster.Secrets({
            'rootUrl': os.environ.get('TASKCLUSTER_PROXY_URL', 'https://taskcluster.net'),
        })

    return secrets.get(name)


def main():
    parser = argparse.ArgumentParser(
        description='Fetch a taskcluster secret value and save it to a file.')

    parser.add_argument('-s', dest="secret", action="store", help="name of the secret")
    parser.add_argument('-k', dest='key', action="store", help='key of the secret')
    parser.add_argument('-f', dest="path", action="store", help='file to save secret to')
    parser.add_argument('--decode', dest="decode", action="store_true", default=False, help='base64 decode secret before saving to file')
    parser.add_argument('--json', dest="json", action="store_true", default=False, help='serializes the secret to JSON format')
    parser.add_argument('--append', dest="append", action="store_true", default=False, help='append secret to existing file')
    parser.add_argument('--prefix', dest="prefix", action="store", default="", help='add prefix when writing secret to file')

    result = parser.parse_args()

    secret = fetch_secret_from_taskcluster(result.secret)
    write_secret_to_file(result.path, secret, result.key, result.decode, result.json, result.append, result.prefix)


if __name__ == "__main__":
    main()
