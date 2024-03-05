#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import absolute_import, print_function, unicode_literals

import argparse
import errno
import os


def write_secret_to_file(path, secret):
    path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../' + path))
    try:
        os.makedirs(os.path.dirname(path))
    except OSError as error:
        if error.errno != errno.EEXIST:
            raise
    print("Outputting secret to: {}".format(path))

    with open(path, 'w') as f:
        f.write(secret)


def main():
    parser = argparse.ArgumentParser(description="Store a dummy secret to a file")

    parser.add_argument("-c", dest="content", action="store", help="content of the secret")
    parser.add_argument("-f", dest="path", action="store", help="file to save secret to")

    result = parser.parse_args()

    write_secret_to_file(result.path, result.content)


if __name__ == "__main__":
    main()
