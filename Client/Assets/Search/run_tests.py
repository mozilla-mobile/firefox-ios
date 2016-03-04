#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from lxml import etree
import sys
import unittest

from scrape_plugins import Overlay

class TestOverlays(unittest.TestCase):
    def setUp(self):
        self.plugin = etree.parse("Tests/Base/testplugin.xml")

    def testAppend(self):
        overlay = Overlay("Tests/Overlays/append.xml")
        overlay.apply(self.plugin)
        self.assertEqualsExpectedXML(plugin=self.plugin, expectedPath="Tests/Expected/append.xml")

    def testReplace(self):
        overlay = Overlay("Tests/Overlays/replace.xml")
        overlay.apply(self.plugin)
        self.assertEqualsExpectedXML(plugin=self.plugin, expectedPath="Tests/Expected/replace.xml")

    def assertEqualsExpectedXML(self, plugin, expectedPath):
        actual = etree.tostring(plugin, pretty_print=True)
        with open(expectedPath, "r") as file:
            expected = file.read()
            self.assertEqual(actual, expected, "\nExpected:\n%s\n\nActual:\n%s" % (expected, actual))

if __name__ == '__main__':
    unittest.main()
