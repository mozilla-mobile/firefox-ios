#!/usr/bin/env python

#
# xliff-cleanup.py <files>
#
#  1. Remove all <file> sections that we do not care about. We only care about the
#     the one for our main app and those for our extensions.
#
#  2. Look at all remaining <file> sections and remove those strings that should not
#     be localized. Currently that means: CFBundleDisplayName, CFBundleName and
#     CFBundleShortVersionString.
#
#  3. Remove all remaining <file> sections that are now have no <trans-unit> nodes
#     in their <body> anymore.
#
# Modifies files in place. Makes no backup.
#

import sys

from lxml import etree

NS = {'x':'urn:oasis:names:tc:xliff:document:1.2'}

FILES_TO_KEEP = ('Client/Info.plist',
                 'Extensions/ShareTo/Info.plist',
                 'Extensions/SendTo/Info.plist',
                 'Extensions/Today/Info.plist',
                 'Extensions/ViewLater/Info.plist')

STRINGS_TO_REMOVE = ('CFBundleDisplayName',
                     'CFBundleName',
                     'CFBundleShortVersionString')

if __name__ == "__main__":
    for path in sys.argv[1:]:
        # Read it in and modify it in memory
        with open(path) as fp:
            tree = etree.parse(fp)
            root = tree.getroot()
            # 1. Remove sections we do not care about
            for file_node in root.xpath("//x:file", namespaces=NS):
                original = file_node.get('original')
                if original and original.endswith('Info.plist'):
                    if file_node.get('original') not in FILES_TO_KEEP:
                        file_node.getparent().remove(file_node)
            # 2. Remove strings we don't want to be translated
            for file_node in root.xpath("//x:file", namespaces=NS):
                original = file_node.get('original')
                if original and original.endswith('Info.plist'):
                    for trans_unit_node in file_node.xpath("./x:body/x:trans-unit", namespaces=NS):
                        id = trans_unit_node.get('id')
                        # TODO we should probably do the exception for SendTo in a nicer way with some kind of whitelist
                        if id and id in STRINGS_TO_REMOVE and not ((original == "Extensions/SendTo/Info.plist" and id == "CFBundleDisplayName") or (original == "Extensions/ViewLater/Info.plist" and id == "CFBundleDisplayName")):
                            trans_unit_node.getparent().remove(trans_unit_node)
            # 3. Remove empty file sections
            for file_node in root.xpath("//x:file", namespaces=NS):
                original = file_node.get('original')
                if original and original.endswith('Info.plist'):
                    trans_unit_nodes = file_node.xpath("x:body/x:trans-unit", namespaces=NS)
                    if len(trans_unit_nodes) == 0:
                        file_node.getparent().remove(file_node)
        # Write it back to the same file
        with open(path, "w") as fp:
            fp.write(etree.tostring(tree))
