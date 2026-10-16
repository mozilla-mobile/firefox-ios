#!/usr/bin/env python3

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Prints the failed or errored test cases in a JUnit XML report as a bulleted list.
# Usage: list_failed_junit_tests.py <junit.xml>

import os
import sys
import xml.etree.ElementTree as ET


def failed_tests(junit_xml):
    root = ET.parse(junit_xml).getroot()
    return [
        case.get('name') for case in root.iter('testcase')
        if case.find('failure') is not None or case.find('error') is not None
    ]


def main():
    if len(sys.argv) != 2:
        sys.exit(f"Usage: {sys.argv[0]} <junit.xml>")
    junit_xml = sys.argv[1]
    if not os.path.isfile(junit_xml):
        print("No test results (run failed before pytest finished)")
        return
    print('\n'.join(f"• {name}" for name in failed_tests(junit_xml)))


if __name__ == '__main__':
    main()
