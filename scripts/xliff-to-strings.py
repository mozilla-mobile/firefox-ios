#!/usr/bin/env python

#
# xliff-export.py l10n-repository export-directory
#
# Convert the l10n repository from the following format:
#
#  en/firefox-ios.xliff
#  fr/firefox-ios.xliff
#
# To the following format:
#
#  Client/en-US.lproj/Localizable.strings
#  Client/fr.lproj/Localizable.strings
#  ShareTo/en-US.lproj/ShareTo.strings
#  ShareTo/fr.lproj/ShareTo.strings
#  SendTo/en-US.lproj/SendTo.strings
#  SendTo/fr.lproj/SendTo.strings
#

import glob
import os
import sys

from lxml import etree

NS = {'x':'urn:oasis:names:tc:xliff:document:1.2'}

# Files we are interested in. It would be nice to not hardcode this but I'm not totally sure how yet.
FILES = [
    "Client/Info.plist",
    "Client/Localizable.strings",
    "Client/search.strings",
    "Extensions/SendTo/SendTo.strings",
    "Extensions/ShareTo/ShareTo.strings",
    "Shared/Localizable.strings",
]

# Because Xcode is unpredictable. See bug 1162510 - Sync.strings are not imported
FILENAME_OVERRIDES = {
    "Sync.strings": "Shared/Localizable.strings", # TODO This can go away when all the XLIFF files have been updated to use Shared.strings
    "Shared.strings": "Shared/Localizable.strings",
}

def export_xliff_file(file_node, export_path, target_language):
    directory = os.path.dirname(export_path)
    if not os.path.exists(directory):
        os.makedirs(directory)
    with open(export_path, "w") as fp:
        for trans_unit_node in file_node.xpath("x:body/x:trans-unit", namespaces=NS):
            sources = trans_unit_node.xpath("x:source", namespaces=NS)
            targets = trans_unit_node.xpath("x:target", namespaces=NS)

            # Special hack for en-US. If we don't create an en-US.lproj file,
            # the  system will not default to the base strings but instead
            # pick some random locale it seems. This needs to be verified. Not
            # sure if our bug or iOS bug.
            if target_language == "en-US":
                targets = sources

            if len(sources) == 1 and len(targets) == 1:
                notes = trans_unit_node.xpath("x:note", namespaces=NS)
                if len(notes) == 1:
                    line = u"/* %s */\n" % notes[0].text
                    fp.write(line.encode("utf8"))
                source_text = sources[0].text.replace("'", "\\'")
                target_text = targets[0].text.replace("'", "\\'")
                line = u"\"%s\" = \"%s\";\n\n" % (source_text, target_text)
                fp.write(line.encode("utf8"))

    # Export fails if the strings file is empty. Xcode probably checks
    # on file length vs read error.
    contents = open(export_path).read()
    if len(contents) == 0:
        os.remove(export_path)

def original_path(root, target, original):
    dir,file = os.path.split(original)
    lproj = "%s.lproj" % target_language
    path = dir + "/" + lproj + "/" + file
    return path

if __name__ == "__main__":

    import_root = sys.argv[1]
    if not os.path.isdir(import_root):
        print "import path does not exist or is not a directory"
        sys.exit(1)

    export_root = sys.argv[2]
    if not os.path.isdir(export_root):
        print "export path does not exist or is not a directory"
        sys.exit(1)

    for xliff_path in glob.glob(import_root + "/*/firefox-ios.xliff"):
        print "Exporting", xliff_path
        with open(xliff_path) as fp:
            tree = etree.parse(fp)
            root = tree.getroot()

            # Make sure there are <file> nodes in this xliff file.
            file_nodes = root.xpath("//x:file", namespaces=NS)
            if len(file_nodes) == 0:
                print "  ERROR: No translated files. Skipping."
                continue

            # Take the target language from the first <file>. Not sure if that
            # is a bug in the XLIFF, but in some files only the first node has
            # the target-language set.
            target_language = file_nodes[0].get('target-language')
            if not target_language:
                print "  ERROR: Missing target-language. Skipping."
                continue

            # Export each <file> node as a separate strings file under the
            # export root.
            for file_node in file_nodes:
                original = file_node.get('original')
                original = FILENAME_OVERRIDES.get(original, original)
                if original in FILES:
                    export_path = original_path(export_root, target_language, original)
                    print "  Writing", export_path, target_language
                    export_xliff_file(file_node, export_path, target_language)
