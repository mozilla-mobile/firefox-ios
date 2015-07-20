#! /usr/bin/env python

#
# clean-xliff.py <l10n_folder>
#
# Remove targets from a locale, remove target-language attribute
#

from glob import glob
from lxml import etree
import argparse
import os

NS = {'x':'urn:oasis:names:tc:xliff:document:1.2'}

def indent(elem, level=0):
    # Prettify XML output
    # http://effbot.org/zone/element-lib.htm#prettyprint
    i = '\n' + level*'  '
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + '  '
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def main():
    xliff_filename = 'firefox-ios.xliff'

    parser = argparse.ArgumentParser()
    parser.add_argument('l10n_folder', help='Path to locale folder to clean up')
    args = parser.parse_args()

    file_path = os.path.join(
                    os.path.realpath(args.l10n_folder),
                    xliff_filename
                )

    print 'Updating %s' % file_path

    # Read localized file XML
    locale_tree = etree.parse(file_path)
    locale_root = locale_tree.getroot()

    # Remove existing localizations and target-language
    for trans_node in locale_root.xpath('//x:trans-unit', namespaces=NS):
        for child in trans_node.xpath('./x:target', namespaces=NS):
            child.getparent().remove(child)

        # Remove target-language where defined
        for file_node in locale_root.xpath('//x:file', namespaces=NS):
            if file_node.get('target-language'):
                file_node.attrib.pop('target-language')
        # Replace the existing locale file with the new XML content
        with open(file_path, 'w') as fp:
            # Fix indentations
            indent(locale_root)
            xliff_content = etree.tostring(
                                locale_tree,
                                encoding='UTF-8',
                                xml_declaration=True,
                                pretty_print=True
                            )
            fp.write(xliff_content)

if __name__ == '__main__':
    main()
