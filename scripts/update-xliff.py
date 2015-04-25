#! /usr/bin/env python

from glob import glob
from lxml import etree
import argparse
import os

NS = {'x':'urn:oasis:names:tc:xliff:document:1.2'}

def main():
    reference_locale = 'en-US'
    target_language = 'en'
    excluded_locales = ['pl', reference_locale]

    parser = argparse.ArgumentParser()
    parser.add_argument('base_folder', help='Path to folder including subfolders for all locales')
    args = parser.parse_args()

    # Get a list of files to update
    base_folder = os.path.realpath(args.base_folder)
    file_paths = []
    for xliff_path in glob(base_folder + '/*/firefox-ios.xliff'):
        parts = xliff_path.split(os.sep)
        if not parts[-2] in excluded_locales:
            file_paths.append(xliff_path)
    file_paths.sort()

    for file_path in file_paths:
        print 'Updating %s' % file_path

        # Read the reference file
        reference_tree = etree.parse(os.path.join(base_folder, reference_locale, 'firefox-ios.xliff'))
        reference_root = reference_tree.getroot()

        # Read localized file
        locale_tree = etree.parse(file_path)
        locale_root = locale_tree.getroot()
        locale_code = file_path.split(os.sep)[-2]

        # Store existing localizations
        translations = {}
        for trans_node in locale_root.xpath('//x:trans-unit', namespaces=NS):
            file_name = trans_node.getparent().getparent().get('original')
            string_id = '%s:%s' % (file_name, trans_node.get('id'))
            for child in trans_node:
                if child.tag.endswith('target'):
                    translations[string_id] = child.text

        # Replace translations in reference file
        for trans_node in reference_root.xpath('//x:trans-unit', namespaces=NS):
            file_name = trans_node.getparent().getparent().get('original')
            string_id = '%s:%s' % (file_name, trans_node.get('id'))
            for child in trans_node:
                if child.tag.endswith('target'):
                    if string_id in translations:
                        # We have a translation, update the target
                        child.text = translations[string_id]
                    else:
                        # No translation, remove the target
                        child.getparent().remove(child)

        # Fix target-language
        for file_node in reference_root.xpath('//x:file', namespaces=NS):
            if file_node.get('target-language'):
                file_node.set('target-language', locale_code)

        # Store the modified reference as locale file
        with open(file_path, "w") as fp:
            fp.write(etree.tostring(reference_tree, encoding='UTF-8', xml_declaration=True))

if __name__ == '__main__':
    main()
