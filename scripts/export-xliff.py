#!/usr/bin/env python

#
# xliff-export.py xcodeproj-path l10n-path
#
#  Export all locales that are present in the l10n directory. We use xcodebuild
#  to export and write to l10n-directory/$locale/firefox-ios.xliff so that it
#  can be easily imported into svn. (which is a manual step)
#
# Example:
#
#  cd firefox-ios
#  ./xliff-export.py Client.xcodeproj ../firefox-ios-l10n
#

import glob
import os
import shutil
import subprocess
import sys

LOCALES_TO_SKIP = ['pl']

def available_locales(l10n_path):
    for xliff_path in glob.glob(l10n_path + "/*/firefox-ios.xliff"):
        parts = xliff_path.split(os.sep)
        yield parts[-2]

if __name__ == "__main__":
    project_path = sys.argv[1]
    l10n_path = sys.argv[2]

    for locale in available_locales(l10n_path):
        if locale in LOCALES_TO_SKIP:
            continue
        command = [
            "xcodebuild",
            "-exportLocalizations",
            "-localizationPath", "/tmp/xliff",
            "-project", project_path,
            "-exportLanguage", locale
        ]

        print "Exporting '%s' to '/tmp/xliff/%s.xliff'" % (locale, locale)
        subprocess.call(command)

        src_path = "/tmp/xliff/%s.xliff" % locale
        dst_path = "%s/%s/firefox-ios.xliff" % (l10n_path, locale)
        print "Copying '%s' to '%s'" % (src_path, dst_path)
        shutil.copy(src_path, dst_path)
