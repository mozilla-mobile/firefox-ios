#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from lxml import html
from lxml import etree
import copy
import json
import os
import requests
import shutil
import subprocess
import urllib

# Paths for en-US plugins included in the core Android repo.
EN_PLUGINS_DIR_URL = "https://hg.mozilla.org/releases/mozilla-aurora/file/default/mobile/locales/en-US/searchplugins"
EN_PLUGINS_FILE_URL = "https://hg.mozilla.org/releases/mozilla-aurora/raw-file/default/mobile/locales/en-US/searchplugins/%s"
EN_PREFS_URL = "https://hg.mozilla.org/releases/mozilla-aurora/raw-file/default/mobile/locales/en-US/chrome/region.properties"

# Paths for plugins in the l10n repos.
L10N_LOCALE_LIST_URL = "https://hg.mozilla.org/releases/mozilla-aurora/raw-file/default/mobile/android/locales/all-locales"
L10N_PLUGINS_DIR_URL = "https://hg.mozilla.org/releases/l10n/mozilla-aurora/%s/file/default/mobile/searchplugins"
L10N_PLUGINS_FILE_URL = "https://hg.mozilla.org/releases/l10n/mozilla-aurora/%s/raw-file/default/mobile/searchplugins/%%s"
L10N_PREFS_URL = "https://hg.mozilla.org/releases/l10n/mozilla-aurora/%s/raw-file/default/mobile/chrome/region.properties"

MOZ_HEADER = """\
<!-- This Source Code Form is subject to the terms of the Mozilla Public
   - License, v. 2.0. If a copy of the MPL was not distributed with this
   - file, You can obtain one at http://mozilla.org/MPL/2.0/. -->

"""

ns = { "search": "http://www.mozilla.org/2006/browser/search/" }

def main():
    # Remove and recreate the SearchPlugins directory.
    if os.path.exists("SearchPlugins"):
        shutil.rmtree("SearchPlugins")
    os.makedirs("SearchPlugins")

    # Import en-US engines from the core repo.
    downloadLocale("en", EnScraper())

    # Import engines from the l10n repos.
    response = requests.get(L10N_LOCALE_LIST_URL)
    locales = response.text.strip().split("\n")
    supportedLocales = getSupportedLocales()
    for locale in locales:
        if (locale not in supportedLocales):
            print("skipping unsupported locale: %s" % locale)
            continue

        downloadLocale(locale, L10nScraper(locale))

    copyOverrides()
    verifyEngines()

def downloadLocale(locale, scraper):
    print("scraping: %s..." % locale)
    files = scraper.getFileList()
    if files == None:
        print("no files for locale: %s" % locale)
        return

    print("  found search plugins")

    directory = os.path.join("SearchPlugins", locale)
    if not os.path.exists(directory):
        os.makedirs(directory)

    # Get the default search engine for this locale.
    default = scraper.getDefault()
    print("  default: %s" % default)
    saveDefault(locale, default)

    for file in files:
        path = os.path.join(directory, file)
        print("  downloading: %s..." % file)
        downloadedFile = scraper.getFile(file)
        name, extension = os.path.splitext(file)

        # Apply iOS-specific overlays for this engine if they are defined.
        if extension == ".xml":
            engine = name.split("-")[0]
            overlay = overlayForEngine(engine)
            if overlay:
                plugin = etree.parse(downloadedFile)
                overlay.apply(plugin)
                contents = MOZ_HEADER + etree.tostring(plugin.getroot(), encoding="utf-8", pretty_print=True)
                with open(path, "w") as outfile:
                    outfile.write(contents)
                continue

        # Otherwise, just use the downloaded file as is.
        shutil.move(downloadedFile, path)

def copyOverrides():
    for locale in os.listdir("SearchOverrides"):
        if not locale.startswith("."):
            print("copying overrides for %s..." % locale)
            localeSrc = os.path.join("SearchOverrides", locale)
            localeDst = os.path.join("SearchPlugins", locale)
            if not os.path.exists(localeDst):
                os.makedirs(localeDst)

            for file in os.listdir(localeSrc):
                if localeSrc.startswith("."): continue
                overrideSrc = os.path.join(localeSrc, file)
                overrideDst = os.path.join(localeDst, file)
                print("  overriding: %s..." % file)
                shutil.copy(overrideSrc, overrideDst)

