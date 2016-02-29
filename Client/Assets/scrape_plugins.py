#!/usr/bin/env python

from lxml import html
import os
import requests
import shutil
import urllib

def main():
    if not os.path.exists("SearchPlugins"):
        os.makedirs("SearchPlugins")

    # Copy the default en search engines since they aren't in an l10n repo.
    enPluginsSrc = os.path.join("SearchOverlays", "en")
    enPluginsDst = os.path.join("SearchPlugins", "en")
    shutil.copytree(enPluginsSrc, enPluginsDst)

    locales = getLocaleList()
    for locale in locales:
        files = getFileList(locale)
        if files == None:
            continue

        print("  found search plugins")

        directory = os.path.join("SearchPlugins", locale)
        if not os.path.exists(directory):
            os.makedirs(directory)

        # Get the default search engine for this locale.
        default = getDefault(locale)
        if default == None:
            continue
        saveDefault(locale, default)

        for file in files:
            downloadedFile = getFile(locale, file)
            shutil.move(downloadedFile, os.path.join(directory, file))

def getLocaleList():
    response = requests.get('http://hg.mozilla.org/releases/mozilla-aurora/raw-file/default/mobile/android/locales/all-locales')
    return response.text.strip().split("\n")

def getFileList(locale):
    print("scraping: %s..." % locale)
    url = "https://hg.mozilla.org/releases/l10n/mozilla-aurora/%s/file/default/mobile/searchplugins" % locale
    response = requests.get(url)
    if not response.ok:
        return

    tree = html.fromstring(response.content)
    return tree.xpath('//a[@class="list"]/text()')

def getFile(locale, file):
    print("  downloading: %s..." % file)
    url = "https://hg.mozilla.org/releases/l10n/mozilla-aurora/%s/raw-file/default/mobile/searchplugins/%s" % (locale, file)
    result = urllib.urlretrieve(url)
    return result[0]

def getDefault(locale):
    url = "https://hg.mozilla.org/releases/l10n/mozilla-aurora/%s/raw-file/default/mobile/chrome/region.properties" % locale
    response = requests.get(url)
    if not response.ok:
        return

    lines = response.text.strip().split("\n")
    for line in lines:
        values = line.strip().split("=")
        if len(values) == 2 and values[0].strip() == "browser.search.defaultenginename":
            default = values[1].strip()
            print("  default: %s" % default)
            return default

def saveDefault(locale, default):
    directory = os.path.join("SearchPlugins", locale, "default.txt")
    file = open(directory, "w")
    file.write(default.encode("UTF-8"))

if __name__ == "__main__":
        main()