def verifyEngines():
    print("verifying engines...")
    enDir = os.path.join("SearchPlugins", "en")
    for locale in os.listdir("SearchPlugins"):
        if locale.startswith("."): continue
        localeDir = os.path.join("SearchPlugins", locale)
        with open(os.path.join(localeDir, "list.txt")) as f:
            engineList = f.read().splitlines()

        for engine in engineList:
            if engine.endswith(":hidden"): continue
            path = os.path.join(localeDir, engine + ".xml")
            enPath = os.path.join(enDir, engine + ".xml")
            if not os.path.exists(path) and not os.path.exists(enPath):
                print("  ERROR: missing engine %s for locale %s" % (engine, locale))

def getSupportedLocales():
    supportedLocales = subprocess.Popen("./get_supported_locales.swift", stdout=subprocess.PIPE).communicate()[0]
    return json.loads(supportedLocales.replace("_", "-"))

def overlayForEngine(engine):
    path = os.path.join("SearchOverlays", "%s.xml" % engine)
    if not os.path.exists(path):
        return None
    return Overlay(path)

def saveDefault(locale, default):
    directory = os.path.join("SearchPlugins", locale, "default.txt")
    file = open(directory, "w")
    file.write(default.encode("UTF-8"))


class Scraper:
    def pluginsDirURL(self): pass
    def pluginsFileURL(self): pass
    def prefsURL(self): pass
    def defaultPrefName(self): pass

    def getFileList(self):
        response = requests.get(self.pluginsDirURL)
        if not response.ok:
            raise Exception("error: could not read plugins directory")

        tree = html.fromstring(response.content)
        return tree.xpath('//a[@class="list"]/text()')

    def getFile(self, file):
        result = urllib.urlretrieve(self.pluginsFileURL % file)
        return result[0]

    def getDefault(self):
        response = requests.get(self.prefsURL)
        if not response.ok:
            raise Exception("error: could not read prefs file")

        lines = response.text.strip().split("\n")
        for line in lines:
            values = line.strip().split("=")
            if len(values) == 2 and values[0].strip() == self.defaultPrefName:
                default = values[1].strip()
                return default

        raise Exception("error: no default pref found")


class L10nScraper(Scraper):
    def __init__(self, locale):
        self.pluginsDirURL = L10N_PLUGINS_DIR_URL % locale
        self.pluginsFileURL = L10N_PLUGINS_FILE_URL % locale
        self.prefsURL = L10N_PREFS_URL % locale
        self.defaultPrefName = "browser.search.defaultenginename"


class EnScraper(Scraper):
    def __init__(self):
        self.pluginsDirURL = EN_PLUGINS_DIR_URL
        self.pluginsFileURL = EN_PLUGINS_FILE_URL
        self.prefsURL = EN_PREFS_URL
        self.defaultPrefName = "browser.search.defaultenginename.US"

class Overlay:
    def __init__(self, path):
        overlay = etree.parse(path)
        self.actions = overlay.getroot().getchildren()

    def apply(self, doc):
        for action in self.actions:
            if action.tag == "replace":
                self.replace(target=action.get("target"), replacement=action[0], doc=doc)
            elif action.tag == "append":
                self.append(parent=action.get("parent"), child=action[0], doc=doc)

    def replace(self, target, replacement, doc):
        for element in doc.xpath(target, namespaces=ns):
            replacementCopy = copy.deepcopy(replacement)
            element.getparent().replace(element, replacementCopy)

            # Try to preserve indentation.
            replacementCopy.tail = element.tail

    def append(self, parent, child, doc):
        for element in doc.xpath(parent, namespaces=ns):
            childCopy = copy.deepcopy(child)
            element.append(childCopy)

            # Try to preserve indentation.
            childCopy.tail = "\n"
            previous = childCopy.getprevious()
            if previous is not None:
                childCopy.tail = previous.tail
                prevPrevious = previous.getprevious()
                if prevPrevious is not None:
                    previous.tail = prevPrevious.tail


if __name__ == "__main__":
        main()
